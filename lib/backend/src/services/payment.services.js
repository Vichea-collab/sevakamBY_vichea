import admin from "firebase-admin";
import { db } from "../config/firebase.js";
import { env } from "../config/env.js";
import { mapOrderDoc } from "./order.services.js";
import {
  createBakongKhqrCharge,
  deepFind,
  extractPaymentStatus,
  extractTransactionId,
  getBakongWebhookSecret,
  isPaidText,
  verifyBakongKhqrCharge,
} from "./bakong.services.js";

const ORDER_COLLECTION = "orders";

function normalizePaymentMethod(value) {
  const method = (value || "").toString().trim().toLowerCase();
  if (method === "bank_account" || method === "bank account") {
    return "credit_card";
  }
  if (["credit_card", "cash", "khqr"].includes(method)) {
    return method;
  }
  return "credit_card";
}

function toNumber(value, fallback = 0) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}


class PaymentService {
  static async createKhqrSession(uid, payload) {
    const orderId = (payload.orderId || "").toString().trim();
    if (!orderId) {
      const error = new Error("orderId is required");
      error.status = 400;
      throw error;
    }

    const orderRef = db.collection(ORDER_COLLECTION).doc(orderId);
    const orderSnap = await orderRef.get();
    if (!orderSnap.exists) {
      const error = new Error("order not found");
      error.status = 404;
      throw error;
    }

    const row = orderSnap.data() || {};
    if ((row.finderUid || "").toString().trim() !== uid) {
      const error = new Error("forbidden");
      error.status = 403;
      throw error;
    }

    const paymentMethod = normalizePaymentMethod(row.paymentMethod);
    if (paymentMethod !== "khqr") {
      const error = new Error("order payment method is not khqr");
      error.status = 400;
      throw error;
    }

    const amount = toNumber(row.total, 0);
    if (amount <= 0) {
      const error = new Error("invalid order amount for khqr");
      error.status = 400;
      throw error;
    }

    const merchantReference =
      (row.paymentMerchantRef || "").toString().trim() ||
      `KHQR_${orderId}_${Date.now()}`;

    const paymentSession = await createBakongKhqrCharge({
      referenceId: orderId,
      amount,
      merchantReference,
      purpose: `Order ${orderId}`,
    });

    await orderRef.update({
      paymentMethod: "khqr",
      paymentStatus: "pending",
      paymentMerchantRef: paymentSession.merchantReference,
      paymentTransactionId: paymentSession.transactionId,
      paymentKhqrMd5: paymentSession.khqrMd5,
      khqrPayload: paymentSession.qrPayload,
      khqrImageUrl: paymentSession.qrImageUrl,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      data: {
        orderId,
        ...paymentSession,
      },
    };
  }

  static async verifyKhqrPayment(uid, payload) {
    const orderId = (payload.orderId || "").toString().trim();
    if (!orderId) {
      const error = new Error("orderId is required");
      error.status = 400;
      throw error;
    }
    const inputTransactionId = (payload.transactionId || "").toString().trim();

    const orderRef = db.collection(ORDER_COLLECTION).doc(orderId);
    const orderSnap = await orderRef.get();
    if (!orderSnap.exists) {
      const error = new Error("order not found");
      error.status = 404;
      throw error;
    }
    const row = orderSnap.data() || {};
    if ((row.finderUid || "").toString().trim() !== uid) {
      const error = new Error("forbidden");
      error.status = 403;
      throw error;
    }

    const paymentMethod = normalizePaymentMethod(row.paymentMethod);
    if (paymentMethod !== "khqr") {
      const error = new Error("order payment method is not khqr");
      error.status = 400;
      throw error;
    }

    const currentStatus = (row.paymentStatus || "").toString().trim().toLowerCase();
    if (currentStatus === "paid") {
      return {
        data: {
          paid: true,
          paymentStatus: "paid",
          order: mapOrderDoc(orderSnap),
        },
      };
    }

    const merchantReference = (row.paymentMerchantRef || "").toString().trim();
    const transactionId =
      inputTransactionId || (row.paymentTransactionId || "").toString().trim();

    if (!merchantReference) {
      const error = new Error("khqr session is not created for this order");
      error.status = 400;
      throw error;
    }

    const verification = await verifyBakongKhqrCharge({
      referenceId: orderId,
      amount: row.total,
      currency: env.BAKONG_CURRENCY,
      merchantReference,
      transactionId,
      qrPayload: row.khqrPayload,
      khqrMd5: row.paymentKhqrMd5,
    });

    if (!verification.paid) {
      return {
        data: {
          paid: false,
          paymentStatus: "pending",
          status: verification.status,
          order: mapOrderDoc(orderSnap),
        },
      };
    }

    await orderRef.update({
      paymentStatus: "paid",
      paymentTransactionId: verification.transactionId,
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    const updated = await orderRef.get();
    return {
      data: {
        paid: true,
        paymentStatus: "paid",
        status: "paid",
        order: mapOrderDoc(updated),
      },
    };
  }

  static async webhookKhqr(payload, headers = {}) {
    const secret = getBakongWebhookSecret();
    const incomingSecret = (headers["x-khqr-webhook-secret"] || "")
      .toString()
      .trim();
    if (secret && incomingSecret !== secret) {
      const error = new Error("invalid webhook secret");
      error.status = 403;
      throw error;
    }

    const merchantReference =
      (payload?.merchantReference ||
        payload?.merchantRef ||
        deepFind(payload, "merchantReference") ||
        "")
        .toString()
        .trim();
    const explicitOrderId =
      (payload?.orderId || deepFind(payload, "orderId") || "")
        .toString()
        .trim();
    const status = extractPaymentStatus(payload) || "pending";
    const paid = isPaidText(status) || payload?.paid === true;
    const transactionId = extractTransactionId(payload);

    let orderSnap = null;
    if (explicitOrderId) {
      const ref = db.collection(ORDER_COLLECTION).doc(explicitOrderId);
      const snap = await ref.get();
      if (snap.exists) orderSnap = snap;
    }
    if (!orderSnap && merchantReference) {
      const snap = await db
        .collection(ORDER_COLLECTION)
        .where("paymentMerchantRef", "==", merchantReference)
        .limit(1)
        .get();
      if (!snap.empty) orderSnap = snap.docs[0];
    }
    if (!orderSnap) {
      const error = new Error("order not found for webhook");
      error.status = 404;
      throw error;
    }

    if (!paid) {
      return {
        data: {
          processed: false,
          orderId: orderSnap.id,
          paymentStatus: "pending",
        },
      };
    }

    const updatePayload = {
      paymentStatus: "paid",
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (transactionId) {
      updatePayload.paymentTransactionId = transactionId;
    }
    await orderSnap.ref.update(updatePayload);

    return {
      data: {
        processed: true,
        orderId: orderSnap.id,
        paymentStatus: "paid",
      },
    };
  }
}

export default PaymentService;
