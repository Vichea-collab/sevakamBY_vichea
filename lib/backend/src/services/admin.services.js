import { db } from "../config/firebase.js";
import admin from "firebase-admin";
import { paginateArray } from "../utils/pagination.util.js";
import { mapOrderDoc } from "./order.services.js";

const DEFAULT_ADMIN_EMAIL = "admin@gmail.com";
const MAX_ADMIN_SCAN = 120;
const MAX_ADMIN_BROADCAST_SCAN = 200;
const READ_BUDGET_DAILY = 50000;
const READ_BUDGET_GUARD_RATIO = 0.92;
const OVERVIEW_CACHE_TTL_MS = 2 * 60 * 1000;
const UNDO_WINDOW_MINUTES = 5;
const ALLOWED_ORDER_STATUSES = [
  "booked",
  "on_the_way",
  "started",
  "completed",
  "cancelled",
  "declined",
];
const ALLOWED_POST_STATUSES = ["open", "closed", "paused", "hidden"];
const ALLOWED_TICKET_STATUSES = ["open", "resolved", "closed"];
const ALLOWED_BROADCAST_TYPES = ["system", "promotion"];
const ALLOWED_PROMO_DISCOUNT_TYPES = ["percent", "fixed"];

function readWindow(pagination, maxLimit = MAX_ADMIN_SCAN) {
  const page = Math.max(1, Number.parseInt((pagination?.page ?? 1).toString(), 10) || 1);
  const limit = Math.max(1, Number.parseInt((pagination?.limit ?? 10).toString(), 10) || 10);
  return Math.min(maxLimit, page * limit + 1);
}

function normalizePagination(pagination, maxLimit = MAX_ADMIN_SCAN) {
  const page = Math.max(1, Number.parseInt((pagination?.page ?? 1).toString(), 10) || 1);
  const limit = Math.min(
    maxLimit,
    Math.max(1, Number.parseInt((pagination?.limit ?? 10).toString(), 10) || 10),
  );
  return {
    page,
    limit,
    cursor: safeString(pagination?.cursor),
  };
}

let _overviewCache = {
  expiresAt: 0,
  data: null,
};

function normalizeStatus(value, fallback = "") {
  return safeString(value).toLowerCase() || fallback;
}

function parseBoolean(value, fallback = false) {
  if (typeof value === "boolean") return value;
  const normalized = normalizeStatus(value);
  if (["true", "1", "yes", "active"].includes(normalized)) return true;
  if (["false", "0", "no", "inactive"].includes(normalized)) return false;
  return fallback;
}

function utcDayKey(date = new Date()) {
  const y = date.getUTCFullYear();
  const m = `${date.getUTCMonth() + 1}`.padStart(2, "0");
  const d = `${date.getUTCDate()}`.padStart(2, "0");
  return `${y}-${m}-${d}`;
}

function mapRowContains(fields, query) {
  const needle = normalizeStatus(query);
  if (!needle) return true;
  return fields
    .map((value) => safeString(value).toLowerCase())
    .join(" ")
    .includes(needle);
}

function normalizeRole(value) {
  const role = (value || "").toString().trim().toLowerCase();
  if (role === "finders") return "finder";
  if (role === "providers") return "provider";
  if (role === "admins") return "admin";
  return role;
}

function normalizeRoleList(value, fallback = ["finder", "provider"]) {
  const source = Array.isArray(value)
    ? value
    : typeof value === "string"
      ? value.split(",")
      : [];
  const roles = Array.from(
    new Set(
      source
        .map((entry) => normalizeRole(entry))
        .filter((entry) => ["finder", "provider"].includes(entry)),
    ),
  );
  return roles.length > 0 ? roles : fallback;
}

function normalizeBroadcastType(value) {
  const type = normalizeStatus(value, "system");
  if (type === "promo") return "promotion";
  if (!ALLOWED_BROADCAST_TYPES.includes(type)) return "system";
  return type;
}

function normalizePromoDiscountType(value) {
  const discountType = normalizeStatus(value, "percent");
  if (ALLOWED_PROMO_DISCOUNT_TYPES.includes(discountType)) return discountType;
  return "percent";
}

function toIsoOrNull(value) {
  if (!value) return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  return date.toISOString();
}

function lifecycleForWindow({
  active = true,
  startAt = null,
  endAt = null,
  now = Date.now(),
}) {
  if (!active) return "inactive";
  const startMillis = toMillis(startAt);
  const endMillis = toMillis(endAt);
  if (startMillis > 0 && now < startMillis) return "scheduled";
  if (endMillis > 0 && now > endMillis) return "expired";
  return "active";
}

function toMillis(value) {
  if (!value) return 0;
  if (typeof value?.toDate === "function") {
    return value.toDate().getTime();
  }
  if (value instanceof Date) {
    return value.getTime();
  }
  if (typeof value === "string") {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) return parsed.getTime();
  }
  if (typeof value === "object" && value._seconds) {
    const seconds = Number(value._seconds);
    if (Number.isFinite(seconds)) return Math.round(seconds * 1000);
  }
  return 0;
}

function toIso(value) {
  const millis = toMillis(value);
  if (millis <= 0) return null;
  return new Date(millis).toISOString();
}

function toNumber(value, fallback = 0) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function safeString(value) {
  return (value || "").toString().trim();
}

function normalizeServiceList(row = {}) {
  const values = [];
  if (Array.isArray(row.services)) {
    row.services.forEach((entry) => {
      const text = safeString(entry);
      if (text) values.push(text);
    });
  }
  const primary = safeString(row.service);
  if (primary) values.push(primary);
  return Array.from(new Set(values));
}

function serviceSummary(services = []) {
  if (!Array.isArray(services) || services.length === 0) return "";
  const ordered = Array.from(new Set(services.map((entry) => safeString(entry)).filter(Boolean)))
    .sort((a, b) => a.localeCompare(b));
  if (ordered.length === 0) return "";
  if (ordered.length === 1) return ordered[0];
  return `${ordered[0]} +${ordered.length - 1} more`;
}

function orderStatus(value) {
  const status = safeString(value).toLowerCase();
  switch (status) {
    case "on_the_way":
    case "started":
    case "completed":
    case "cancelled":
    case "declined":
      return status;
    case "booked":
    default:
      return "booked";
  }
}

function displayRole(row = {}) {
  const role = normalizeRole(row.role);
  const roles = Array.isArray(row.roles)
    ? row.roles.map((value) => normalizeRole(value)).filter(Boolean)
    : [];
  if (roles.length > 0) return Array.from(new Set(roles)).join(", ");
  if (role) return role;
  return "user";
}

function sortByNewest(items, readCreatedAt) {
  return items.sort((a, b) => readCreatedAt(b) - readCreatedAt(a));
}

class AdminService {
  static async _recordReadUsage(estimatedReads = 0, meta = {}) {
    const safeReads = Math.max(0, Math.floor(toNumber(estimatedReads, 0)));
    if (safeReads <= 0) return;
    const key = utcDayKey();
    const ref = db.collection("adminUsage").doc(key);
    const endpoint = safeString(meta.endpoint);
    const payload = {
      dateKey: key,
      dailyBudget: READ_BUDGET_DAILY,
      estimatedReadsUsed: admin.firestore.FieldValue.increment(safeReads),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      lastEndpoint: endpoint,
    };
    if (endpoint) {
      payload[`endpointReads.${endpoint}`] = admin.firestore.FieldValue.increment(safeReads);
    }
    await ref.set(
      payload,
      { merge: true },
    );
  }

