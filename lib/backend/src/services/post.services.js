import admin from "firebase-admin";
import { db } from "../config/firebase.js";
import { paginateArray } from "../utils/pagination.util.js";

const MAX_POST_SCAN = 120;

function readWindow(pagination) {
  const page = Math.max(1, Number.parseInt((pagination?.page ?? 1).toString(), 10) || 1);
  const limit = Math.max(1, Number.parseInt((pagination?.limit ?? 10).toString(), 10) || 10);
  return Math.min(MAX_POST_SCAN, page * limit + 1);
}

function normalizePagination(pagination) {
  return {
    page: Math.max(1, Number.parseInt((pagination?.page ?? 1).toString(), 10) || 1),
    limit: Math.min(
      MAX_POST_SCAN,
      Math.max(1, Number.parseInt((pagination?.limit ?? 10).toString(), 10) || 10),
    ),
    cursor: (pagination?.cursor ?? "").toString().trim(),
  };
}

async function applyCollectionCursor(query, collectionName, cursor) {
  const cursorId = (cursor || "").toString().trim();
  if (!cursorId) return query;
  const snap = await db.collection(collectionName).doc(cursorId).get();
  if (!snap.exists) return query;
  return query.startAfter(snap);
}

function normalizeProviderType(value) {
  const normalized = (value || "").toString().trim().toLowerCase();
  if (normalized === "company") return "company";
  return "individual";
}

function normalizeProviderMaxWorkers(value, providerType) {
  if (providerType !== "company") return 1;
  const parsed = Number.parseInt((value ?? "").toString(), 10);
  if (Number.isFinite(parsed) && parsed > 0) return parsed;
  return 1;
}

function normalizeServicesInput(payload = {}) {
  const values = [];
  if (Array.isArray(payload.services)) {
    payload.services.forEach((entry) => {
      const text = (entry || "").toString().trim();
      if (text) values.push(text);
    });
  }
  const primary = (payload.service || "").toString().trim();
  if (primary) values.push(primary);
  return Array.from(new Set(values));
}

function mapPostServices(row = {}) {
  return normalizeServicesInput({
    service: row.service,
    services: row.services,
  });
}

class PostService {
  static async createFinderRequest(uid, user, payload) {
    const finderRef = db.collection("finders").doc(uid);
    const finderSnap = await finderRef.get();
    const finderData = finderSnap.exists ? finderSnap.data() : {};
    const userSnap = await db.collection("users").doc(uid).get();
    const userData = userSnap.exists ? userSnap.data() : {};
    const payloadLocation = (payload.location || "").toString().trim();
    const profileCity = (finderData?.city || "").toString().trim();
    const profileLocation = (finderData?.location || "").toString().trim();
    const resolvedLocation =
      payloadLocation || profileLocation || profileCity || "Phnom Penh, Cambodia";
    const clientName =
      (userData?.name || user?.name || "Finder User").toString().trim() || "Finder User";
    const services = normalizeServicesInput(payload);
    if (services.length === 0) {
      const error = new Error("service or services[] is required");
      error.status = 400;
      throw error;
    }
    const primaryService = services.length > 0 ? services[0] : "";

    const docRef = db.collection("finderPosts").doc();
    const now = admin.firestore.FieldValue.serverTimestamp();
    const item = {
      id: docRef.id,
      finderUid: uid,
      clientName,
      clientAvatarUrl: user?.picture || "",
      category: payload.category.toString().trim(),
      service: primaryService,
      services,
      location: resolvedLocation,
      message: payload.message.toString().trim(),
      preferredDate: payload.preferredDate
        ? new Date(payload.preferredDate).toISOString()
        : null,
      status: "open",
      createdAt: now,
      updatedAt: now,
    };
    await docRef.set(item);
    await finderRef.set(
      {
        city: resolvedLocation,
        location: resolvedLocation,
      },
      { merge: true },
    );
    return { data: item };
  }

