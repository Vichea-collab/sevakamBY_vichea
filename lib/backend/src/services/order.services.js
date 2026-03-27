import admin from "firebase-admin";
import { db } from "../config/firebase.js";
import { paginateArray } from "../utils/pagination.util.js";
import PushService from "./push.services.js";
import ServiceService from "./service.services.js";
import SubscriptionService from "./subscription.services.js";

const ORDER_COLLECTION = "orders";
const MAX_ORDER_SCAN = 120;
const MAX_PROVIDER_REVIEW_SCAN = 400;

const ALLOWED_STATUSES = [
  "booked",
  "on_the_way",
  "started",
  "completed",
  "cancelled",
  "declined",
];

const PROVIDER_ALLOWED_TARGETS = ["on_the_way", "started", "completed", "declined"];
const FINDER_ALLOWED_TARGETS = ["cancelled", "completed"];

function readWindow(pagination) {
  const page = Math.max(1, Number.parseInt((pagination?.page ?? 1).toString(), 10) || 1);
  const limit = Math.max(1, Number.parseInt((pagination?.limit ?? 10).toString(), 10) || 10);
  return Math.min(MAX_ORDER_SCAN, page * limit + 1);
}

function normalizePagination(pagination) {
  return {
    page: Math.max(1, Number.parseInt((pagination?.page ?? 1).toString(), 10) || 1),
    limit: Math.min(
      MAX_ORDER_SCAN,
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

function safeString(value) {
  return (value ?? "").toString().trim();
}

function toNumber(value, fallback = 0) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function normalizeReviewRating(value) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) return 0;
  const clamped = Math.max(1, Math.min(5, parsed));
  return Number(clamped.toFixed(1));
}

function normalizeReviewComment(value) {
  const text = (value || "").toString().trim();
  if (!text) return "";
  if (text.length <= 500) return text;
  return text.slice(0, 500);
}

function toIsoDate(value) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return new Date().toISOString();
  return date.toISOString();
}

function normalizeStatus(value) {
  const status = (value || "").toString().trim().toLowerCase();
  if (!ALLOWED_STATUSES.includes(status)) return "booked";
  return status;
}

function orderStatusTitle(status, role = "finder") {
  switch (normalizeStatus(status)) {
    case "on_the_way":
      return "Order Confirmed";
    case "started":
      return "Service Started";
    case "completed":
      return "Order Completed";
    case "cancelled":
      return "Order Cancelled";
    case "declined":
      return "Order Declined";
    case "booked":
    default:
      return role === "provider" ? "Upcoming Booking" : "Order Booked";
  }
}

function orderStatusMessage(row, status, role, providerNameOverride = "") {
  const normalizedStatus = normalizeStatus(status);
  const serviceName = safeString(row?.serviceName) || "service";
  const providerName =
    safeString(providerNameOverride) ||
    safeString(row?.providerName) ||
    "Provider";
  const finderName = safeString(row?.finderName) || "Customer";

  if (role === "provider") {
    switch (normalizedStatus) {
      case "booked":
        return `New upcoming booking received for ${serviceName}.`;
      case "on_the_way":
        return `You confirmed the booking for ${serviceName}.`;
      case "started":
        return `You started ${serviceName}.`;
      case "completed":
        return `${finderName} marked ${serviceName} as completed.`;
      case "cancelled":
        return `${finderName} cancelled ${serviceName}.`;
      case "declined":
        return `You declined ${serviceName}.`;
      default:
        return `Order status updated for ${serviceName}.`;
    }
  }

  switch (normalizedStatus) {
    case "booked":
      return `Your booking for ${serviceName} is confirmed.`;
    case "on_the_way":
      return `${providerName} confirmed your booking for ${serviceName}.`;
    case "started":
      return `${providerName} started ${serviceName}.`;
    case "completed":
      return `${serviceName} has been completed.`;
    case "cancelled":
      return `Your booking for ${serviceName} was cancelled.`;
    case "declined":
      return `Your booking for ${serviceName} was declined.`;
    default:
      return `Order status updated for ${serviceName}.`;
  }
}