  static async _assertReadBudgetAvailable(estimatedReads = 0, meta = {}) {
    const needed = Math.max(0, Math.floor(toNumber(estimatedReads, 0)));
    if (needed <= 0) return;
    const key = utcDayKey();
    const snap = await db.collection("adminUsage").doc(key).get();
    const row = snap.exists ? snap.data() || {} : {};
    const used = Math.max(0, Math.floor(toNumber(row.estimatedReadsUsed, 0)));
    const projected = used + needed;
    const guardCap = Math.floor(READ_BUDGET_DAILY * READ_BUDGET_GUARD_RATIO);
    if (projected < guardCap) return;
    const endpoint = safeString(meta.endpoint) || "admin";
    const error = new Error(`read budget guard active for ${endpoint}`);
    error.status = 429;
    throw error;
  }

  static async _applyDocCursor(query, collectionName, cursor) {
    const cursorId = safeString(cursor);
    if (!cursorId) return query;
    const cursorSnap = await db.collection(collectionName).doc(cursorId).get();
    if (!cursorSnap.exists) return query;
    return query.startAfter(cursorSnap);
  }

  static async _createUndoAction({
    adminUid,
    actionType,
    targetLabel,
    docPath,
    previousState,
    nextState,
    reason,
  }) {
    const ref = db.collection("adminUndoActions").doc();
    const expiresAt = new Date(Date.now() + UNDO_WINDOW_MINUTES * 60 * 1000);
    await ref.set({
      id: ref.id,
      adminUid: safeString(adminUid),
      actionType: safeString(actionType),
      targetLabel: safeString(targetLabel),
      docPath: safeString(docPath),
      previousState: previousState && typeof previousState === "object" ? previousState : {},
      nextState: nextState && typeof nextState === "object" ? nextState : {},
      reason: safeString(reason),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: expiresAt.toISOString(),
      usedAt: null,
    });
    return { undoToken: ref.id, undoExpiresAt: expiresAt.toISOString() };
  }

  static async _isAdmin(uid, user = {}) {
    const [adminSnap, userSnap] = await Promise.all([
      db.collection("admins").doc(uid).get(),
      db.collection("users").doc(uid).get(),
    ]);
    if (adminSnap.exists) return true;

    if (userSnap.exists) {
      const row = userSnap.data() || {};
      const role = normalizeRole(row.role);
      if (role === "admin") return true;
      if (Array.isArray(row.roles)) {
        const roles = row.roles
          .map((value) => normalizeRole(value))
          .filter(Boolean);
        if (roles.includes("admin")) return true;
      }
    }

    const email = safeString(user?.email).toLowerCase();
    if (email && email === DEFAULT_ADMIN_EMAIL) return true;
    return false;
  }

  static async _assertAdmin(uid, user = {}) {
    const allowed = await this._isAdmin(uid, user);
    if (allowed) return;
    const error = new Error("admin access required");
    error.status = 403;
    throw error;
  }

  static async getOverview(uid, user = {}) {
    await this._assertAdmin(uid, user);
    if (_overviewCache.data && _overviewCache.expiresAt > Date.now()) {
      return { data: _overviewCache.data };
    }
    const overviewLimit = 80;
    await this._assertReadBudgetAvailable(overviewLimit * 9, { endpoint: "overview" });

    const [
      usersSnap,
      findersSnap,
      providersSnap,
      ordersSnap,
      finderPostsSnap,
      providerPostsSnap,
      categoriesSnap,
      servicesSnap,
    ] = await Promise.all([
      db.collection("users").limit(overviewLimit).get(),
      db.collection("finders").limit(overviewLimit).get(),
      db.collection("providers").limit(overviewLimit).get(),
      db.collection("orders").limit(overviewLimit).get(),
      db.collection("finderPosts").limit(overviewLimit).get(),
      db.collection("providerPosts").limit(overviewLimit).get(),
      db.collection("categories").limit(overviewLimit).get(),
      db.collection("services").limit(overviewLimit).get(),
    ]);

    let ticketsSnap = null;
    try {
      ticketsSnap = await db.collectionGroup("helpTickets").limit(overviewLimit).get();
    } catch (_) {
      ticketsSnap = null;
    }

    await this._recordReadUsage(
      usersSnap.size +
        findersSnap.size +
        providersSnap.size +
        ordersSnap.size +
        finderPostsSnap.size +
        providerPostsSnap.size +
        categoriesSnap.size +
        servicesSnap.size +
        (ticketsSnap?.size || 0),
      { endpoint: "overview" },
    );

    const statusCounts = {
      booked: 0,
      on_the_way: 0,
      started: 0,
      completed: 0,
      cancelled: 0,
      declined: 0,
    };
    let revenueCompleted = 0;
    const orderRows = ordersSnap.docs.map((doc) => {
      const row = mapOrderDoc(doc);
      const status = orderStatus(row.status);
      statusCounts[status] += 1;
      if (status === "completed") {
        revenueCompleted += toNumber(row.total, 0);
      }
      return row;
    });

    const users = usersSnap.docs.map((doc) => {
      const row = doc.data() || {};
      return {
        id: doc.id,
        name: safeString(row.name) || "Unnamed User",
        email: safeString(row.email),
        role: displayRole(row),
        createdAt: row.createdAt || null,
        updatedAt: row.updatedAt || null,
      };
    });

    const allPosts = [
      ...finderPostsSnap.docs.map((doc) => {
        const row = doc.data() || {};
        const services = normalizeServiceList(row);
        return {
          id: doc.id,
          type: "finder_request",
          ownerName: safeString(row.clientName) || "Finder",
          category: safeString(row.category),
          service: serviceSummary(services),
          status: safeString(row.status) || "open",
          createdAt: row.createdAt || null,
        };
      }),
      ...providerPostsSnap.docs.map((doc) => {
        const row = doc.data() || {};
        const services = normalizeServiceList(row);
        return {
          id: doc.id,
          type: "provider_offer",
          ownerName: safeString(row.providerName) || "Provider",
          category: safeString(row.category),
          service: serviceSummary(services),
          status: safeString(row.status) || "open",
          createdAt: row.createdAt || null,
        };
      }),
    ];

    const recentOrders = sortByNewest(
      orderRows.map((row) => ({
        id: row.id,
        finderName: row.finderName || "Finder",
        providerName: row.providerName || "Provider",
        serviceName: row.serviceName || "Service",
        status: row.status,
        total: toNumber(row.total, 0),
        createdAt: row.createdAt || null,
      })),
      (row) => toMillis(row.createdAt),
    ).slice(0, 10);

    const recentUsers = sortByNewest(
      [...users],
      (row) => toMillis(row.updatedAt) || toMillis(row.createdAt),
    ).slice(0, 10);

    const recentPosts = sortByNewest(
      [...allPosts],
      (row) => toMillis(row.createdAt),
    ).slice(0, 10);

    const tickets = ticketsSnap
      ? ticketsSnap.docs.map((doc) => ({
          id: doc.id,
          status: safeString(doc.data()?.status).toLowerCase() || "open",
          title: safeString(doc.data()?.title),
          message: safeString(doc.data()?.message),
          createdAt: doc.data()?.createdAt || null,
        }))
      : [];

    const openTickets = tickets.filter(
      (item) => item.status === "open",
    ).length;
    const resolvedTickets = tickets.length - openTickets;

    const activeServices = servicesSnap.docs.filter(
      (doc) => doc.data()?.active !== false,
    ).length;
    const activeCategories = categoriesSnap.docs.filter(
      (doc) => doc.data()?.isActive !== false,
    ).length;

    const overview = {
      generatedAt: new Date().toISOString(),
      kpis: {
        users: usersSnap.size,
        finders: findersSnap.size,
        providers: providersSnap.size,
        orders: ordersSnap.size,
        completedOrders: statusCounts.completed,
        activeProviderPosts: providerPostsSnap.docs.filter(
          (doc) => safeString(doc.data()?.status).toLowerCase() === "open",
        ).length,
        activeFinderRequests: finderPostsSnap.docs.filter(
          (doc) => safeString(doc.data()?.status).toLowerCase() === "open",
        ).length,
        services: activeServices,
        categories: activeCategories,
        helpTickets: tickets.length,
        openHelpTickets: openTickets,
        resolvedHelpTickets: resolvedTickets,
        completedRevenue: Number(revenueCompleted.toFixed(2)),
      },
      orderStatus: statusCounts,
      recentOrders: recentOrders.map((row) => ({
        ...row,
        createdAt: toIso(row.createdAt),
      })),
      recentUsers: recentUsers.map((row) => ({
        ...row,
        createdAt: toIso(row.createdAt),
        updatedAt: toIso(row.updatedAt),
      })),
      recentPosts: recentPosts.map((row) => ({
        ...row,
        createdAt: toIso(row.createdAt),
      })),
    };

    _overviewCache = {
      data: overview,
      expiresAt: Date.now() + OVERVIEW_CACHE_TTL_MS,
    };
    return { data: overview };
  }

