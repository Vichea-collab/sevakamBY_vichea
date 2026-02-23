import admin from "firebase-admin";
import { db } from "../config/firebase.js";
import { paginateArray } from "../utils/pagination.util.js";

const ORDER_COLLECTION = "orders";
const PROMO_COLLECTION = "promoCodes";
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
const ALLOWED_PAYMENT_METHODS = ["credit_card", "cash", "khqr"];
const ALLOWED_PROMO_DISCOUNT_TYPES = ["percent", "fixed"];

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

function normalizePaymentMethod(value) {
  const method = (value || "").toString().trim().toLowerCase();
  if (method === "bank_account" || method === "bank account") {
    return "credit_card";
  }
  if (!ALLOWED_PAYMENT_METHODS.includes(method)) return "credit_card";
  return method;
}

function paymentStatusForMethod(method) {
  if (method === "khqr") return "pending";
  return "paid";
}

function isPaymentConfirmedForProvider(row) {
  const method = normalizePaymentMethod(row.paymentMethod);
  if (method !== "khqr") return true;
  return (row.paymentStatus || "").toString().trim().toLowerCase() === "paid";
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

function normalizePromoCode(value) {
  return (value || "").toString().trim().toUpperCase();
}

function promoTimeState(promo = {}, nowMillis = Date.now()) {
  if (promo.active === false) return "inactive";
  const startMillis = createdAtMillis(promo.startAt);
  const endMillis = createdAtMillis(promo.endAt);
  if (startMillis > 0 && nowMillis < startMillis) return "scheduled";
  if (endMillis > 0 && nowMillis > endMillis) return "expired";
  return "active";
}

function normalizePromoDiscountType(value) {
  const normalized = (value || "").toString().trim().toLowerCase();
  if (ALLOWED_PROMO_DISCOUNT_TYPES.includes(normalized)) return normalized;
  return "percent";
}

function clampDiscount(value, subtotal) {
  if (!Number.isFinite(value)) return 0;
  return Math.max(0, Math.min(subtotal, Number(value)));
}

export function mapOrderDoc(doc) {
  const row = doc.data() || {};
  const status = normalizeStatus(row.status);
  const paymentMethod = normalizePaymentMethod(row.paymentMethod);
  const paymentStatus = (row.paymentStatus || "").toString().trim().toLowerCase();
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
    hours: toNumber(row.hours, 1),
    workers: toNumber(row.workers, 1),
    homeType: (row.homeType || "").toString(),
    paymentMethod,
    paymentStatus: paymentStatus || paymentStatusForMethod(paymentMethod),
    paymentMerchantRef: (row.paymentMerchantRef || "").toString(),
    paymentTransactionId: (row.paymentTransactionId || "").toString(),
    khqrPayload: (row.khqrPayload || "").toString(),
    khqrImageUrl: (row.khqrImageUrl || "").toString(),
    paidAt: toIsoDateOrNull(row.paidAt),
    additionalService: (row.additionalService || "").toString(),
    finderNote: (row.finderNote || "").toString(),
    promoCode: (row.promoCode || "").toString(),
    serviceFields:
      row.serviceFields && typeof row.serviceFields === "object"
        ? row.serviceFields
        : {},
    subtotal: toNumber(row.subtotal, 0),
    processingFee: toNumber(row.processingFee, 0),
    discount: toNumber(row.discount, 0),
    total: toNumber(row.total, 0),
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
  static async _resolvePromo(promoCode, role = "finder") {
    const code = normalizePromoCode(promoCode);
    if (!code) {
      return {
        code: "",
        applied: false,
        message: "",
        discountType: "",
        discountValue: 0,
        minSubtotal: 0,
        maxDiscount: 0,
      };
    }

    const snap = await db
      .collection(PROMO_COLLECTION)
      .where("code", "==", code)
      .limit(1)
      .get();
    if (snap.empty) {
      return {
        code,
        applied: false,
        message: "Promo code not found.",
        discountType: "",
        discountValue: 0,
        minSubtotal: 0,
        maxDiscount: 0,
      };
    }

    const doc = snap.docs[0];
    const row = doc.data() || {};
    const roles = normalizeRoleList(row.targetRoles);
    if (!roles.includes(role)) {
      return {
        id: doc.id,
        code,
        applied: false,
        message: "Promo code is not available for this account role.",
        discountType: normalizePromoDiscountType(row.discountType),
        discountValue: toNumber(row.discountValue, 0),
        minSubtotal: toNumber(row.minSubtotal, 0),
        maxDiscount: toNumber(row.maxDiscount, 0),
      };
    }

    const timeState = promoTimeState(row);
    if (timeState !== "active") {
      const message =
        timeState === "scheduled"
          ? "Promo code is not active yet."
          : timeState === "expired"
            ? "Promo code has expired."
            : "Promo code is inactive.";
      return {
        id: doc.id,
        code,
        applied: false,
        message,
        discountType: normalizePromoDiscountType(row.discountType),
        discountValue: toNumber(row.discountValue, 0),
        minSubtotal: toNumber(row.minSubtotal, 0),
        maxDiscount: toNumber(row.maxDiscount, 0),
      };
    }

    const usageLimit = toNumber(row.usageLimit, 0);
    const usedCount = toNumber(row.usedCount, 0);
    if (usageLimit > 0 && usedCount >= usageLimit) {
      return {
        id: doc.id,
        code,
        applied: false,
        message: "Promo code usage limit has been reached.",
        discountType: normalizePromoDiscountType(row.discountType),
        discountValue: toNumber(row.discountValue, 0),
        minSubtotal: toNumber(row.minSubtotal, 0),
        maxDiscount: toNumber(row.maxDiscount, 0),
      };
    }

    return {
      id: doc.id,
      code,
      title: (row.title || "").toString().trim(),
      message: "",
      applied: true,
      discountType: normalizePromoDiscountType(row.discountType),
      discountValue: toNumber(row.discountValue, 0),
      minSubtotal: toNumber(row.minSubtotal, 0),
      maxDiscount: toNumber(row.maxDiscount, 0),
    };
  }

  static async _buildPricingQuote(payload = {}, role = "finder") {
    const hours = Math.max(1, Math.floor(toNumber(payload.hours, 1)));
    const requestedWorkers = Math.max(1, Math.floor(toNumber(payload.workers, 1)));
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

    const requestedServices = normalizeServiceList(payload);
    if (requestedProviderUid && requestedServices.length > 0) {
      const providerPostsSnap = await db
        .collection("providerPosts")
        .where("providerUid", "==", requestedProviderUid)
        .limit(200)
        .get();
      const offeredServiceKeys = new Set();
      providerPostsSnap.docs.forEach((doc) => {
        const row = doc.data() || {};
        const status = (row.status || "").toString().trim().toLowerCase();
        if (status && status !== "open") return;
        normalizeServiceList({
          serviceName: row.service,
          service: row.service,
          services: row.services,
        }).forEach((item) => {
          const key = serviceKey(item);
          if (key) offeredServiceKeys.add(key);
        });
      });

      if (offeredServiceKeys.size == 0) {
        const error = new Error("provider has no active service posts");
        error.status = 400;
        throw error;
      }

      const unsupported = requestedServices.find((item) => {
        const key = serviceKey(item);
        return key && !offeredServiceKeys.has(key);
      });
      if (unsupported) {
        const error = new Error(`provider does not offer ${unsupported}`);
        error.status = 400;
        throw error;
      }
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
    const workers = normalizeRequestedWorkers(
      requestedWorkers,
      providerType,
      providerMaxWorkers,
    );

    const providerRate = toNumber(providerData.ratePerHour, 0);
    const payloadRate = toNumber(payload.unitPricePerHour, 0);
    const unitPricePerHour = providerRate > 0
      ? providerRate
      : payloadRate > 0
        ? payloadRate
        : 11;
    const subtotal = Number((unitPricePerHour * hours * workers).toFixed(2));
    const processingFee = 0;

    const promo = await this._resolvePromo(payload.promoCode, role);
    let appliedPromo = { ...promo };
    let discount = 0;
    if (promo.code && promo.applied !== true) {
      appliedPromo = { ...promo, applied: false };
    }
    if (promo.applied === true) {
      if (promo.minSubtotal > 0 && subtotal < promo.minSubtotal) {
        appliedPromo = {
          ...promo,
          applied: false,
          message: `Minimum subtotal is \$${promo.minSubtotal.toFixed(0)} for this code.`,
        };
      } else {
        if (promo.discountType === "fixed") {
          discount = promo.discountValue;
        } else {
          discount = (subtotal * promo.discountValue) / 100;
        }
        if (promo.maxDiscount > 0) {
          discount = Math.min(discount, promo.maxDiscount);
        }
      }
    }

    discount = clampDiscount(Number(discount.toFixed(2)), subtotal);
    const promoApplied = discount > 0 && appliedPromo.applied === true;
    const promoMessage = promoApplied
      ? `Promo code ${appliedPromo.code} applied.`
      : (appliedPromo.message || "").toString();
    const total = Number(Math.max(0, subtotal + processingFee - discount).toFixed(2));

    return {
      providerUid,
      providerType,
      providerCompanyName,
      providerMaxWorkers,
      hours,
      workers,
      unitPricePerHour,
      subtotal,
      processingFee,
      discount,
      total,
      promo: {
        ...appliedPromo,
        applied: promoApplied,
        message: promoMessage,
      },
    };
  }

  static async quoteFinderOrder(uid, user, payload = {}) {
    const quote = await this._buildPricingQuote(payload, "finder");
    return {
      data: {
        providerUid: quote.providerUid,
        providerType: quote.providerType,
        providerCompanyName: quote.providerCompanyName,
        providerMaxWorkers: quote.providerMaxWorkers,
        hours: quote.hours,
        workers: quote.workers,
        unitPricePerHour: quote.unitPricePerHour,
        subtotal: quote.subtotal,
        processingFee: quote.processingFee,
        discount: quote.discount,
        total: quote.total,
        promo: quote.promo,
      },
    };
  }

  static async createFinderOrder(uid, user, payload) {
    const docRef = db.collection(ORDER_COLLECTION).doc();
    const now = admin.firestore.FieldValue.serverTimestamp();
    const paymentMethod = normalizePaymentMethod(payload.paymentMethod);
    const paymentStatus = paymentStatusForMethod(paymentMethod);
    const quote = await this._buildPricingQuote(payload, "finder");
    if ((payload.promoCode || "").toString().trim() && quote.promo.applied !== true) {
      const error = new Error(
        (quote.promo.message || "").toString().trim() || "Promo code is invalid.",
      );
      error.status = 400;
      throw error;
    }

    const row = {
      id: docRef.id,
      finderUid: uid,
      finderName:
        (payload.finderName || user?.name || "Finder User").toString().trim(),
      finderPhone: (payload.finderPhone || "").toString().trim(),
      providerUid: quote.providerUid,
      providerName: (payload.providerName || "").toString().trim(),
      providerRole: (payload.providerRole || "").toString().trim(),
      providerRating: toNumber(payload.providerRating, 0),
      providerImagePath: (payload.providerImagePath || "").toString().trim(),
      providerType: quote.providerType,
      providerCompanyName: quote.providerCompanyName,
      providerMaxWorkers: quote.providerMaxWorkers,
      categoryName: (payload.categoryName || payload.category || "")
        .toString()
        .trim(),
      serviceName: (payload.serviceName || payload.service || "")
        .toString()
        .trim(),
      addressLabel: (payload.addressLabel || "").toString().trim(),
      addressStreet: (payload.addressStreet || "").toString().trim(),
      addressCity: (payload.addressCity || "").toString().trim(),
      addressMapLink: (payload.addressMapLink || "").toString().trim(),
      preferredDate: toIsoDate(payload.preferredDate || new Date().toISOString()),
      preferredTimeSlot: (payload.preferredTimeSlot || "").toString().trim(),
      hours: quote.hours,
      workers: quote.workers,
      homeType: (payload.homeType || "").toString().trim(),
      paymentMethod,
      paymentStatus,
      additionalService: (payload.additionalService || "").toString().trim(),
      finderNote: (payload.finderNote || "").toString().trim(),
      promoCode: quote.promo.applied ? quote.promo.code : "",
      serviceFields:
        payload.serviceFields && typeof payload.serviceFields === "object"
          ? payload.serviceFields
          : {},
      subtotal: quote.subtotal,
      processingFee: quote.processingFee,
      discount: quote.discount,
      total: quote.total,
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

    const batch = db.batch();
    batch.set(docRef, row);
    if (quote.promo.applied && quote.promo.id) {
      const promoRef = db.collection(PROMO_COLLECTION).doc(quote.promo.id);
      batch.set(
        promoRef,
        {
          usedCount: admin.firestore.FieldValue.increment(1),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }
    await batch.commit();
    const created = await docRef.get();
    return { data: mapOrderDoc(created) };
  }

  static async getFinderOrders(uid, pagination) {
    const normalized = normalizePagination(pagination);
    const canUseCursor = normalized.page === 1 || Boolean(normalized.cursor);
    if (canUseCursor) {
      let queryRef = db
        .collection(ORDER_COLLECTION)
        .where("finderUid", "==", uid)
        .orderBy(admin.firestore.FieldPath.documentId());
      queryRef = await applyCollectionCursor(queryRef, ORDER_COLLECTION, normalized.cursor);
      const fetchLimit = normalized.cursor ? normalized.limit + 1 : normalized.limit;
      const snap = await queryRef.limit(fetchLimit).get();
      const docs = normalized.cursor && snap.docs.length > normalized.limit
        ? snap.docs.slice(0, normalized.limit)
        : snap.docs;
      const hasNextPage = normalized.cursor
        ? snap.docs.length > normalized.limit
        : snap.docs.length >= normalized.limit;
      const items = docs
        .map(mapOrderDoc)
        .sort((a, b) => createdAtMillis(b.createdAt) - createdAtMillis(a.createdAt));
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
      .sort((a, b) => createdAtMillis(b.createdAt) - createdAtMillis(a.createdAt))
      .slice(0, queryLimit);
    const paged = paginateArray(items, pagination);
    return { data: paged.items, pagination: paged.pagination };
  }

  static async getProviderOrders(uid, pagination) {
    const normalized = normalizePagination(pagination);
    const canUseCursor = normalized.page === 1 || Boolean(normalized.cursor);
    if (canUseCursor) {
      let assignedQuery = db
        .collection(ORDER_COLLECTION)
        .where("providerUid", "==", uid)
        .orderBy(admin.firestore.FieldPath.documentId());
      let incomingQuery = db
        .collection(ORDER_COLLECTION)
        .where("status", "==", "booked")
        .orderBy(admin.firestore.FieldPath.documentId());
      assignedQuery = await applyCollectionCursor(assignedQuery, ORDER_COLLECTION, normalized.cursor);
      incomingQuery = await applyCollectionCursor(incomingQuery, ORDER_COLLECTION, normalized.cursor);
      const fetchLimit = normalized.cursor ? normalized.limit + 1 : normalized.limit;
      const [assignedSnap, incomingSnap] = await Promise.all([
        assignedQuery.limit(fetchLimit).get(),
        incomingQuery.limit(fetchLimit).get(),
      ]);

      const merged = new Map();
      for (const doc of assignedSnap.docs) {
        const row = mapOrderDoc(doc);
        if (!isPaymentConfirmedForProvider(row)) continue;
        merged.set(doc.id, row);
      }
      for (const doc of incomingSnap.docs) {
        const row = mapOrderDoc(doc);
        if (!isPaymentConfirmedForProvider(row)) continue;
        if (!row.providerUid) {
          merged.set(doc.id, row);
        }
      }
      const mergedItems = Array.from(merged.values()).sort(
        (a, b) => createdAtMillis(b.createdAt) - createdAtMillis(a.createdAt),
      );
      const hasNextPage = mergedItems.length >= normalized.limit;
      const items = mergedItems.slice(0, normalized.limit);
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
      if (!isPaymentConfirmedForProvider(row)) continue;
      merged.set(doc.id, row);
    }
    for (const doc of incomingSnap.docs) {
      const row = mapOrderDoc(doc);
      if (!isPaymentConfirmedForProvider(row)) continue;
      if (!row.providerUid) {
        merged.set(doc.id, row);
      }
    }
    const items = Array.from(merged.values())
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
      return { data: mapOrderDoc(updated) };
    }

    if (role === "provider") {
      if (!isPaymentConfirmedForProvider(row)) {
        const error = new Error("payment is not confirmed yet");
        error.status = 400;
        throw error;
      }
      const [providerDoc, providerUserDoc] = await Promise.all([
        db.collection("providers").doc(uid).get(),
        db.collection("users").doc(uid).get(),
      ]);
      if (!providerDoc.exists) {
        const error = new Error("provider not found");
        error.status = 403;
        throw error;
      }

      const currentStatus = normalizeStatus(row.status);
      validateProviderTransition(currentStatus, target);

      const currentProviderUid = (row.providerUid || "").toString();
      if (currentProviderUid && currentProviderUid !== uid) {
        const error = new Error("order already assigned to another provider");
        error.status = 403;
        throw error;
      }

      const providerRow = providerDoc.data() || {};
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
      const updated = await orderRef.get();
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
    });

    const updated = await orderRef.get();
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
        reviews: limited,
      },
    };
  }
}

export default OrderService;