function parseStatusFilters(value) {
  if (value === undefined || value === null) return [];
  const source = Array.isArray(value)
    ? value
    : value
        .toString()
        .split(",");
  return Array.from(
    new Set(
      source
        .map((entry) => (entry || "").toString().trim().toLowerCase())
        .filter((entry) => ALLOWED_STATUSES.includes(entry)),
    ),
  );
}

function toIsoDateOrNull(value) {
  if (!value) return null;
  if (typeof value?.toDate === "function") {
    return value.toDate().toISOString();
  }
  if (value instanceof Date) {
    return value.toISOString();
  }
  if (typeof value === "string") {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) return parsed.toISOString();
  }
  if (typeof value === "object" && value._seconds) {
    const seconds = Number(value._seconds);
    if (Number.isFinite(seconds)) {
      return new Date(Math.round(seconds * 1000)).toISOString();
    }
  }
  return null;
}

function normalizeTimeline(rawTimeline, fallbackCreatedAt, fallbackUpdatedAt, status) {
  const source =
    rawTimeline && typeof rawTimeline === "object" ? rawTimeline : {};
  const bookedAt = toIsoDateOrNull(source.bookedAt) || toIsoDateOrNull(fallbackCreatedAt);
  const onTheWayAt = toIsoDateOrNull(source.onTheWayAt);
  const startedAt = toIsoDateOrNull(source.startedAt);
  let completedAt = toIsoDateOrNull(source.completedAt);
  let cancelledAt = toIsoDateOrNull(source.cancelledAt);
  let declinedAt = toIsoDateOrNull(source.declinedAt);
  const fallback = toIsoDateOrNull(fallbackUpdatedAt);
  if (status === "completed" && !completedAt) completedAt = fallback;
  if (status === "cancelled" && !cancelledAt) cancelledAt = fallback;
  if (status === "declined" && !declinedAt) declinedAt = fallback;
  return {
    bookedAt,
    onTheWayAt,
    startedAt,
    completedAt,
    cancelledAt,
    declinedAt,
  };
}

function timelineFieldForStatus(status) {
  switch (status) {
    case "on_the_way":
      return "onTheWayAt";
    case "started":
      return "startedAt";
    case "completed":
      return "completedAt";
    case "cancelled":
      return "cancelledAt";
    case "declined":
      return "declinedAt";
    case "booked":
    default:
      return "bookedAt";
  }
}

function firstNonEmptyString(...values) {
  for (const value of values) {
    const text = (value || "").toString().trim();
    if (text) return text;
  }
  return "";
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

function normalizeRequestedWorkers(value, providerType, maxWorkers) {
  if (providerType !== "company") return 1;
  const parsed = Number.parseInt((value ?? "").toString(), 10);
  if (!Number.isFinite(parsed) || parsed < 1) return 1;
  return Math.min(parsed, Math.max(1, maxWorkers));
}

function normalizeServiceList(payload = {}) {
  const values = [];
  if (Array.isArray(payload.services)) {
    payload.services.forEach((entry) => {
      const text = (entry || "").toString().trim();
      if (text) values.push(text);
    });
  }
  const primary = firstNonEmptyString(payload.serviceName, payload.service);
  if (primary) values.push(primary);
  return Array.from(new Set(values));
}

function serviceKey(value) {
  return (value || "")
    .toString()
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/_+/g, "_")
    .replace(/^_|_$/g, "");
}

function canonicalServiceName(value) {
  const normalized = safeString(value).toLowerCase();
  switch (normalized) {
    case "ac repair":
      return "Air Conditioner Repair";
    case "door repair":
      return "Door & Window Repair";
    case "pipe leak repair":
      return "Pipe leaks";
    default:
      return safeString(value);
  }
}