  static async getUsers(uid, user, pagination, filters = {}) {
    await this._assertAdmin(uid, user);
    const roleFilter = normalizeStatus(filters.role);
    const query = safeString(filters.q || filters.query).toLowerCase();
    const normalized = normalizePagination(pagination);
    const canUseCursor =
      (!roleFilter || roleFilter === "all") &&
      !query &&
      (normalized.page === 1 || Boolean(normalized.cursor));

    if (canUseCursor) {
      let queryRef = db.collection("users").orderBy("updatedAt", "desc");
      queryRef = await this._applyDocCursor(queryRef, "users", normalized.cursor);
      const fetchLimit = normalized.cursor ? normalized.limit + 1 : normalized.limit;
      const snap = await queryRef.limit(fetchLimit).get();
      await this._recordReadUsage(snap.size, { endpoint: "users" });
      let docs = snap.docs;
      const hasNextPage = normalized.cursor
        ? docs.length > normalized.limit
        : docs.length >= normalized.limit;
      if (normalized.cursor && docs.length > normalized.limit) {
        docs = docs.slice(0, normalized.limit);
      }
      const items = docs.map((doc) => {
        const row = doc.data() || {};
        return {
          id: doc.id,
          name: safeString(row.name) || "Unnamed User",
          email: safeString(row.email),
          role: displayRole(row),
          active: row.active !== false,
          createdAt: toIso(row.createdAt),
          updatedAt: toIso(row.updatedAt),
        };
      });
      return {
        data: items,
        pagination: {
          page: normalized.page,
          limit: normalized.limit,
          totalItems: items.length + (hasNextPage ? 1 : 0),
          totalPages: hasNextPage ? normalized.page + 1 : normalized.page,
          hasPrevPage: Boolean(normalized.cursor) || normalized.page > 1,
          hasNextPage,
          nextCursor: hasNextPage && items.length > 0 ? items[items.length - 1].id : "",
        },
      };
    }

    const snap = await db.collection("users").limit(readWindow(pagination)).get();
    await this._recordReadUsage(snap.size, { endpoint: "users" });
    const items = snap.docs.map((doc) => {
      const row = doc.data() || {};
      return {
        id: doc.id,
        name: safeString(row.name) || "Unnamed User",
        email: safeString(row.email),
        role: displayRole(row),
        active: row.active !== false,
        createdAt: toIso(row.createdAt),
        updatedAt: toIso(row.updatedAt),
      };
    });
    const filtered = items.filter((row) => {
      if (roleFilter && roleFilter !== "all") {
        if (!row.role.toLowerCase().includes(roleFilter)) return false;
      }
      if (!query) return true;
      return mapRowContains([row.id, row.name, row.email, row.role], query);
    });
    const sorted = sortByNewest(filtered, (row) => {
      return toMillis(row.updatedAt) || toMillis(row.createdAt);
    });
    const paged = paginateArray(sorted, pagination);
    return { data: paged.items, pagination: paged.pagination };
  }

  static async getOrders(uid, user, pagination, filters = {}) {
    await this._assertAdmin(uid, user);
    const statusFilter = normalizeStatus(filters.status);
    const query = safeString(filters.q || filters.query).toLowerCase();
    const normalized = normalizePagination(pagination);
    const canUseCursor =
      (!statusFilter || statusFilter === "all") &&
      !query &&
      (normalized.page === 1 || Boolean(normalized.cursor));

    if (canUseCursor) {
      let queryRef = db.collection("orders").orderBy("createdAt", "desc");
      queryRef = await this._applyDocCursor(queryRef, "orders", normalized.cursor);
      const fetchLimit = normalized.cursor ? normalized.limit + 1 : normalized.limit;
      const snap = await queryRef.limit(fetchLimit).get();
      await this._recordReadUsage(snap.size, { endpoint: "orders" });
      let docs = snap.docs;
      const hasNextPage = normalized.cursor
        ? docs.length > normalized.limit
        : docs.length >= normalized.limit;
      if (normalized.cursor && docs.length > normalized.limit) {
        docs = docs.slice(0, normalized.limit);
      }
      const items = docs.map((doc) => {
        const row = mapOrderDoc(doc);
        return {
          id: row.id,
          finderName: row.finderName || "Finder",
          providerName: row.providerName || "Provider",
          categoryName: row.categoryName || "",
          serviceName: row.serviceName || "Service",
          status: row.status,
          paymentMethod: row.paymentMethod,
          paymentStatus: row.paymentStatus,
          total: toNumber(row.total, 0),
          createdAt: toIso(row.createdAt),
        };
      });
      return {
        data: items,
        pagination: {
          page: normalized.page,
          limit: normalized.limit,
          totalItems: items.length + (hasNextPage ? 1 : 0),
          totalPages: hasNextPage ? normalized.page + 1 : normalized.page,
          hasPrevPage: Boolean(normalized.cursor) || normalized.page > 1,
          hasNextPage,
          nextCursor: hasNextPage && items.length > 0 ? items[items.length - 1].id : "",
        },
      };
    }

    const snap = await db.collection("orders").limit(readWindow(pagination)).get();
    await this._recordReadUsage(snap.size, { endpoint: "orders" });
    const items = snap.docs.map((doc) => {
      const row = mapOrderDoc(doc);
      return {
        id: row.id,
        finderName: row.finderName || "Finder",
        providerName: row.providerName || "Provider",
        categoryName: row.categoryName || "",
        serviceName: row.serviceName || "Service",
        status: row.status,
        paymentMethod: row.paymentMethod,
        paymentStatus: row.paymentStatus,
        total: toNumber(row.total, 0),
        createdAt: toIso(row.createdAt),
      };
    });
    const filtered = items.filter((row) => {
      if (statusFilter && statusFilter !== "all") {
        if (normalizeStatus(row.status) !== statusFilter) return false;
      }
      if (!query) return true;
      return mapRowContains(
        [row.id, row.serviceName, row.finderName, row.providerName, row.status],
        query,
      );
    });
    const sorted = sortByNewest(filtered, (row) => toMillis(row.createdAt));
    const paged = paginateArray(sorted, pagination);
    return { data: paged.items, pagination: paged.pagination };
  }

