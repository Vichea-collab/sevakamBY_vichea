import { db } from "../config/firebase.js";
import admin from "firebase-admin";
import { paginateArray } from "../utils/pagination.util.js";
import { mapOrderDoc } from "./order.services.js";

const DEFAULT_ADMIN_EMAIL = "admin@gmail.com";
const MAX_ADMIN_SCAN = 120;
const READ_BUDGET_DAILY = 50000;
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

function readWindow(pagination, maxLimit = MAX_ADMIN_SCAN) {
  const page = Math.max(1, Number.parseInt((pagination?.page ?? 1).toString(), 10) || 1);
  const limit = Math.max(1, Number.parseInt((pagination?.limit ?? 10).toString(), 10) || 10);
  return Math.min(maxLimit, page * limit + limit);
}

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

function toPercentDelta(current, previous) {
  const cur = toNumber(current, 0);
  const prev = toNumber(previous, 0);
  if (prev <= 0) {
    return cur > 0 ? 100 : 0;
  }
  return Number((((cur - prev) / prev) * 100).toFixed(2));
}

function normalizeRole(value) {
  const role = (value || "").toString().trim().toLowerCase();
  if (role === "finders") return "finder";
  if (role === "providers") return "provider";
  if (role === "admins") return "admin";
  return role;
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
    await ref.set(
      {
        dateKey: key,
        dailyBudget: READ_BUDGET_DAILY,
        estimatedReadsUsed: admin.firestore.FieldValue.increment(safeReads),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastEndpoint: safeString(meta.endpoint),
      },
      { merge: true },
    );
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
    const overviewLimit = 120;

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
      ...finderPostsSnap.docs.map((doc) => ({
        id: doc.id,
        type: "finder_request",
        ownerName: safeString(doc.data()?.clientName) || "Finder",
        category: safeString(doc.data()?.category),
        service: safeString(doc.data()?.service),
        status: safeString(doc.data()?.status) || "open",
        createdAt: doc.data()?.createdAt || null,
      })),
      ...providerPostsSnap.docs.map((doc) => ({
        id: doc.id,
        type: "provider_offer",
        ownerName: safeString(doc.data()?.providerName) || "Provider",
        category: safeString(doc.data()?.category),
        service: safeString(doc.data()?.service),
        status: safeString(doc.data()?.status) || "open",
        createdAt: doc.data()?.createdAt || null,
      })),
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

    return { data: overview };
  }

  static async getUsers(uid, user, pagination, filters = {}) {
    await this._assertAdmin(uid, user);
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
    const roleFilter = normalizeStatus(filters.role);
    const query = safeString(filters.q || filters.query).toLowerCase();
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
    const statusFilter = normalizeStatus(filters.status);
    const query = safeString(filters.q || filters.query).toLowerCase();
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
        return {
          id: doc.id,
          sourceCollection: "finderPosts",
          type: "finder_request",
          ownerName: safeString(row.clientName) || "Finder",
          category: safeString(row.category),
          service: safeString(row.service),
          location: safeString(row.location),
          status: safeString(row.status) || "open",
          createdAt: toIso(row.createdAt),
        };
      }),
      ...providerSnap.docs.map((doc) => {
        const row = doc.data() || {};
        return {
          id: doc.id,
          sourceCollection: "providerPosts",
          type: "provider_offer",
          ownerName: safeString(row.providerName) || "Provider",
          category: safeString(row.category),
          service: safeString(row.service),
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
        [row.id, row.ownerName, row.category, row.service, row.location, row.status],
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
        title: safeString(row.title) || "Support request",
        message: safeString(row.message),
        status: safeString(row.status) || "open",
        createdAt: toIso(row.createdAt),
      };
    });
    const statusFilter = normalizeStatus(filters.status);
    const query = safeString(filters.q || filters.query).toLowerCase();
    const filtered = items.filter((row) => {
      if (statusFilter && statusFilter !== "all") {
        if (normalizeStatus(row.status) !== statusFilter) return false;
      }
      if (!query) return true;
      return mapRowContains([row.id, row.userUid, row.title, row.message, row.status], query);
    });
    const sorted = sortByNewest(filtered, (row) => toMillis(row.createdAt));
    const paged = paginateArray(sorted, pagination);
    return { data: paged.items, pagination: paged.pagination };
  }

  static async getServices(uid, user, pagination, filters = {}) {
    await this._assertAdmin(uid, user);
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
    const activeFilter = normalizeStatus(filters.active);
    const query = safeString(filters.q || filters.query).toLowerCase();
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

  static async getReadBudget(uid, user) {
    await this._assertAdmin(uid, user);
    const key = utcDayKey();
    const snap = await db.collection("adminUsage").doc(key).get();
    const row = snap.exists ? snap.data() || {} : {};
    const used = Math.max(0, Math.floor(toNumber(row.estimatedReadsUsed, 0)));
    const remaining = Math.max(0, READ_BUDGET_DAILY - used);
    const usedPercent = Number(((used / READ_BUDGET_DAILY) * 100).toFixed(2));
    const level = usedPercent >= 90 ? "critical" : usedPercent >= 70 ? "warning" : "healthy";
    return {
      data: {
        dateKey: key,
        dailyBudget: READ_BUDGET_DAILY,
        estimatedReadsUsed: used,
        estimatedReadsRemaining: remaining,
        usedPercent,
        level,
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
    if (query.length < 2) {
      return { data: { query, total: 0, groups: [] } };
    }

    const searchWindow = Math.max(40, limit * 8);
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
        return {
          id: doc.id,
          section: "posts",
          title: safeString(row.clientName) || "Finder Request",
          subtitle: `Finder request • ${safeString(row.service) || "Service"} • ${safeString(row.location) || "-"}`,
        };
      }),
      ...providerSnap.docs.map((doc) => {
        const row = doc.data() || {};
        return {
          id: doc.id,
          section: "posts",
          title: safeString(row.providerName) || "Provider Offer",
          subtitle: `Provider offer • ${safeString(row.service) || "Service"} • ${safeString(row.area) || "-"}`,
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

  static async getAnalytics(uid, user, payload = {}) {
    await this._assertAdmin(uid, user);
    const days = Math.min(30, Math.max(7, Number.parseInt(safeString(payload.days || "14"), 10) || 14));
    const compareDays = Math.min(
      30,
      Math.max(7, Number.parseInt(safeString(payload.compareDays || `${days}`), 10) || days),
    );
    const scanLimit = Math.max(180, days * 12);

    const [ordersSnap, finderSnap, providerSnap, chatsSnap] = await Promise.all([
      db.collection("orders").limit(scanLimit).get(),
      db.collection("finderPosts").limit(scanLimit).get(),
      db.collection("providerPosts").limit(scanLimit).get(),
      db.collection("chats").limit(scanLimit).get(),
    ]);

    await this._recordReadUsage(
      ordersSnap.size + finderSnap.size + providerSnap.size + chatsSnap.size,
      { endpoint: "analytics" },
    );

    const now = Date.now();
    const dayMs = 24 * 60 * 60 * 1000;
    const currentStart = now - (days - 1) * dayMs;
    const previousEnd = currentStart - 1;
    const previousStart = previousEnd - (compareDays - 1) * dayMs;

    const inRange = (millis, start, end) => millis >= start && millis <= end;
    const dayLabel = (millis) => {
      const d = new Date(millis);
      return `${d.getUTCFullYear()}-${`${d.getUTCMonth() + 1}`.padStart(2, "0")}-${`${d.getUTCDate()}`.padStart(2, "0")}`;
    };

    const orders = ordersSnap.docs.map(mapOrderDoc);
    const currentOrders = [];
    const previousOrders = [];
    for (const order of orders) {
      const createdMillis = toMillis(order.createdAt);
      if (createdMillis <= 0) continue;
      if (inRange(createdMillis, currentStart, now)) currentOrders.push(order);
      if (inRange(createdMillis, previousStart, previousEnd)) previousOrders.push(order);
    }

    const summarize = (rows) => {
      const completed = rows.filter((row) => normalizeStatus(row.status) === "completed");
      const cancelled = rows.filter((row) => normalizeStatus(row.status) === "cancelled");
      return {
        orders: rows.length,
        completedOrders: completed.length,
        cancelledOrders: cancelled.length,
        revenue: Number(completed.reduce((sum, row) => sum + toNumber(row.total, 0), 0).toFixed(2)),
      };
    };

    const current = summarize(currentOrders);
    const previous = summarize(previousOrders);

    const buildSeries = (rows, totalDays, startMillis) => {
      const bucket = new Map();
      for (let i = 0; i < totalDays; i += 1) {
        const millis = startMillis + i * dayMs;
        bucket.set(dayLabel(millis), { date: dayLabel(millis), orders: 0, revenue: 0 });
      }
      for (const row of rows) {
        const key = dayLabel(toMillis(row.createdAt));
        if (!bucket.has(key)) continue;
        const entry = bucket.get(key);
        entry.orders += 1;
        if (normalizeStatus(row.status) === "completed") {
          entry.revenue = Number((entry.revenue + toNumber(row.total, 0)).toFixed(2));
        }
      }
      return Array.from(bucket.values());
    };

    const currentSeries = buildSeries(currentOrders, days, currentStart);
    const previousSeries = buildSeries(previousOrders, compareDays, previousStart);

    const completedServiceMap = new Map();
    for (const row of currentOrders) {
      if (normalizeStatus(row.status) !== "completed") continue;
      const key = safeString(row.serviceName) || "Service";
      const currentRow = completedServiceMap.get(key) || { serviceName: key, completedOrders: 0, revenue: 0 };
      currentRow.completedOrders += 1;
      currentRow.revenue = Number((currentRow.revenue + toNumber(row.total, 0)).toFixed(2));
      completedServiceMap.set(key, currentRow);
    }
    const topServices = Array.from(completedServiceMap.values())
      .sort((a, b) => b.completedOrders - a.completedOrders || b.revenue - a.revenue)
      .slice(0, 5);

    const funnel = {
      postIntents: [...finderSnap.docs, ...providerSnap.docs].filter((doc) => {
        const row = doc.data() || {};
        return inRange(toMillis(row.createdAt), currentStart, now);
      }).length,
      activeChats: chatsSnap.docs.filter((doc) => {
        const row = doc.data() || {};
        return inRange(toMillis(row.updatedAt || row.lastMessageAt || row.createdAt), currentStart, now);
      }).length,
      bookedOrders: current.orders,
      completedOrders: current.completedOrders,
    };

    return {
      data: {
        range: {
          currentDays: days,
          compareDays,
          currentStart: new Date(currentStart).toISOString(),
          currentEnd: new Date(now).toISOString(),
          previousStart: new Date(previousStart).toISOString(),
          previousEnd: new Date(previousEnd).toISOString(),
        },
        totals: {
          current,
          previous,
          deltaPercent: {
            orders: toPercentDelta(current.orders, previous.orders),
            completedOrders: toPercentDelta(current.completedOrders, previous.completedOrders),
            cancelledOrders: toPercentDelta(current.cancelledOrders, previous.cancelledOrders),
            revenue: toPercentDelta(current.revenue, previous.revenue),
          },
        },
        funnel,
        trend: {
          currentSeries,
          previousSeries,
        },
        topServices,
      },
    };
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
    const scanLimit = readWindow(pagination, 200);
    const snap = await db
      .collection("adminUndoActions")
      .orderBy("createdAt", "desc")
      .limit(scanLimit)
      .get();

    await this._recordReadUsage(snap.size, { endpoint: "undo_history" });

    const now = Date.now();
    const rows = snap.docs
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