async function findServiceDocForOrder(serviceId, serviceName, categoryName) {
  const normalizedServiceId = safeString(serviceId);
  if (normalizedServiceId) {
    const snap = await db.collection("services").doc(normalizedServiceId).get();
    if (snap.exists) {
      return snap;
    }
  }

  const normalizedServiceName = canonicalServiceName(serviceName);
  if (!normalizedServiceName) {
    return null;
  }

  const serviceSnap = await db
    .collection("services")
    .where("name", "==", normalizedServiceName)
    .limit(10)
    .get();
  if (serviceSnap.empty) {
    return null;
  }

  const normalizedCategoryKey = serviceKey(categoryName);
  if (normalizedCategoryKey) {
    const matched = serviceSnap.docs.find((doc) => {
      const row = doc.data() || {};
      return serviceKey(row.categoryName || row.categoryId) === normalizedCategoryKey;
    });
    if (matched) {
      return matched;
    }
  }

  return serviceSnap.docs[0];
}

function providerRatingFromProfile(row, providerRow = {}) {
  const existing = toNumber(row.providerRating, 0);
  if (existing > 0) return existing;

  const ratingSum = toNumber(providerRow.ratingSum, 0);
  const ratingCount = toNumber(providerRow.ratingCount, 0);
  if (ratingCount > 0) {
    return Number((ratingSum / ratingCount).toFixed(2));
  }
  return 4.8;
}

function validateFinderTransition(currentStatus, targetStatus) {
  if (!FINDER_ALLOWED_TARGETS.includes(targetStatus)) {
    const error = new Error("finder can only set cancelled/completed");
    error.status = 400;
    throw error;
  }
  if (["completed", "cancelled", "declined"].includes(currentStatus)) {
    const error = new Error("order already finalized");
    error.status = 400;
    throw error;
  }
  if (targetStatus === "completed" && !["started", "on_the_way"].includes(currentStatus)) {
    const error = new Error("finder can complete only after provider starts service");
    error.status = 400;
    throw error;
  }
}

function validateProviderTransition(currentStatus, targetStatus) {
  if (!PROVIDER_ALLOWED_TARGETS.includes(targetStatus)) {
    const error = new Error("invalid provider status");
    error.status = 400;
    throw error;
  }
  if (["completed", "cancelled", "declined"].includes(currentStatus)) {
    const error = new Error("order already finalized");
    error.status = 400;
    throw error;
  }

  const allowedByCurrent = {
    booked: ["on_the_way", "declined"],
    on_the_way: ["started", "completed"],
    started: ["completed"],
  };
  const allowedNext = allowedByCurrent[currentStatus] || [];
  if (!allowedNext.includes(targetStatus)) {
    const error = new Error(
      `invalid provider transition: ${currentStatus} -> ${targetStatus}`,
    );
    error.status = 400;
    throw error;
  }
}