  static async getPosts(uid, user, pagination, filters = {}) {
    await this._assertAdmin(uid, user);
    const queryLimit = readWindow(pagination);
    const [finderSnap, providerSnap] = await Promise.all([
      db.collection("finderPosts").limit(queryLimit).get(),
      db.collection("providerPosts").limit(queryLimit).get(),
    ]);
    await this._recordReadUsage(finderSnap.size + providerSnap.size, {
      endpoint: "posts",
    });
    const items = [
      ...finderSnap.docs.map((doc) => {
        const row = doc.data() || {};
        const services = normalizeServiceList(row);
        return {
          id: doc.id,
          sourceCollection: "finderPosts",
          type: "finder_request",
          ownerName: safeString(row.clientName) || "Finder",
          category: safeString(row.category),
          service: serviceSummary(services),
          services,
          details: safeString(row.message),
          location: safeString(row.location),
          status: safeString(row.status) || "open",
          createdAt: toIso(row.createdAt),
        };
      }),
      ...providerSnap.docs.map((doc) => {
        const row = doc.data() || {};
        const services = normalizeServiceList(row);
        return {
          id: doc.id,
          sourceCollection: "providerPosts",
          type: "provider_offer",
          ownerName: safeString(row.providerName) || "Provider",
          category: safeString(row.category),
          service: serviceSummary(services),
          services,
          details: safeString(row.details),
          location: safeString(row.area),
          status: safeString(row.status) || "open",
          createdAt: toIso(row.createdAt),
        };
      }),
    ];
    const typeFilter = normalizeStatus(filters.type);
    const query = safeString(filters.q || filters.query).toLowerCase();
    const filtered = items.filter((row) => {
      if (typeFilter && typeFilter !== "all") {
        if (normalizeStatus(row.type) !== typeFilter) return false;
      }
      if (!query) return true;
      return mapRowContains(
        [
          row.id,
          row.ownerName,
          row.category,
          row.service,
          row.location,
          row.status,
          row.details,
          ...(Array.isArray(row.services) ? row.services : []),
        ],
        query,
      );
    });
    const sorted = sortByNewest(filtered, (row) => toMillis(row.createdAt));
    const paged = paginateArray(sorted, pagination);
    return { data: paged.items, pagination: paged.pagination };
  }

  static async getTickets(uid, user, pagination, filters = {}) {
    await this._assertAdmin(uid, user);
    const queryLimit = readWindow(pagination);
    let snap = null;
    try {
      snap = await db.collectionGroup("helpTickets").limit(queryLimit).get();
    } catch (error) {
      const e = new Error("help tickets query requires index configuration");
      e.status = 500;
      throw e;
    }
    await this._recordReadUsage(snap.size, { endpoint: "tickets" });
    const items = snap.docs.map((doc) => {
      const row = doc.data() || {};
      const uid = doc.ref.parent?.parent?.id || "";
      return {
        id: doc.id,
        userUid: uid,
        userName: "",
        userEmail: "",
        title: safeString(row.title) || "Support request",
        message: safeString(row.message),
        status: safeString(row.status) || "open",
        createdAt: toIso(row.createdAt),
      };
    });
    const userUids = Array.from(
      new Set(items.map((row) => safeString(row.userUid)).filter(Boolean)),
    );
    if (userUids.length > 0) {
      const snaps = await Promise.all(
        userUids.map((userUid) => db.collection("users").doc(userUid).get()),
      );
      const userMap = new Map();
      snaps.forEach((userSnap) => {
        if (!userSnap.exists) return;
        userMap.set(userSnap.id, userSnap.data() || {});
      });
      items.forEach((item) => {
        const userRow = userMap.get(item.userUid) || {};
        item.userName = safeString(userRow.name) || "User";
        item.userEmail = safeString(userRow.email);
      });
      await this._recordReadUsage(snaps.length, { endpoint: "tickets_users_meta" });
    }
    const statusFilter = normalizeStatus(filters.status);
    const query = safeString(filters.q || filters.query).toLowerCase();
    const filtered = items.filter((row) => {
      if (statusFilter && statusFilter !== "all") {
        if (normalizeStatus(row.status) !== statusFilter) return false;
      }
      if (!query) return true;
      return mapRowContains(
        [row.id, row.userUid, row.userName, row.userEmail, row.title, row.message, row.status],
        query,
      );
    });
    const sorted = sortByNewest(filtered, (row) => toMillis(row.createdAt));
    const paged = paginateArray(sorted, pagination);
    return { data: paged.items, pagination: paged.pagination };
  }

  static async getTicketMessages(uid, user, userUid, ticketId, pagination) {
    await this._assertAdmin(uid, user);
    const ticketRef = db.collection("users").doc(userUid).collection("helpTickets").doc(ticketId);
    const ticketSnap = await ticketRef.get();
    if (!ticketSnap.exists) {
      const error = new Error("ticket not found");
      error.status = 404;
      throw error;
    }
    const normalized = normalizePagination(pagination, 200);
    const canUseCursor = normalized.page === 1 || Boolean(normalized.cursor);
    if (canUseCursor) {
      const messagesRef = ticketRef.collection("messages");
      let queryRef = messagesRef.orderBy("createdAt", "desc");
      if (normalized.cursor) {
        const cursorSnap = await messagesRef.doc(normalized.cursor).get();
        if (cursorSnap.exists) {
          queryRef = queryRef.startAfter(cursorSnap);
        }
      }
      const fetchLimit = normalized.cursor ? normalized.limit + 1 : normalized.limit;
      const messagesSnap = await queryRef.limit(fetchLimit).get();
      await this._recordReadUsage(messagesSnap.size, { endpoint: "ticket_messages" });
      let docs = messagesSnap.docs;
      const hasNextPage = normalized.cursor
        ? docs.length > normalized.limit
        : docs.length >= normalized.limit;
      if (normalized.cursor && docs.length > normalized.limit) {
        docs = docs.slice(0, normalized.limit);
      }
      const items = docs.map((doc) => {
        const row = doc.data() || {};
        return {
          id: doc.id,
          text: safeString(row.text),
          type: safeString(row.type) || "text",
          senderUid: safeString(row.senderUid),
          senderRole: safeString(row.senderRole) || "finder",
          senderName: safeString(row.senderName) || "User",
          createdAt: toIso(row.createdAt),
        };
      });
      const ordered = [...items].sort((a, b) => toMillis(a.createdAt) - toMillis(b.createdAt));
      return {
        data: ordered,
        pagination: {
          page: normalized.page,
          limit: normalized.limit,
          totalItems: ordered.length + (hasNextPage ? 1 : 0),
          totalPages: hasNextPage ? normalized.page + 1 : normalized.page,
          hasPrevPage: Boolean(normalized.cursor) || normalized.page > 1,
          hasNextPage,
          nextCursor: hasNextPage && items.length > 0 ? items[items.length - 1].id : "",
        },
      };
    }
    const messagesSnap = await ticketRef
      .collection("messages")
      .orderBy("createdAt", "desc")
      .limit(readWindow(pagination, 200))
      .get();
    await this._recordReadUsage(messagesSnap.size, { endpoint: "ticket_messages" });
    const items = messagesSnap.docs.map((doc) => {
      const row = doc.data() || {};
      return {
        id: doc.id,
        text: safeString(row.text),
        type: safeString(row.type) || "text",
        senderUid: safeString(row.senderUid),
        senderRole: safeString(row.senderRole) || "finder",
        senderName: safeString(row.senderName) || "User",
        createdAt: toIso(row.createdAt),
      };
    });
    const paged = paginateArray(items, pagination);
    const ordered = [...paged.items].sort(
      (a, b) => toMillis(a.createdAt) - toMillis(b.createdAt),
    );
    return { data: ordered, pagination: paged.pagination };
  }