  static async getFinderRequests(pagination) {
    const normalized = normalizePagination(pagination);
    const canUseCursor = normalized.page === 1 || Boolean(normalized.cursor);
    if (canUseCursor) {
      let queryRef = db.collection("finderPosts").orderBy("createdAt", "desc");
      queryRef = await applyCollectionCursor(queryRef, "finderPosts", normalized.cursor);
      const fetchLimit = normalized.cursor ? normalized.limit + 1 : normalized.limit;
      const snap = await queryRef.limit(fetchLimit).get();
      let docs = snap.docs;
      const hasNextPage = normalized.cursor
        ? docs.length > normalized.limit
        : docs.length >= normalized.limit;
      if (normalized.cursor && docs.length > normalized.limit) {
        docs = docs.slice(0, normalized.limit);
      }
      const items = docs
        .map((doc) => {
          const row = doc.data();
          const services = mapPostServices(row);
          return {
            id: doc.id,
            finderUid: row.finderUid || "",
            clientName: row.clientName || "Finder User",
            clientAvatarUrl: row.clientAvatarUrl || "",
            category: row.category || "",
            service:
              (row.service || "").toString().trim() || (services[0] || ""),
            services,
            location: row.location || "",
            message: row.message || "",
            preferredDate: row.preferredDate || null,
            status: row.status || "open",
            createdAt: row.createdAt || null,
          };
        })
        .filter((item) => item.status === "open");
      return {
        data: items,
        pagination: {
          page: normalized.page,
          limit: normalized.limit,
          totalItems: items.length + (hasNextPage ? 1 : 0),
          totalPages: hasNextPage ? normalized.page + 1 : normalized.page,
          hasPrevPage: Boolean(normalized.cursor) || normalized.page > 1,
          hasNextPage,
          nextCursor: hasNextPage && docs.length > 0 ? docs[docs.length - 1].id : "",
        },
      };
    }

    const queryLimit = readWindow(pagination);
    const snap = await db
      .collection("finderPosts")
      .orderBy("createdAt", "desc")
      .limit(queryLimit)
      .get();
    if (snap.empty) {
      const paged = paginateArray([], pagination);
      return { data: paged.items, pagination: paged.pagination };
    }

    const items = snap.docs
      .map((doc) => {
        const row = doc.data();
        const services = mapPostServices(row);
        return {
          id: doc.id,
          finderUid: row.finderUid || "",
          clientName: row.clientName || "Finder User",
          clientAvatarUrl: row.clientAvatarUrl || "",
          category: row.category || "",
          service:
            (row.service || "").toString().trim() || (services[0] || ""),
          services,
          location: row.location || "",
          message: row.message || "",
          preferredDate: row.preferredDate || null,
          status: row.status || "open",
          createdAt: row.createdAt || null,
        };
      })
      .filter((item) => item.status === "open");
    const paged = paginateArray(items, pagination);
    return { data: paged.items, pagination: paged.pagination };
  }

  static async createProviderOffer(uid, user, payload) {
    const providerSnap = await db.collection("providers").doc(uid).get();
    const providerRow = providerSnap.exists ? providerSnap.data() || {} : {};
    const providerType = normalizeProviderType(providerRow.providerType);
    const providerCompanyName = (providerRow.companyName || "").toString().trim();
    const providerMaxWorkers = normalizeProviderMaxWorkers(
      providerRow.maxWorkers,
      providerType,
    );
    const services = normalizeServicesInput(payload);
    if (services.length === 0) {
      const error = new Error("service or services[] is required");
      error.status = 400;
      throw error;
    }
    const primaryService = services.length > 0 ? services[0] : "";
    const docRef = db.collection("providerPosts").doc();
    const now = admin.firestore.FieldValue.serverTimestamp();
    const item = {
      id: docRef.id,
      providerUid: uid,
      providerName: user?.name || "Service Provider",
      providerAvatarUrl: user?.picture || "",
      category: payload.category.toString().trim(),
      service: primaryService,
      services,
      area: payload.area.toString().trim(),
      details: payload.details.toString().trim(),
      ratePerHour: Number(payload.ratePerHour || 0),
      availableNow: payload.availableNow === true,
      providerType,
      providerCompanyName: providerType === "company" ? providerCompanyName : "",
      providerMaxWorkers,
      status: "open",
      createdAt: now,
      updatedAt: now,
    };
    await docRef.set(item);
    return { data: item };
  }