function createdAtMillis(value) {
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

function initialsFromName(name) {
  const parts = (name || "")
    .toString()
    .trim()
    .split(/\s+/)
    .filter(Boolean);
  if (parts.length === 0) return "U";
  if (parts.length === 1) return parts[0].slice(0, 1).toUpperCase();
  return `${parts[0].slice(0, 1)}${parts[parts.length - 1].slice(0, 1)}`.toUpperCase();
}

function roleName(role) {
  const raw = (role || "").toString().trim().toLowerCase();
  if (raw === "providers") return "provider";
  if (raw === "finders") return "finder";
  return raw;
}

function userHasRole(user, expectedRole) {
  const normalizedExpected = roleName(expectedRole);
  const primary = roleName(user?.role);
  if (primary === normalizedExpected) return true;
  const roles = normalizeRoleList(user?.roles, []);
  return roles.includes(normalizedExpected);
}

function normalizeRoleList(value, fallback = ["finder", "provider"]) {
  const source = Array.isArray(value)
    ? value
    : typeof value === "string"
      ? value.split(",")
      : [];
  const normalized = Array.from(
    new Set(
      source
        .map((entry) => (entry || "").toString().trim().toLowerCase())
        .filter((entry) => ["finder", "provider"].includes(entry)),
    ),
  );
  return normalized.length > 0 ? normalized : fallback;
}

export function mapOrderDoc(doc) {
  const row = doc.data() || {};
  const status = normalizeStatus(row.status);
  return {
    id: doc.id,
    finderUid: (row.finderUid || "").toString(),
    finderName: (row.finderName || "").toString(),
    finderPhone: (row.finderPhone || "").toString(),
    providerUid: (row.providerUid || "").toString(),
    providerName: (row.providerName || "").toString(),
    providerRole: (row.providerRole || "").toString(),
    providerRating: toNumber(row.providerRating, 0),
    providerImagePath: (row.providerImagePath || "").toString(),
    providerType: normalizeProviderType(row.providerType),
    providerCompanyName: (row.providerCompanyName || "").toString(),
    providerMaxWorkers: normalizeProviderMaxWorkers(
      row.providerMaxWorkers,
      normalizeProviderType(row.providerType),
    ),
    providerBlockedDates: Array.isArray(row.providerBlockedDates) ? row.providerBlockedDates : [],
    categoryName: (row.categoryName || "").toString(),
    serviceName: (row.serviceName || "").toString(),
    addressLabel: (row.addressLabel || "").toString(),
    addressStreet: (row.addressStreet || "").toString(),
    addressCity: (row.addressCity || "").toString(),
    addressMapLink: (row.addressMapLink || "").toString(),
    preferredDate: row.preferredDate
      ? toIsoDate(row.preferredDate)
      : new Date().toISOString(),
    preferredTimeSlot: (row.preferredTimeSlot || "").toString(),
    homeType: (row.homeType || "").toString(),
    additionalService: (row.additionalService || "").toString(),
    finderNote: (row.finderNote || "").toString(),
    serviceFields:
      row.serviceFields && typeof row.serviceFields === "object"
        ? row.serviceFields
        : {},
    status,
    finderRating: toNumber(row.finderRating ?? row.rating, 0),
    finderComment: (row.finderComment || "").toString(),
    reviewedAt: toIsoDateOrNull(row.reviewedAt),
    statusTimeline: normalizeTimeline(
      row.statusTimeline,
      row.createdAt,
      row.updatedAt,
      status,
    ),
    createdAt: row.createdAt || null,
    updatedAt: row.updatedAt || null,
  };
}

class OrderService {
  static async createFinderOrder(uid, user, payload) {
    const docRef = db.collection(ORDER_COLLECTION).doc();
    const now = admin.firestore.FieldValue.serverTimestamp();

    const requestedProviderUid = (payload.providerUid || "").toString().trim();
    let providerData = {};
    let providerUid = "";
    if (requestedProviderUid) {
      const providerDoc = await db
        .collection("providers")
        .doc(requestedProviderUid)
        .get();
      if (providerDoc.exists) {
        providerUid = requestedProviderUid;
        providerData = providerDoc.data() || {};
      }
    }

    if (providerUid && providerUid === uid) {
      const error = new Error("You cannot book your own provider profile");
      error.status = 403;
      throw error;
    }

    const providerType = normalizeProviderType(
      providerData.providerType || payload.providerType,
    );
    const providerCompanyName =
      providerType === "company"
        ? (providerData.companyName || payload.providerCompanyName || "")
            .toString()
            .trim()
        : "";
    const providerMaxWorkers = normalizeProviderMaxWorkers(
      providerData.maxWorkers ?? payload.providerMaxWorkers,
      providerType,
    );
    const serviceDoc = await findServiceDocForOrder(
      payload.serviceId,
      payload.serviceName || payload.service,
      payload.categoryName || payload.category,
    );

    const row = {
      id: docRef.id,
      finderUid: uid,
      finderName:
        (payload.finderName || user?.name || "Finder User").toString().trim(),
      finderPhone: (payload.finderPhone || "").toString().trim(),
      providerUid,
      providerName: (payload.providerName || "").toString().trim(),
      providerRole: (payload.providerRole || "").toString().trim(),
      providerRating: toNumber(payload.providerRating, 0),
      providerImagePath: (payload.providerImagePath || "").toString().trim(),
      providerType,
      providerCompanyName,
      providerMaxWorkers,
      providerBlockedDates: providerData.blockedDates || [],
      categoryName: (payload.categoryName || payload.category || "")
        .toString()
        .trim(),
      serviceId: serviceDoc?.id || safeString(payload.serviceId),
      serviceName: (payload.serviceName || payload.service || "")
        .toString()
        .trim(),
      addressLabel: (payload.addressLabel || "").toString().trim(),
      addressStreet: (payload.addressStreet || "").toString().trim(),
      addressCity: (payload.addressCity || "").toString().trim(),
      addressMapLink: (payload.addressMapLink || "").toString().trim(),
      preferredDate: toIsoDate(payload.preferredDate || new Date().toISOString()),
      preferredTimeSlot: (payload.preferredTimeSlot || "").toString().trim(),
      homeType: (payload.homeType || "").toString().trim(),
      additionalService: (payload.additionalService || "").toString().trim(),
      finderNote: (payload.finderNote || "").toString().trim(),
      serviceFields:
        payload.serviceFields && typeof payload.serviceFields === "object"
          ? payload.serviceFields
          : {},
      finderRating: 0,
      finderComment: "",
      reviewedAt: null,
      status: "booked",
      statusTimeline: {
        bookedAt: now,
      },
      createdAt: now,
      updatedAt: now,
    };

    await docRef.set(row);
    const created = await docRef.get();
    if (providerUid) {
      await PushService.sendToUser({
        uid: providerUid,
        title: "New booking request",
        body: `${row.finderName || "A customer"} booked ${row.serviceName || "your service"}.`,
        data: {
          target: "orders",
          orderId: docRef.id,
          role: "provider",
        },
      }).catch(() => null);
    }
    return { data: mapOrderDoc(created) };
  }

  static async getFinderOrders(uid, pagination, filters = {}) {
    const normalized = normalizePagination(pagination);
    const statusFilters = parseStatusFilters(filters.status);

    const queryLimit = readWindow(pagination);
    const snap = await db
      .collection(ORDER_COLLECTION)
      .where("finderUid", "==", uid)
      .limit(queryLimit)
      .get();
    if (snap.empty) {
      const paged = paginateArray([], pagination);
      return { data: paged.items, pagination: paged.pagination };
    }
    const items = snap.docs
      .map(mapOrderDoc)
      .filter((row) =>
        statusFilters.length === 0
          ? true
          : statusFilters.includes(normalizeStatus(row.status)),
      )
      .sort((a, b) => createdAtMillis(b.createdAt) - createdAtMillis(a.createdAt))
      .slice(0, queryLimit);
    const paged = paginateArray(items, pagination);
    return { data: paged.items, pagination: paged.pagination };
  }

  static async getProviderOrders(uid, pagination, filters = {}) {
    const normalized = normalizePagination(pagination);
    const statusFilters = parseStatusFilters(filters.status);
    const queryLimit = readWindow(pagination);
    const [assignedSnap, incomingSnap] = await Promise.all([
      db
        .collection(ORDER_COLLECTION)
        .where("providerUid", "==", uid)
        .limit(queryLimit)
        .get(),
      db
        .collection(ORDER_COLLECTION)
        .where("status", "==", "booked")
        .limit(queryLimit)
        .get(),
    ]);

    const merged = new Map();
    for (const doc of assignedSnap.docs) {
      const row = mapOrderDoc(doc);
      merged.set(doc.id, row);
    }
    for (const doc of incomingSnap.docs) {
      const row = mapOrderDoc(doc);
      if (!row.providerUid) {
        merged.set(doc.id, row);
      }
    }
    const items = Array.from(merged.values())
      .filter((row) =>
        statusFilters.length === 0
          ? true
          : statusFilters.includes(normalizeStatus(row.status)),
      )
      .sort((a, b) => createdAtMillis(b.createdAt) - createdAtMillis(a.createdAt))
      .slice(0, queryLimit);
    const paged = paginateArray(items, pagination);
    return { data: paged.items, pagination: paged.pagination };
  }

  static async updateOrderStatus(uid, user, orderId, nextStatus, actorRole) {
    const orderRef = db.collection(ORDER_COLLECTION).doc(orderId);
    const orderSnap = await orderRef.get();
    if (!orderSnap.exists) {
      const error = new Error("order not found");
      error.status = 404;
      throw error;
    }
    const row = orderSnap.data() || {};
    const target = normalizeStatus(nextStatus);
    const role = roleName(actorRole);

    if (role === "finder") {
      if ((row.finderUid || "").toString() !== uid) {
        const error = new Error("forbidden");
        error.status = 403;
        throw error;
      }
      validateFinderTransition(normalizeStatus(row.status), target);
      await orderRef.update({
        status: target,
        [`statusTimeline.${timelineFieldForStatus(target)}`]:
          admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      const updated = await orderRef.get();
      const providerUid = safeString(row.providerUid);
      if (providerUid) {
        await PushService.sendToUser({
          uid: providerUid,
          title: orderStatusTitle(target, "provider"),
          body: orderStatusMessage(row, target, "provider"),
          data: {
            target: "orders",
            orderId,
            role: "provider",
            orderStatus: target,
          },
        }).catch(() => null);
      }
      return { data: mapOrderDoc(updated) };
    }

    if (role === "provider") {
      const [providerDoc, providerUserDoc] = await Promise.all([
        db.collection("providers").doc(uid).get(),
        db.collection("users").doc(uid).get(),
      ]);
      const canActAsProvider = providerDoc.exists || userHasRole(user, "provider");
      if (!canActAsProvider) {
        const error = new Error("provider not found");
        error.status = 403;
        throw error;
      }

      const currentStatus = normalizeStatus(row.status);
      validateProviderTransition(currentStatus, target);

      // Booking limit enforcement: check when provider accepts (booked → on_the_way)
      if (currentStatus === "booked" && target === "on_the_way") {
        const allowance = await SubscriptionService.checkBookingAllowance(uid);
        if (!allowance.allowed) {
          const error = new Error(
            `Booking limit reached (${allowance.used}/${allowance.limit}). Upgrade your subscription plan to accept more bookings.`,
          );
          error.status = 403;
          error.code = "BOOKING_LIMIT_REACHED";
          throw error;
        }
      }

      const currentProviderUid = (row.providerUid || "").toString();
      if (currentProviderUid && currentProviderUid !== uid) {
        const error = new Error("order already assigned to another provider");
        error.status = 403;
        throw error;
      }

      const providerRow = providerDoc.exists ? providerDoc.data() || {} : {};
      const userRow = providerUserDoc.exists ? providerUserDoc.data() || {} : {};
      const providerName = firstNonEmptyString(
        row.providerName,
        providerRow.name,
        userRow.name,
        user?.name,
        "Provider",
      );
      const providerRole = firstNonEmptyString(
        row.providerRole,
        providerRow.serviceName,
        row.categoryName,
        "Service Provider",
      );
      const providerImagePath = firstNonEmptyString(
        row.providerImagePath,
        providerRow.PhotoUrl,
        userRow.photoUrl,
        user?.picture,
      );

      const updatePayload = {
        status: target,
        providerUid: uid,
        providerName,
        providerRole,
        providerImagePath,
        providerRating: providerRatingFromProfile(row, providerRow),
        providerType: normalizeProviderType(providerRow.providerType),
        providerCompanyName:
          normalizeProviderType(providerRow.providerType) === "company"
            ? (providerRow.companyName || "").toString().trim()
            : "",
        providerMaxWorkers: normalizeProviderMaxWorkers(
          providerRow.maxWorkers,
          normalizeProviderType(providerRow.providerType),
        ),
        [`statusTimeline.${timelineFieldForStatus(target)}`]:
          admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      await orderRef.update(updatePayload);

      // Increment booking count after successful accept
      if (currentStatus === "booked" && target === "on_the_way") {
        await SubscriptionService.incrementBookingCount(uid);
      }

      const updated = await orderRef.get();
      const finderUid = safeString(row.finderUid);
      if (finderUid) {
        await PushService.sendToUser({
          uid: finderUid,
          title: orderStatusTitle(target, "finder"),
          body: orderStatusMessage(row, target, "finder", providerName),
          data: {
            target: "orders",
            orderId,
            role: "finder",
            orderStatus: target,
          },
        }).catch(() => null);
      }
      return { data: mapOrderDoc(updated) };
    }

    const error = new Error("actorRole must be finder or provider");
    error.status = 400;
    throw error;
  }

  static async submitFinderReview(uid, user, orderId, payload = {}) {
    const rating = normalizeReviewRating(payload.rating);
    if (rating < 1 || rating > 5) {
      const error = new Error("rating must be between 1 and 5");
      error.status = 400;
      throw error;
    }
    const comment = normalizeReviewComment(payload.comment);
    const orderRef = db.collection(ORDER_COLLECTION).doc(orderId);
    const now = admin.firestore.FieldValue.serverTimestamp();

    await db.runTransaction(async (tx) => {
      const orderSnap = await tx.get(orderRef);
      if (!orderSnap.exists) {
        const error = new Error("order not found");
        error.status = 404;
        throw error;
      }
      const row = orderSnap.data() || {};
      if ((row.finderUid || "").toString() !== uid) {
        const error = new Error("forbidden");
        error.status = 403;
        throw error;
      }
      if (normalizeStatus(row.status) !== "completed") {
        const error = new Error("order must be completed before review");
        error.status = 400;
        throw error;
      }
      if (toNumber(row.finderRating ?? row.rating, 0) > 0 || row.reviewedAt) {
        const error = new Error("order already reviewed");
        error.status = 400;
        throw error;
      }
      const providerUid = (row.providerUid || "").toString().trim();
      if (!providerUid) {
        const error = new Error("provider is not assigned");
        error.status = 400;
        throw error;
      }

      const providerRef = db.collection("providers").doc(providerUid);
      const providerDoc = await tx.get(providerRef);
      const providerRow = providerDoc.exists ? providerDoc.data() : {};
      let serviceDoc = null;
      const normalizedServiceId = safeString(row.serviceId);
      if (normalizedServiceId) {
        const explicitServiceRef = db.collection("services").doc(normalizedServiceId);
        const explicitServiceDoc = await tx.get(explicitServiceRef);
        if (explicitServiceDoc.exists) {
          serviceDoc = explicitServiceDoc;
        }
      }
      if (!serviceDoc && safeString(row.serviceName)) {
        const serviceQuery = db
          .collection("services")
          .where("name", "==", safeString(row.serviceName))
          .limit(10);
        const serviceSnap = await tx.get(serviceQuery);
        if (!serviceSnap.empty) {
          const categoryKey = serviceKey(row.categoryName);
          serviceDoc = serviceSnap.docs.find((doc) => {
            const serviceRow = doc.data() || {};
            return serviceKey(serviceRow.categoryName || serviceRow.categoryId) === categoryKey;
          }) || serviceSnap.docs[0];
        }
      }

      tx.set(
        orderRef,
        {
          finderRating: rating,
          finderComment: comment,
          reviewedAt: now,
          updatedAt: now,
        },
        { merge: true },
      );
      tx.set(
        providerRef,
        {
          ratingCount: admin.firestore.FieldValue.increment(1),
          ratingSum: admin.firestore.FieldValue.increment(rating),
          updatedAt: now,
        },
        { merge: true },
      );
      if (serviceDoc) {
        const serviceRow = serviceDoc.data() || {};
        const nextServiceRatingCount = Number(serviceRow.ratingCount || 0) + 1;
        const nextServiceRatingSum = Number(serviceRow.ratingSum || 0) + rating;
        const nextServiceAverageRating = Number(
          (nextServiceRatingSum / nextServiceRatingCount).toFixed(1),
        );
        tx.set(
          serviceDoc.ref,
          {
            ratingCount: admin.firestore.FieldValue.increment(1),
            ratingSum: admin.firestore.FieldValue.increment(rating),
            rating: nextServiceAverageRating,
            updatedAt: now,
          },
          { merge: true },
        );
        tx.set(
          orderRef,
          {
            serviceId: serviceDoc.id,
          },
          { merge: true },
        );
      }

      const postsSnap = await db
        .collection("providerPosts")
        .where("providerUid", "==", providerUid)
        .where("status", "==", "open")
        .get();

      const nextRatingCount = Number(providerRow.ratingCount || 0) + 1;
      const nextRatingSum = Number(providerRow.ratingSum || 0) + rating;
      const nextAverageRating = Number((nextRatingSum / nextRatingCount).toFixed(1));

      postsSnap.docs.forEach((postDoc) => {
        tx.set(
          postDoc.ref,
          {
            providerRatingCount: nextRatingCount,
            providerRatingSum: nextRatingSum,
            rating: nextAverageRating,
            updatedAt: now,
          },
          { merge: true },
        );
      });
    });

    const updated = await orderRef.get();
    ServiceService.invalidateActiveServicesCache();
    return { data: mapOrderDoc(updated) };
  }

  static async getProviderReviews(providerUid, options = {}) {
    const normalizedProviderUid = (providerUid || "").toString().trim();
    if (!normalizedProviderUid) {
      const error = new Error("provider uid is required");
      error.status = 400;
      throw error;
    }
    const parsedLimit = Number.parseInt((options.limit ?? "20").toString(), 10);
    const limit = Math.max(1, Math.min(100, Number.isFinite(parsedLimit) ? parsedLimit : 20));

    const [providerSnap, orderSnap] = await Promise.all([
      db.collection("providers").doc(normalizedProviderUid).get(),
      db
        .collection(ORDER_COLLECTION)
        .where("providerUid", "==", normalizedProviderUid)
        .limit(MAX_PROVIDER_REVIEW_SCAN)
        .get(),
    ]);
    if (!providerSnap.exists) {
      const error = new Error("provider not found");
      error.status = 404;
      throw error;
    }
    const providerRow = providerSnap.data() || {};

    const reviews = [];
    let completedJobsComputed = 0;
    let reviewSumComputed = 0;
    for (const doc of orderSnap.docs) {
      const row = doc.data() || {};
      if (normalizeStatus(row.status) === "completed") {
        completedJobsComputed += 1;
      }
      const reviewRating = toNumber(row.finderRating, 0);
      if (reviewRating <= 0) continue;
      reviewSumComputed += reviewRating;
      const reviewerName = (row.finderName || "Customer").toString().trim() || "Customer";
      const reviewedAt = toIsoDateOrNull(row.reviewedAt) || toIsoDateOrNull(row.updatedAt);
      reviews.push({
        orderId: doc.id,
        reviewerUid: (row.finderUid || "").toString(),
        reviewerName,
        reviewerInitials: initialsFromName(reviewerName),
        rating: Number(reviewRating.toFixed(1)),
        comment: (row.finderComment || "").toString().trim(),
        reviewedAt,
      });
    }

    reviews.sort((a, b) => createdAtMillis(b.reviewedAt) - createdAtMillis(a.reviewedAt));
    const limited = reviews.slice(0, limit);
    const reviewerUidSet = new Set(
      limited
        .map((item) => (item.reviewerUid || "").toString().trim())
        .filter((uid) => uid.length > 0),
    );
    const reviewerPhotoByUid = new Map();
    if (reviewerUidSet.size > 0) {
      const reviewerDocs = await Promise.all(
        Array.from(reviewerUidSet).map((reviewerUid) =>
          db.collection("users").doc(reviewerUid).get(),
        ),
      );
      reviewerDocs.forEach((doc) => {
        if (!doc.exists) return;
        const row = doc.data() || {};
        const photoUrl = (row.photoUrl || "").toString().trim();
        if (!photoUrl) return;
        reviewerPhotoByUid.set(doc.id, photoUrl);
      });
    }
    const reviewsWithPhoto = limited.map((item) => ({
      ...item,
      reviewerPhotoUrl: reviewerPhotoByUid.get((item.reviewerUid || "").toString().trim()) || "",
    }));

    const profileRatingCount = toNumber(providerRow.ratingCount, 0);
    const profileRatingSum = toNumber(providerRow.ratingSum, 0);
    const totalReviews = profileRatingCount > 0 ? profileRatingCount : reviews.length;
    const ratingSum = totalReviews > 0
      ? profileRatingCount > 0
        ? profileRatingSum
        : reviewSumComputed
      : 0;
    const averageRating =
      totalReviews > 0 ? Number((ratingSum / totalReviews).toFixed(2)) : 0;
    const completedJobs = Math.max(
      toNumber(providerRow.completedOrder, 0),
      completedJobsComputed,
    );

    return {
      data: {
        providerUid: normalizedProviderUid,
        averageRating,
        totalReviews,
        completedJobs,
        reviews: reviewsWithPhoto,
      },
    };
  }
}

export default OrderService;