  static async sendTicketMessage(uid, user, userUid, ticketId, payload = {}) {
    await this._assertAdmin(uid, user);
    const text = safeString(payload.text || payload.message);
    if (!text) {
      const error = new Error("message text is required");
      error.status = 400;
      throw error;
    }
    const ticketRef = db.collection("users").doc(userUid).collection("helpTickets").doc(ticketId);
    const ticketSnap = await ticketRef.get();
    if (!ticketSnap.exists) {
      const error = new Error("ticket not found");
      error.status = 404;
      throw error;
    }
    const ticket = ticketSnap.data() || {};
    const status = safeString(ticket.status).toLowerCase();
    const nextStatus = ["closed", "resolved"].includes(status) ? "open" : (status || "open");
    const senderName = safeString(user?.name || user?.email) || "Admin";
    const now = admin.firestore.FieldValue.serverTimestamp();
    const messageRef = ticketRef.collection("messages").doc();
    await db.runTransaction(async (tx) => {
      tx.set(messageRef, {
        id: messageRef.id,
        text,
        type: "text",
        senderUid: uid,
        senderRole: "admin",
        senderName,
        createdAt: now,
      });
      tx.set(
        ticketRef,
        {
          status: nextStatus,
          updatedAt: now,
          lastMessageText: text,
          lastMessageAt: now,
        },
        { merge: true },
      );
    });
    return {
      data: {
        id: messageRef.id,
        text,
        type: "text",
        senderUid: uid,
        senderRole: "admin",
        senderName,
      },
    };
  }

  static async getServices(uid, user, pagination, filters = {}) {
    await this._assertAdmin(uid, user);
    const activeFilter = normalizeStatus(filters.active);
    const query = safeString(filters.q || filters.query).toLowerCase();
    const normalized = normalizePagination(pagination);
    const canUseCursor =
      (!activeFilter || activeFilter === "all") &&
      !query &&
      (normalized.page === 1 || Boolean(normalized.cursor));

    if (canUseCursor) {
      let queryRef = db.collection("services").orderBy("name");
      queryRef = await this._applyDocCursor(queryRef, "services", normalized.cursor);
      const fetchLimit = normalized.cursor ? normalized.limit + 1 : normalized.limit;
      const [servicesSnap, categoriesSnap] = await Promise.all([
        queryRef.limit(fetchLimit).get(),
        db.collection("categories").limit(MAX_ADMIN_SCAN).get(),
      ]);
      await this._recordReadUsage(servicesSnap.size + categoriesSnap.size, {
        endpoint: "services",
      });
      const categoryMap = new Map();
      categoriesSnap.docs.forEach((doc) => {
        const row = doc.data() || {};
        categoryMap.set(doc.id, safeString(row.name));
      });
      let docs = servicesSnap.docs;
      const hasNextPage = normalized.cursor
        ? docs.length > normalized.limit
        : docs.length >= normalized.limit;
      if (normalized.cursor && docs.length > normalized.limit) {
        docs = docs.slice(0, normalized.limit);
      }
      const items = docs.map((doc) => {
        const row = doc.data() || {};
        const categoryId = safeString(row.categoryId);
        return {
          id: doc.id,
          name: safeString(row.name) || "Unnamed Service",
          categoryId,
          categoryName: safeString(row.categoryName) || categoryMap.get(categoryId) || "General",
          active: row.active !== false,
          imageUrl: safeString(row.imageUrl),
        };
      });
      return {
        data: items,
        pagination: {
          page: normalized.page,
          limit: normalized.limit,
          totalItems: items.length + (hasNextPage ? 1 : 0),
          totalPages: hasNextPage ? normalized.page + 1 : normalized.page,
          hasPrevPage: Boolean(normalized.cursor) || normalized.page > 1,
          hasNextPage,
          nextCursor: hasNextPage && items.length > 0 ? items[items.length - 1].id : "",
        },
      };
    }

    const queryLimit = readWindow(pagination);
    const [servicesSnap, categoriesSnap] = await Promise.all([
      db.collection("services").limit(queryLimit).get(),
      db.collection("categories").limit(MAX_ADMIN_SCAN).get(),
    ]);
    await this._recordReadUsage(servicesSnap.size + categoriesSnap.size, {
      endpoint: "services",
    });

    const categoryMap = new Map();
    categoriesSnap.docs.forEach((doc) => {
      const row = doc.data() || {};
      categoryMap.set(doc.id, safeString(row.name));
    });

    const items = servicesSnap.docs.map((doc) => {
      const row = doc.data() || {};
      const categoryId = safeString(row.categoryId);
      return {
        id: doc.id,
        name: safeString(row.name) || "Unnamed Service",
        categoryId,
        categoryName:
          safeString(row.categoryName) ||
          categoryMap.get(categoryId) ||
          "General",
        active: row.active !== false,
        imageUrl: safeString(row.imageUrl),
      };
    });
    const filtered = items.filter((row) => {
      if (activeFilter && activeFilter !== "all") {
        const active = row.active === true;
        if (["true", "active", "1"].includes(activeFilter) && !active) return false;
        if (["false", "inactive", "0"].includes(activeFilter) && active) return false;
      }
      if (!query) return true;
      return mapRowContains([row.id, row.name, row.categoryName, row.categoryId], query);
    });

    const sorted = filtered.sort((a, b) => {
      if (a.categoryName == b.categoryName) {
        return a.name.localeCompare(b.name);
      }
      return a.categoryName.localeCompare(b.categoryName);
    });
    const paged = paginateArray(sorted, pagination);
    return { data: paged.items, pagination: paged.pagination };
  }

