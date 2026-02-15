import admin from "firebase-admin";
import { db } from "../config/firebase.js";

const ORDER_COLLECTION = "orders";

const ALLOWED_STATUSES = [
  "booked",
  "on_the_way",
  "started",
  "completed",
  "cancelled",
  "declined",
];

function toNumber(value, fallback = 0) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
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

function roleName(role) {
  const raw = (role || "").toString().trim().toLowerCase();
  if (raw === "providers") return "provider";
  if (raw === "finders") return "finder";
  return raw;
}

function rowFromDoc(doc) {
  const row = doc.data() || {};
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
    paymentMethod: (row.paymentMethod || "").toString(),
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
    status: normalizeStatus(row.status),
    createdAt: row.createdAt || null,
    updatedAt: row.updatedAt || null,
  };
}

class OrderService {
  static async createFinderOrder(uid, user, payload) {
    const docRef = db.collection(ORDER_COLLECTION).doc();
    const now = admin.firestore.FieldValue.serverTimestamp();
    const requestedProviderUid = (payload.providerUid || "").toString().trim();
    let providerUid = "";
    if (requestedProviderUid) {
      const providerDoc = await db
        .collection("providers")
        .doc(requestedProviderUid)
        .get();
      if (providerDoc.exists) {
        providerUid = requestedProviderUid;
      }
    }

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
      hours: toNumber(payload.hours, 1),
      workers: toNumber(payload.workers, 1),
      homeType: (payload.homeType || "").toString().trim(),
      paymentMethod: (payload.paymentMethod || "").toString().trim(),
      additionalService: (payload.additionalService || "").toString().trim(),
      finderNote: (payload.finderNote || "").toString().trim(),
      promoCode: (payload.promoCode || "").toString().trim(),
      serviceFields:
        payload.serviceFields && typeof payload.serviceFields === "object"
          ? payload.serviceFields
          : {},
      subtotal: toNumber(payload.subtotal, 0),
      processingFee: toNumber(payload.processingFee, 0),
      discount: toNumber(payload.discount, 0),
      total: toNumber(payload.total, 0),
      status: "booked",
      createdAt: now,
      updatedAt: now,
    };

    await docRef.set(row);
    const created = await docRef.get();
    return { data: rowFromDoc(created) };
  }

  static async getFinderOrders(uid) {
    const snap = await db
      .collection(ORDER_COLLECTION)
      .where("finderUid", "==", uid)
      .get();
    if (snap.empty) return { data: [] };
    const items = snap.docs
      .map(rowFromDoc)
      .sort((a, b) => createdAtMillis(b.createdAt) - createdAtMillis(a.createdAt))
      .slice(0, 120);
    return { data: items };
  }

  static async getProviderOrders(uid) {
    const [assignedSnap, incomingSnap] = await Promise.all([
      db
        .collection(ORDER_COLLECTION)
        .where("providerUid", "==", uid)
        .get(),
      db
        .collection(ORDER_COLLECTION)
        .where("status", "==", "booked")
        .get(),
    ]);

    const merged = new Map();
    for (const doc of assignedSnap.docs) {
      merged.set(doc.id, rowFromDoc(doc));
    }
    for (const doc of incomingSnap.docs) {
      const row = rowFromDoc(doc);
      if (!row.providerUid) {
        merged.set(doc.id, row);
      }
    }
    const items = Array.from(merged.values())
      .sort((a, b) => createdAtMillis(b.createdAt) - createdAtMillis(a.createdAt))
      .slice(0, 120);
    return { data: items };
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
      if (!["cancelled", "completed"].includes(target)) {
        const error = new Error("finder can only set cancelled/completed");
        error.status = 400;
        throw error;
      }
      await orderRef.update({
        status: target,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      const updated = await orderRef.get();
      return { data: rowFromDoc(updated) };
    }

    if (role === "provider") {
      const providerDoc = await db.collection("providers").doc(uid).get();
      if (!providerDoc.exists) {
        const error = new Error("provider not found");
        error.status = 403;
        throw error;
      }

      const currentProviderUid = (row.providerUid || "").toString();
      if (currentProviderUid && currentProviderUid !== uid) {
        const error = new Error("order already assigned to another provider");
        error.status = 403;
        throw error;
      }
      if (
        !["on_the_way", "started", "completed", "declined", "booked"].includes(
          target,
        )
      ) {
        const error = new Error("invalid provider status");
        error.status = 400;
        throw error;
      }

      const updatePayload = {
        status: target,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      if (target === "on_the_way" || target === "started" || target === "completed") {
        updatePayload.providerUid = uid;
        updatePayload.providerName = (row.providerName || user?.name || "Provider")
          .toString()
          .trim();
      }
      await orderRef.update(updatePayload);
      const updated = await orderRef.get();
      return { data: rowFromDoc(updated) };
    }

    const error = new Error("actorRole must be finder or provider");
    error.status = 400;
    throw error;
  }
}

export default OrderService;
