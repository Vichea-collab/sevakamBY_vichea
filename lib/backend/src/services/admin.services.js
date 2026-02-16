import { db } from "../config/firebase.js";
import { paginateArray } from "../utils/pagination.util.js";
import { mapOrderDoc } from "./order.services.js";

const DEFAULT_ADMIN_EMAIL = "admin@gmail.com";

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
      db.collection("users").get(),
      db.collection("finders").get(),
      db.collection("providers").get(),
      db.collection("orders").get(),
      db.collection("finderPosts").get(),
      db.collection("providerPosts").get(),
      db.collection("categories").get(),
      db.collection("services").get(),
    ]);

    let ticketsSnap = null;
    try {
      ticketsSnap = await db.collectionGroup("helpTickets").get();
    } catch (_) {
      ticketsSnap = null;
    }

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

  static async getUsers(uid, user, pagination) {
    await this._assertAdmin(uid, user);
    const snap = await db.collection("users").get();
    const items = snap.docs.map((doc) => {
      const row = doc.data() || {};
      return {
        id: doc.id,
        name: safeString(row.name) || "Unnamed User",
        email: safeString(row.email),
        role: displayRole(row),
        createdAt: toIso(row.createdAt),
        updatedAt: toIso(row.updatedAt),
      };
    });
    const sorted = sortByNewest(items, (row) => {
      return toMillis(row.updatedAt) || toMillis(row.createdAt);
    });
    const paged = paginateArray(sorted, pagination);
    return { data: paged.items, pagination: paged.pagination };
  }

  static async getOrders(uid, user, pagination) {
    await this._assertAdmin(uid, user);
    const snap = await db.collection("orders").get();
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
    const sorted = sortByNewest(items, (row) => toMillis(row.createdAt));
    const paged = paginateArray(sorted, pagination);
    return { data: paged.items, pagination: paged.pagination };
  }

  static async getPosts(uid, user, pagination) {
    await this._assertAdmin(uid, user);
    const [finderSnap, providerSnap] = await Promise.all([
      db.collection("finderPosts").get(),
      db.collection("providerPosts").get(),
    ]);
    const items = [
      ...finderSnap.docs.map((doc) => {
        const row = doc.data() || {};
        return {
          id: doc.id,
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
    const sorted = sortByNewest(items, (row) => toMillis(row.createdAt));
    const paged = paginateArray(sorted, pagination);
    return { data: paged.items, pagination: paged.pagination };
  }

  static async getTickets(uid, user, pagination) {
    await this._assertAdmin(uid, user);
    let snap = null;
    try {
      snap = await db.collectionGroup("helpTickets").get();
    } catch (error) {
      const e = new Error("help tickets query requires index configuration");
      e.status = 500;
      throw e;
    }
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
    const sorted = sortByNewest(items, (row) => toMillis(row.createdAt));
    const paged = paginateArray(sorted, pagination);
    return { data: paged.items, pagination: paged.pagination };
  }

  static async getServices(uid, user, pagination) {
    await this._assertAdmin(uid, user);
    const [servicesSnap, categoriesSnap] = await Promise.all([
      db.collection("services").get(),
      db.collection("categories").get(),
    ]);

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
    const sorted = items.sort((a, b) => {
      if (a.categoryName == b.categoryName) {
        return a.name.localeCompare(b.name);
      }
      return a.categoryName.localeCompare(b.categoryName);
    });
    const paged = paginateArray(sorted, pagination);
    return { data: paged.items, pagination: paged.pagination };
  }
}

export default AdminService;