  static async getBroadcasts(uid, user, pagination, filters = {}) {
    await this._assertAdmin(uid, user);
    const typeFilter = normalizeBroadcastType(
      safeString(filters.type || "all"),
    );
    const statusFilter = normalizeStatus(filters.status, "all");
    const roleFilter = normalizeRole(safeString(filters.role));
    const query = safeString(filters.q || filters.query).toLowerCase();
    const normalized = normalizePagination(pagination, MAX_ADMIN_BROADCAST_SCAN);
    const typeParam = safeString(filters.type).toLowerCase();
    const canUseCursor =
      (!typeParam || typeParam === "all") &&
      (!statusFilter || statusFilter === "all") &&
      !roleFilter &&
      !query &&
      (normalized.page === 1 || Boolean(normalized.cursor));

    let snap = null;
    if (canUseCursor) {
      let queryRef = db.collection("adminBroadcasts").orderBy("createdAt", "desc");
      queryRef = await this._applyDocCursor(queryRef, "adminBroadcasts", normalized.cursor);
      const fetchLimit = normalized.cursor ? normalized.limit + 1 : normalized.limit;
      snap = await queryRef.limit(fetchLimit).get();
    } else {
      const queryLimit = readWindow(pagination, MAX_ADMIN_BROADCAST_SCAN);
      snap = await db.collection("adminBroadcasts").limit(queryLimit).get();
    }
    await this._recordReadUsage(snap.size, { endpoint: "admin_broadcasts" });
    const now = Date.now();
    let sourceDocs = snap.docs;
    if (canUseCursor && normalized.cursor && sourceDocs.length > normalized.limit) {
      sourceDocs = sourceDocs.slice(0, normalized.limit);
    }

    const items = sourceDocs
      .map((doc) => {
        const row = doc.data() || {};
        const active = row.active !== false;
        const targetRoles = normalizeRoleList(row.targetRoles);
        const type = normalizeBroadcastType(row.type);
        const startAt = toIso(row.startAt);
        const endAt = toIso(row.endAt);
        const lifecycle = lifecycleForWindow({
          active,
          startAt,
          endAt,
          now,
        });
        return {
          id: doc.id,
          type,
          title: safeString(row.title) || "Platform update",
          message: safeString(row.message),
          targetRoles,
          promoCode: safeString(row.promoCode).toUpperCase(),
          promoCodeId: safeString(row.promoCodeId),
          active,
          lifecycle,
          startAt,
          endAt,
          createdAt: toIso(row.createdAt),
          updatedAt: toIso(row.updatedAt),
          createdByUid: safeString(row.createdByUid),
          createdByName: safeString(row.createdByName),
        };
      })
      .filter((row) => {
        if (safeString(filters.type) && safeString(filters.type).toLowerCase() !== "all") {
          if (row.type !== typeFilter) return false;
        }
        if (statusFilter && statusFilter !== "all") {
          if (row.lifecycle !== statusFilter) return false;
        }
        if (roleFilter) {
          if (!row.targetRoles.includes(roleFilter)) return false;
        }
        if (!query) return true;
        return mapRowContains(
          [
            row.id,
            row.title,
            row.message,
            row.type,
            row.promoCode,
            row.lifecycle,
            row.targetRoles.join(","),
          ],
          query,
        );
      });
    if (canUseCursor) {
      const hasNextPage = normalized.cursor
        ? snap.docs.length > normalized.limit
        : snap.docs.length >= normalized.limit;
      const sorted = sortByNewest(items, (row) => toMillis(row.createdAt));
      return {
        data: sorted,
        pagination: {
          page: normalized.page,
          limit: normalized.limit,
          totalItems: sorted.length + (hasNextPage ? 1 : 0),
          totalPages: hasNextPage ? normalized.page + 1 : normalized.page,
          hasPrevPage: Boolean(normalized.cursor) || normalized.page > 1,
          hasNextPage,
          nextCursor: hasNextPage && sourceDocs.length > 0 ? sourceDocs[sourceDocs.length - 1].id : "",
        },
      };
    }
    const sorted = sortByNewest(items, (row) => toMillis(row.createdAt));
    const paged = paginateArray(sorted, pagination);
    return { data: paged.items, pagination: paged.pagination };
  }

  static async createBroadcast(uid, user, payload = {}) {
    await this._assertAdmin(uid, user);

    const title = safeString(payload.title);
    const message = safeString(payload.message);
    if (title.length < 3) {
      const error = new Error("title is required (min 3 chars)");
      error.status = 400;
      throw error;
    }
    if (message.length < 3) {
      const error = new Error("message is required (min 3 chars)");
      error.status = 400;
      throw error;
    }

    const type = normalizeBroadcastType(payload.type);
    const targetRoles = normalizeRoleList(payload.targetRoles);
    const active = parseBoolean(payload.active, true);
    const startAt = toIsoOrNull(payload.startAt);
    const endAt = toIsoOrNull(payload.endAt);
    if (payload.startAt !== undefined && !startAt) {
      const error = new Error("startAt must be a valid ISO date");
      error.status = 400;
      throw error;
    }
    if (payload.endAt !== undefined && !endAt) {
      const error = new Error("endAt must be a valid ISO date");
      error.status = 400;
      throw error;
    }
    if (startAt && endAt && toMillis(endAt) < toMillis(startAt)) {
      const error = new Error("endAt must be later than startAt");
      error.status = 400;
      throw error;
    }

    const promoCode = safeString(payload.promoCode).toUpperCase();
    const hasPromo = promoCode.length > 0;
    let promoCodeId = "";

    const now = admin.firestore.FieldValue.serverTimestamp();
    if (hasPromo) {
      const existing = await db
        .collection("promoCodes")
        .where("code", "==", promoCode)
        .limit(1)
        .get();
      if (!existing.empty) {
        const error = new Error("promoCode already exists");
        error.status = 400;
        throw error;
      }
      const discountValue = toNumber(payload.discountValue, 0);
      if (!(discountValue > 0)) {
        const error = new Error("discountValue is required and must be > 0");
        error.status = 400;
        throw error;
      }
      const discountType = normalizePromoDiscountType(payload.discountType);
      if (discountType === "percent" && discountValue > 100) {
        const error = new Error("percent discountValue cannot exceed 100");
        error.status = 400;
        throw error;
      }
      const minSubtotal = Math.max(0, toNumber(payload.minSubtotal, 0));
      const maxDiscount = Math.max(0, toNumber(payload.maxDiscount, 0));
      const usageLimit = Math.max(0, Math.floor(toNumber(payload.usageLimit, 0)));
      const promoRef = db.collection("promoCodes").doc();
      promoCodeId = promoRef.id;
      await promoRef.set({
        id: promoRef.id,
        code: promoCode,
        title,
        description: message,
        discountType,
        discountValue,
        minSubtotal,
        maxDiscount,
        usageLimit,
        usedCount: 0,
        targetRoles,
        active,
        startAt: startAt || null,
        endAt: endAt || null,
        createdByUid: uid,
        createdByName: safeString(user?.name || user?.email) || "Admin",
        createdAt: now,
        updatedAt: now,
      });
    }

    const ref = db.collection("adminBroadcasts").doc();
    await ref.set({
      id: ref.id,
      type,
      title,
      message,
      targetRoles,
      active,
      promoCode,
      promoCodeId,
      startAt: startAt || null,
      endAt: endAt || null,
      createdByUid: uid,
      createdByName: safeString(user?.name || user?.email) || "Admin",
      createdAt: now,
      updatedAt: now,
    });
    const created = await ref.get();
    const row = created.data() || {};
    const lifecycle = lifecycleForWindow({
      active: row.active !== false,
      startAt: row.startAt,
      endAt: row.endAt,
    });
    return {
      data: {
        id: created.id,
        type: normalizeBroadcastType(row.type),
        title: safeString(row.title),
        message: safeString(row.message),
        targetRoles: normalizeRoleList(row.targetRoles),
        active: row.active !== false,
        promoCode: safeString(row.promoCode),
        promoCodeId: safeString(row.promoCodeId),
        lifecycle,
        startAt: toIso(row.startAt),
        endAt: toIso(row.endAt),
        createdAt: toIso(row.createdAt),
        updatedAt: toIso(row.updatedAt),
      },
    };
  }