  static async getProviderOffers(pagination) {
    const normalized = normalizePagination(pagination);
    const canUseCursor = normalized.page === 1 || Boolean(normalized.cursor);
    if (canUseCursor) {
      let queryRef = db.collection("providerPosts").orderBy("createdAt", "desc");
      queryRef = await applyCollectionCursor(queryRef, "providerPosts", normalized.cursor);
      const fetchLimit = normalized.cursor ? normalized.limit + 1 : normalized.limit;
      const snap = await queryRef.limit(fetchLimit).get();
      let docs = snap.docs;
      const hasNextPage = normalized.cursor
        ? docs.length > normalized.limit
        : docs.length >= normalized.limit;
      if (normalized.cursor && docs.length > normalized.limit) {
        docs = docs.slice(0, normalized.limit);
      }
      const items = docs
        .map((doc) => {
          const row = doc.data();
          const services = mapPostServices(row);
          return {
            id: doc.id,
            providerUid: row.providerUid || "",
            providerName: row.providerName || "Service Provider",
            providerAvatarUrl: row.providerAvatarUrl || "",
            category: row.category || "",
            service:
              (row.service || "").toString().trim() || (services[0] || ""),
            services,
            area: row.area || "",
            details: row.details || "",
            ratePerHour: Number(row.ratePerHour || 0),
            availableNow: row.availableNow === true,
            providerType: normalizeProviderType(row.providerType),
            providerCompanyName: (row.providerCompanyName || "").toString(),
            providerMaxWorkers: normalizeProviderMaxWorkers(
              row.providerMaxWorkers,
              normalizeProviderType(row.providerType),
            ),
            status: row.status || "open",
            createdAt: row.createdAt || null,
          };
        })
        .filter((item) => item.status === "open");
      return {
        data: items,
        pagination: {
          page: normalized.page,
          limit: normalized.limit,
          totalItems: items.length + (hasNextPage ? 1 : 0),
          totalPages: hasNextPage ? normalized.page + 1 : normalized.page,
          hasPrevPage: Boolean(normalized.cursor) || normalized.page > 1,
          hasNextPage,
          nextCursor: hasNextPage && docs.length > 0 ? docs[docs.length - 1].id : "",
        },
      };
    }

    const queryLimit = readWindow(pagination);
    const snap = await db
      .collection("providerPosts")
      .orderBy("createdAt", "desc")
      .limit(queryLimit)
      .get();
    if (snap.empty) {
      const paged = paginateArray([], pagination);
      return { data: paged.items, pagination: paged.pagination };
    }

    const items = snap.docs
      .map((doc) => {
        const row = doc.data();
        const services = mapPostServices(row);
        return {
          id: doc.id,
          providerUid: row.providerUid || "",
          providerName: row.providerName || "Service Provider",
          providerAvatarUrl: row.providerAvatarUrl || "",
          category: row.category || "",
          service:
            (row.service || "").toString().trim() || (services[0] || ""),
          services,
          area: row.area || "",
          details: row.details || "",
          ratePerHour: Number(row.ratePerHour || 0),
          availableNow: row.availableNow === true,
          providerType: normalizeProviderType(row.providerType),
          providerCompanyName: (row.providerCompanyName || "").toString(),
          providerMaxWorkers: normalizeProviderMaxWorkers(
            row.providerMaxWorkers,
            normalizeProviderType(row.providerType),
          ),
          status: row.status || "open",
          createdAt: row.createdAt || null,
        };
      })
      .filter((item) => item.status === "open");
    const paged = paginateArray(items, pagination);
    return { data: paged.items, pagination: paged.pagination };
  }
}

export default PostService;