  static async updateBroadcastActive(uid, user, broadcastId, payload = {}) {
    await this._assertAdmin(uid, user);
    const active = parseBoolean(payload.active, true);
    const ref = db.collection("adminBroadcasts").doc(broadcastId);
    const snap = await ref.get();
    if (!snap.exists) {
      const error = new Error("broadcast not found");
      error.status = 404;
      throw error;
    }
    const row = snap.data() || {};
    await ref.set(
      {
        active,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    const promoCodeId = safeString(row.promoCodeId);
    if (promoCodeId) {
      await db
        .collection("promoCodes")
        .doc(promoCodeId)
        .set(
          {
            active,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
    }
    return {
      data: {
        id: broadcastId,
        active,
        promoCodeId,
      },
    };
  }

  static async getReadBudget(uid, user) {
    await this._assertAdmin(uid, user);
    const key = utcDayKey();
    const snap = await db.collection("adminUsage").doc(key).get();
    const row = snap.exists ? snap.data() || {} : {};
    const used = Math.max(0, Math.floor(toNumber(row.estimatedReadsUsed, 0)));
    const remaining = Math.max(0, READ_BUDGET_DAILY - used);
    const usedPercent = Number(((used / READ_BUDGET_DAILY) * 100).toFixed(2));
    const level = usedPercent >= 90 ? "critical" : usedPercent >= 70 ? "warning" : "healthy";
    const endpointReads =
      row.endpointReads && typeof row.endpointReads === "object" ? row.endpointReads : {};
    return {
      data: {
        dateKey: key,
        dailyBudget: READ_BUDGET_DAILY,
        estimatedReadsUsed: used,
        estimatedReadsRemaining: remaining,
        usedPercent,
        level,
        endpointReads,
      },
    };
  }

  static async globalSearch(uid, user, payload = {}) {
    await this._assertAdmin(uid, user);
    const query = safeString(payload.q || payload.query);
    const limit = Math.min(
      8,
      Math.max(1, Number.parseInt(safeString(payload.limit || "5"), 10) || 5),
    );
    if (query.length < 3) {
      return { data: { query, total: 0, groups: [] } };
    }
    const searchWindow = Math.max(20, limit * 4);
    await this._assertReadBudgetAvailable(searchWindow * 6, { endpoint: "search" });
    const [usersSnap, ordersSnap, finderSnap, providerSnap, ticketsSnap, servicesSnap] =
      await Promise.all([
        db.collection("users").limit(searchWindow).get(),
        db.collection("orders").limit(searchWindow).get(),
        db.collection("finderPosts").limit(searchWindow).get(),
        db.collection("providerPosts").limit(searchWindow).get(),
        db.collectionGroup("helpTickets").limit(searchWindow).get().catch(() => null),
        db.collection("services").limit(searchWindow).get(),
      ]);

    await this._recordReadUsage(
      usersSnap.size +
        ordersSnap.size +
        finderSnap.size +
        providerSnap.size +
        (ticketsSnap?.size || 0) +
        servicesSnap.size,
      { endpoint: "search" },
    );

    const userResults = usersSnap.docs
      .map((doc) => {
        const row = doc.data() || {};
        return {
          id: doc.id,
          section: "users",
          title: safeString(row.name) || "Unnamed User",
          subtitle: `${safeString(row.email) || "-"} • ${displayRole(row)}`,
        };
      })
      .filter((item) => mapRowContains([item.id, item.title, item.subtitle], query))
      .slice(0, limit);

    const orderResults = ordersSnap.docs
      .map((doc) => {
        const row = mapOrderDoc(doc);
        return {
          id: row.id,
          section: "orders",
          title: safeString(row.serviceName) || "Service",
          subtitle: `${safeString(row.finderName) || "Finder"} → ${safeString(row.providerName) || "Provider"} • ${safeString(row.status)}`,
        };
      })
      .filter((item) => mapRowContains([item.id, item.title, item.subtitle], query))
      .slice(0, limit);

    const postResults = [
      ...finderSnap.docs.map((doc) => {
        const row = doc.data() || {};
        const services = normalizeServiceList(row);
        return {
          id: doc.id,
          section: "posts",
          title: safeString(row.clientName) || "Finder Request",
          subtitle: `Finder request • ${serviceSummary(services) || "Service"} • ${safeString(row.location) || "-"}`,
        };
      }),
      ...providerSnap.docs.map((doc) => {
        const row = doc.data() || {};
        const services = normalizeServiceList(row);
        return {
          id: doc.id,
          section: "posts",
          title: safeString(row.providerName) || "Provider Offer",
          subtitle: `Provider offer • ${serviceSummary(services) || "Service"} • ${safeString(row.area) || "-"}`,
        };
      }),
    ]
      .filter((item) => mapRowContains([item.id, item.title, item.subtitle], query))
      .slice(0, limit);

    const ticketResults = (ticketsSnap?.docs || [])
      .map((doc) => {
        const row = doc.data() || {};
        return {
          id: doc.id,
          section: "tickets",
          title: safeString(row.title) || "Support ticket",
          subtitle: `${safeString(row.status) || "open"} • ${safeString(row.message) || "-"}`,
        };
      })
      .filter((item) => mapRowContains([item.id, item.title, item.subtitle], query))
      .slice(0, limit);

    const serviceResults = servicesSnap.docs
      .map((doc) => {
        const row = doc.data() || {};
        return {
          id: doc.id,
          section: "services",
          title: safeString(row.name) || "Service",
          subtitle: `${safeString(row.categoryName) || "General"} • ${row.active === false ? "inactive" : "active"}`,
        };
      })
      .filter((item) => mapRowContains([item.id, item.title, item.subtitle], query))
      .slice(0, limit);

    const groups = [
      { section: "users", label: "Users", items: userResults },
      { section: "orders", label: "Orders", items: orderResults },
      { section: "posts", label: "Posts", items: postResults },
      { section: "tickets", label: "Tickets", items: ticketResults },
      { section: "services", label: "Services", items: serviceResults },
    ].filter((group) => group.items.length > 0);

    const total = groups.reduce((sum, group) => sum + group.items.length, 0);
    return { data: { query, total, groups } };
  }

  static async updateUserStatus(uid, user, userId, payload = {}) {
    await this._assertAdmin(uid, user);
    const reason = safeString(payload.reason || payload.note);
    if (reason.length < 3) {
      const error = new Error("reason is required (min 3 chars)");
      error.status = 400;
      throw error;
    }
    const active = parseBoolean(payload.active, true);
    const ref = db.collection("users").doc(userId);
    const snap = await ref.get();
    if (!snap.exists) {
      const error = new Error("user not found");
      error.status = 404;
      throw error;
    }
    const row = snap.data() || {};
    const previousState = { active: row.active !== false };
    await ref.set(
      { active, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true },
    );
    const undo = await this._createUndoAction({
      adminUid: uid,
      actionType: "user_status",
      targetLabel: userId,
      docPath: `users/${userId}`,
      previousState,
      nextState: { active },
      reason,
    });
    return { data: { id: userId, active, reason, ...undo } };
  }

  static async updateOrderStatus(uid, user, orderId, payload = {}) {
    await this._assertAdmin(uid, user);
    const reason = safeString(payload.reason || payload.note);
    if (reason.length < 3) {
      const error = new Error("reason is required (min 3 chars)");
      error.status = 400;
      throw error;
    }
    const status = normalizeStatus(payload.status);
    if (!ALLOWED_ORDER_STATUSES.includes(status)) {
      const error = new Error("invalid order status");
      error.status = 400;
      throw error;
    }
    const ref = db.collection("orders").doc(orderId);
    const snap = await ref.get();
    if (!snap.exists) {
      const error = new Error("order not found");
      error.status = 404;
      throw error;
    }
    const row = snap.data() || {};
    const previousState = { status: safeString(row.status) || "booked" };
    await ref.set(
      { status, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true },
    );
    const undo = await this._createUndoAction({
      adminUid: uid,
      actionType: "order_status",
      targetLabel: orderId,
      docPath: `orders/${orderId}`,
      previousState,
      nextState: { status },
      reason,
    });
    return { data: { id: orderId, status, reason, ...undo } };
  }

  static async updatePostStatus(uid, user, source, postId, payload = {}) {
    await this._assertAdmin(uid, user);
    const reason = safeString(payload.reason || payload.note);
    if (reason.length < 3) {
      const error = new Error("reason is required (min 3 chars)");
      error.status = 400;
      throw error;
    }
    const sourceCollection = safeString(source);
    if (!["finderPosts", "providerPosts"].includes(sourceCollection)) {
      const error = new Error("invalid source collection");
      error.status = 400;
      throw error;
    }
    const status = normalizeStatus(payload.status);
    if (!ALLOWED_POST_STATUSES.includes(status)) {
      const error = new Error("invalid post status");
      error.status = 400;
      throw error;
    }
    const ref = db.collection(sourceCollection).doc(postId);
    const snap = await ref.get();
    if (!snap.exists) {
      const error = new Error("post not found");
      error.status = 404;
      throw error;
    }
    const row = snap.data() || {};
    const previousState = { status: safeString(row.status) || "open" };
    await ref.set(
      { status, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true },
    );
    const undo = await this._createUndoAction({
      adminUid: uid,
      actionType: "post_status",
      targetLabel: `${sourceCollection}/${postId}`,
      docPath: `${sourceCollection}/${postId}`,
      previousState,
      nextState: { status },
      reason,
    });
    return { data: { id: postId, sourceCollection, status, reason, ...undo } };
  }

  static async updateTicketStatus(uid, user, userUid, ticketId, payload = {}) {
    await this._assertAdmin(uid, user);
    const reason = safeString(payload.reason || payload.note);
    if (reason.length < 3) {
      const error = new Error("reason is required (min 3 chars)");
      error.status = 400;
      throw error;
    }
    const status = normalizeStatus(payload.status);
    if (!ALLOWED_TICKET_STATUSES.includes(status)) {
      const error = new Error("invalid ticket status");
      error.status = 400;
      throw error;
    }
    const ref = db.collection("users").doc(userUid).collection("helpTickets").doc(ticketId);
    const snap = await ref.get();
    if (!snap.exists) {
      const error = new Error("ticket not found");
      error.status = 404;
      throw error;
    }
    const row = snap.data() || {};
    const previousState = { status: safeString(row.status) || "open" };
    await ref.set(
      { status, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true },
    );
    const undo = await this._createUndoAction({
      adminUid: uid,
      actionType: "ticket_status",
      targetLabel: `${userUid}/${ticketId}`,
      docPath: `users/${userUid}/helpTickets/${ticketId}`,
      previousState,
      nextState: { status },
      reason,
    });
    return { data: { id: ticketId, userUid, status, reason, ...undo } };
  }

  static async updateServiceActive(uid, user, serviceId, payload = {}) {
    await this._assertAdmin(uid, user);
    const reason = safeString(payload.reason || payload.note);
    if (reason.length < 3) {
      const error = new Error("reason is required (min 3 chars)");
      error.status = 400;
      throw error;
    }
    const active = parseBoolean(payload.active, true);
    const ref = db.collection("services").doc(serviceId);
    const snap = await ref.get();
    if (!snap.exists) {
      const error = new Error("service not found");
      error.status = 404;
      throw error;
    }
    const row = snap.data() || {};
    const previousState = { active: row.active !== false };
    await ref.set(
      { active, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true },
    );
    const undo = await this._createUndoAction({
      adminUid: uid,
      actionType: "service_active",
      targetLabel: serviceId,
      docPath: `services/${serviceId}`,
      previousState,
      nextState: { active },
      reason,
    });
    return { data: { id: serviceId, active, reason, ...undo } };
  }

  static async getUndoHistory(uid, user, pagination = {}, filters = {}) {
    await this._assertAdmin(uid, user);
    const query = safeString(filters.q || filters.query);
    const stateFilter = normalizeStatus(filters.state, "all");
    const normalized = normalizePagination(pagination, 200);
    const canUseCursor =
      !query &&
      (!stateFilter || stateFilter === "all") &&
      (normalized.page === 1 || Boolean(normalized.cursor));
    let snap = null;
    if (canUseCursor) {
      let queryRef = db.collection("adminUndoActions").orderBy("createdAt", "desc");
      queryRef = await this._applyDocCursor(queryRef, "adminUndoActions", normalized.cursor);
      const fetchLimit = normalized.cursor ? normalized.limit + 1 : normalized.limit;
      snap = await queryRef.limit(fetchLimit).get();
    } else {
      const scanLimit = readWindow(pagination, 200);
      snap = await db
        .collection("adminUndoActions")
        .orderBy("createdAt", "desc")
        .limit(scanLimit)
        .get();
    }

    await this._recordReadUsage(snap.size, { endpoint: "undo_history" });

    const now = Date.now();
    let sourceDocs = snap.docs;
    if (canUseCursor && normalized.cursor && sourceDocs.length > normalized.limit) {
      sourceDocs = sourceDocs.slice(0, normalized.limit);
    }
    const rows = sourceDocs
      .map((doc) => {
        const row = doc.data() || {};
        const usedAt = toIso(row.usedAt);
        const expiresAt = toIso(row.expiresAt);
        const expiresMillis = toMillis(row.expiresAt);
        const isExpired = !usedAt && expiresMillis > 0 && now > expiresMillis;
        const state = usedAt ? "used" : isExpired ? "expired" : "available";
        return {
          id: doc.id,
          undoToken: doc.id,
          actionType: safeString(row.actionType),
          targetLabel: safeString(row.targetLabel),
          reason: safeString(row.reason),
          docPath: safeString(row.docPath),
          createdAt: toIso(row.createdAt),
          expiresAt,
          usedAt,
          usedBy: safeString(row.usedBy),
          state,
          canUndo: state === "available",
        };
      })
      .filter((item) => {
        if (!mapRowContains(
          [
            item.id,
            item.actionType,
            item.targetLabel,
            item.reason,
            item.docPath,
            item.state,
          ],
          query,
        )) {
          return false;
        }
        if (stateFilter && stateFilter !== "all") {
          return item.state === stateFilter;
        }
        return true;
      });
    if (canUseCursor) {
      const hasNextPage = normalized.cursor
        ? snap.docs.length > normalized.limit
        : snap.docs.length >= normalized.limit;
      return {
        data: rows,
        pagination: {
          page: normalized.page,
          limit: normalized.limit,
          totalItems: rows.length + (hasNextPage ? 1 : 0),
          totalPages: hasNextPage ? normalized.page + 1 : normalized.page,
          hasPrevPage: Boolean(normalized.cursor) || normalized.page > 1,
          hasNextPage,
          nextCursor: hasNextPage && rows.length > 0 ? rows[rows.length - 1].id : "",
        },
      };
    }
    const paged = paginateArray(rows, pagination);
    return { data: paged.items, pagination: paged.pagination };
  }

  static async undoAction(uid, user, payload = {}) {
    await this._assertAdmin(uid, user);
    const token = safeString(payload.undoToken || payload.token);
    if (!token) {
      const error = new Error("undoToken is required");
      error.status = 400;
      throw error;
    }
    const ref = db.collection("adminUndoActions").doc(token);
    const snap = await ref.get();
    if (!snap.exists) {
      const error = new Error("undo action not found");
      error.status = 404;
      throw error;
    }
    const row = snap.data() || {};
    if (row.usedAt) {
      const error = new Error("undo token already used");
      error.status = 400;
      throw error;
    }
    if (toMillis(row.expiresAt) > 0 && Date.now() > toMillis(row.expiresAt)) {
      const error = new Error("undo token expired");
      error.status = 400;
      throw error;
    }
    const docPath = safeString(row.docPath);
    if (!docPath) {
      const error = new Error("invalid undo payload");
      error.status = 400;
      throw error;
    }
    await db.doc(docPath).set(
      {
        ...(row.previousState && typeof row.previousState === "object" ? row.previousState : {}),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    await ref.set(
      {
        usedAt: admin.firestore.FieldValue.serverTimestamp(),
        usedBy: uid,
      },
      { merge: true },
    );
    return {
      data: {
        undoToken: token,
        restoredPath: docPath,
        restoredState:
          row.previousState && typeof row.previousState === "object"
            ? row.previousState
            : {},
      },
    };
  }
}

export default AdminService;
