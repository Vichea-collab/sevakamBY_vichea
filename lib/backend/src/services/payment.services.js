import crypto from "crypto";
import admin from "firebase-admin";
import { db } from "../config/firebase.js";
import { env } from "../config/env.js";
import { mapOrderDoc } from "./order.services.js";

const ORDER_COLLECTION = "orders";
const KHQR_SDK_CANDIDATES = ["bakong-khqr", "@bakong/khqr", "@api-bakong-khqr/core"];

function normalizePaymentMethod(value) {
  const method = (value || "").toString().trim().toLowerCase();
  if (!method) return "credit_card";
  return method;
}

function toNumber(value, fallback = 0) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function normalizeText(value, fallback = "") {
  const text = (value || "").toString().trim();
  return text || fallback;
}

function isPaidText(value) {
  const text = (value || "").toString().trim().toLowerCase();
  return ["paid", "success", "completed", "settled", "approved"].includes(text);
}

function deepFind(value, key) {
  if (!value || typeof value !== "object") return null;
  if (Object.prototype.hasOwnProperty.call(value, key)) {
    return value[key];
  }
  for (const entry of Object.values(value)) {
    const found = deepFind(entry, key);
    if (found !== null && found !== undefined) return found;
  }
  return null;
}

function extractPaymentStatus(payload) {
  const candidates = [
    payload?.status,
    payload?.paymentStatus,
    payload?.result,
    payload?.responseCode,
    deepFind(payload, "status"),
    deepFind(payload, "paymentStatus"),
    deepFind(payload, "responseCode"),
  ];
  for (const candidate of candidates) {
    const value = (candidate || "").toString().trim();
    if (value) return value;
  }
  return "";
}

function extractTransactionId(payload) {
  const candidates = [
    payload?.transactionId,
    payload?.txnId,
    payload?.id,
    payload?.tranId,
    deepFind(payload, "transactionId"),
    deepFind(payload, "txnId"),
    deepFind(payload, "id"),
    deepFind(payload, "tranId"),
  ];
  for (const candidate of candidates) {
    const value = (candidate || "").toString().trim();
    if (value) return value;
  }
  return "";
}

function extractKhqrPayload(payload) {
  const candidates = [
    payload?.qrPayload,
    payload?.khqr,
    payload?.qrString,
    payload?.payload,
    payload?.qr,
    payload?.data,
    deepFind(payload, "qrPayload"),
    deepFind(payload, "khqr"),
    deepFind(payload, "qrString"),
    deepFind(payload, "payload"),
    deepFind(payload, "qr"),
  ];
  for (const candidate of candidates) {
    if (typeof candidate === "string") {
      const value = candidate.trim();
      if (value) return value;
      continue;
    }
    if (candidate && typeof candidate === "object") {
      const nested = extractKhqrPayload(candidate);
      if (nested) return nested;
    }
  }
  return "";
}

function extractKhqrImageUrl(payload) {
  const candidates = [
    payload?.qrImageUrl,
    payload?.qrUrl,
    payload?.imageUrl,
    deepFind(payload, "qrImageUrl"),
    deepFind(payload, "qrUrl"),
    deepFind(payload, "imageUrl"),
  ];
  for (const candidate of candidates) {
    const value = (candidate || "").toString().trim();
    if (value) return value;
  }
  return "";
}

function md5Hex(value) {
  const text = (value || "").toString();
  if (!text) return "";
  return crypto.createHash("md5").update(text).digest("hex");
}

function bakongCheckEnabled() {
  return (
    env.BAKONG_BASE_URL.trim().length > 0 &&
    env.BAKONG_PARTNER_TOKEN.trim().length > 0 &&
    env.BAKONG_KHQR_CHECK_PATH.trim().length > 0
  );
}

function buildBakongUrl(path) {
  const base = env.BAKONG_BASE_URL.trim().replace(/\/+$/, "");
  const suffix = (path || "").toString().trim();
  if (!suffix) return base;
  if (suffix.startsWith("/")) return `${base}${suffix}`;
  return `${base}/${suffix}`;
}

async function fetchJson(url, options = {}) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 8000);
  try {
    const response = await fetch(url, {
      ...options,
      signal: controller.signal,
    });
    const text = await response.text();
    let parsed = {};
    if (text) {
      try {
        parsed = JSON.parse(text);
      } catch (_) {
        parsed = { raw: text };
      }
    }
    return {
      ok: response.ok,
      status: response.status,
      data: parsed,
    };
  } finally {
    clearTimeout(timeout);
  }
}

function buildBakongAuthHeaders() {
  return {
    Authorization: `Bearer ${env.BAKONG_PARTNER_TOKEN.trim()}`,
    Accept: "application/json",
  };
}

async function checkKhqrStatus(payload) {
  const method = normalizeText(env.BAKONG_KHQR_CHECK_METHOD, "POST").toUpperCase();
  const url = buildBakongUrl(env.BAKONG_KHQR_CHECK_PATH);
  const headers = buildBakongAuthHeaders();

  if (method === "GET") {
    const query = new URLSearchParams();
    for (const [key, value] of Object.entries(payload || {})) {
      if (value === null || value === undefined) continue;
      if (typeof value === "object") continue;
      const text = value.toString().trim();
      if (text) query.set(key, text);
    }
    const queryText = query.toString();
    return fetchJson(queryText ? `${url}?${queryText}` : url, {
      method: "GET",
      headers,
    });
  }

  return fetchJson(url, {
    method: "POST",
    headers: {
      ...headers,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload || {}),
  });
}

function normalizeSdkApi(moduleValue) {
  if (!moduleValue || typeof moduleValue !== "object") return null;
  if (moduleValue.default && typeof moduleValue.default === "object") {
    return { ...moduleValue.default, ...moduleValue };
  }
  return moduleValue;
}

async function loadKhqrSdk() {
  for (const packageName of KHQR_SDK_CANDIDATES) {
    try {
      const loaded = await import(packageName);
      const sdk = normalizeSdkApi(loaded);
      if (sdk) return sdk;
    } catch (_) {
      // Try next candidate package.
    }
  }
  return null;
}

function firstKhqrString(value) {
  if (!value) return "";
  if (typeof value === "string") return value.trim();
  if (Array.isArray(value)) {
    for (const item of value) {
      const found = firstKhqrString(item);
      if (found) return found;
    }
    return "";
  }
  if (typeof value === "object") {
    const direct = extractKhqrPayload(value);
    if (direct) return direct;
    for (const nested of Object.values(value)) {
      const found = firstKhqrString(nested);
      if (found) return found;
    }
  }
  return "";
}

function buildKhqrSdkPayload({ orderId, amount, merchantReference }) {
  const expiryMinutes = Number.isFinite(env.BAKONG_KHQR_EXP_MINUTES)
    ? Math.max(1, Math.floor(env.BAKONG_KHQR_EXP_MINUTES))
    : 30;
  return {
    accountId: normalizeText(env.BAKONG_KHQR_ACCOUNT),
    merchantId: normalizeText(env.BAKONG_MERCHANT_ID),
    merchantName: normalizeText(env.BAKONG_KHQR_MERCHANT_NAME, "Service Provider"),
    merchantCity: normalizeText(env.BAKONG_KHQR_MERCHANT_CITY, "Phnom Penh"),
    merchantCategoryCode: normalizeText(env.BAKONG_KHQR_MERCHANT_CATEGORY, "5999"),
    terminalId: normalizeText(env.BAKONG_TERMINAL_ID),
    amount,
    currency: normalizeText(env.BAKONG_CURRENCY, "USD"),
    billNumber: orderId,
    merchantReference,
    storeLabel: normalizeText(env.BAKONG_KHQR_MERCHANT_NAME, "Service Provider"),
    purposeOfTransaction: `Order ${orderId}`,
    expirationTimestamp: Math.floor(Date.now() / 1000) + expiryMinutes * 60,
  };
}

async function generateKhqrFromSdk({ orderId, amount, merchantReference }) {
  const sdk = await loadKhqrSdk();
  if (!sdk) {
    const error = new Error(
      "KHQR SDK is missing. Install one of: bakong-khqr, @bakong/khqr, or @api-bakong-khqr/core.",
    );
    error.status = 400;
    throw error;
  }

  const payload = buildKhqrSdkPayload({ orderId, amount, merchantReference });

  if (!payload.accountId) {
    const error = new Error("BAKONG_KHQR_ACCOUNT is required for KHQR generation.");
    error.status = 400;
    throw error;
  }

  const fnCandidates = [
    "generateKHQR",
    "generateKhqr",
    "generateQr",
    "generateQrString",
    "generate",
  ];

  for (const fnName of fnCandidates) {
    const fn = sdk?.[fnName];
    if (typeof fn !== "function") continue;
    try {
      const result = await fn(payload);
      const qrPayload = firstKhqrString(result);
      if (qrPayload) return qrPayload;
    } catch (_) {
      // Continue with next function signature.
    }
  }

  if (typeof sdk.BakongKHQR === "function") {
    try {
      const instance = new sdk.BakongKHQR();
      const methodCandidates = ["generateIndividual", "generateMerchant", "generate", "generateKHQR"];
      for (const methodName of methodCandidates) {
        const method = instance?.[methodName];
        if (typeof method !== "function") continue;

        try {
          const raw = await method(payload);
          const qrPayload = firstKhqrString(raw);
          if (qrPayload) return qrPayload;
        } catch (_) {
          // Try MerchantInfo/IndividualInfo wrappers if available.
          if (typeof sdk.MerchantInfo === "function") {
            try {
              const merchantInfo = new sdk.MerchantInfo(payload);
              const wrapped = await method(merchantInfo);
              const qrPayload = firstKhqrString(wrapped);
              if (qrPayload) return qrPayload;
            } catch (_) {
              // Fall through.
            }
          }
          if (typeof sdk.IndividualInfo === "function") {
            try {
              const individualInfo = new sdk.IndividualInfo(payload);
              const wrapped = await method(individualInfo);
              const qrPayload = firstKhqrString(wrapped);
              if (qrPayload) return qrPayload;
            } catch (_) {
              // Continue.
            }
          }
        }
      }
    } catch (_) {
      // Continue and throw generic error below.
    }
  }

  const error = new Error(
    "KHQR SDK was loaded but could not generate payload. Check SDK package/version and merchant inputs.",
  );
  error.status = 400;
  throw error;
}

function buildQrImageUrl(qrPayload) {
  if (!qrPayload) return "";
  return `https://quickchart.io/qr?text=${encodeURIComponent(qrPayload)}&size=320`;
}

function buildCheckStatusPayload({ row, orderId, merchantReference, transactionId }) {
  const qrPayload = normalizeText(row.khqrPayload);
  const khqrMd5 = md5Hex(qrPayload);
  return {
    merchantReference,
    merchantRef: merchantReference,
    transactionId: transactionId || undefined,
    orderId,
    md5: khqrMd5 || undefined,
    hash: khqrMd5 || undefined,
    amount: toNumber(row.total, 0),
    currency: normalizeText(env.BAKONG_CURRENCY, "USD"),
    merchantId: normalizeText(env.BAKONG_MERCHANT_ID),
    terminalId: normalizeText(env.BAKONG_TERMINAL_ID),
  };
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

    let qrPayload = "";
    let qrImageUrl = "";
    let transactionId = (row.paymentTransactionId || "").toString().trim();

    try {
      qrPayload = await generateKhqrFromSdk({
        orderId,
        amount,
        merchantReference,
      });
      qrImageUrl = buildQrImageUrl(qrPayload);
    } catch (sdkError) {
      if (env.BAKONG_ALLOW_MOCK) {
        qrPayload = `KHQR-MOCK:${merchantReference}:USD:${amount.toFixed(2)}`;
        qrImageUrl = "";
        transactionId = transactionId || `MOCK_TXN_${Date.now()}`;
      } else {
        const error = new Error(sdkError?.message || "failed to generate khqr");
        error.status = 400;
        throw error;
      }
    }

    if (!qrPayload) {
      const error = new Error("khqr sdk did not return qr payload");
      error.status = 400;
      throw error;
    }

    await orderRef.update({
      paymentMethod: "khqr",
      paymentStatus: "pending",
      paymentMerchantRef: merchantReference,
      paymentTransactionId: transactionId,
      paymentKhqrMd5: md5Hex(qrPayload),
      khqrPayload: qrPayload,
      khqrImageUrl: qrImageUrl,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      data: {
        orderId,
        amount,
        currency: env.BAKONG_CURRENCY || "USD",
        merchantReference,
        transactionId,
        qrPayload,
        qrImageUrl,
        paymentStatus: "pending",
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

    let paid = false;
    let status = "pending";
    let verifiedTransactionId = transactionId;

    if (bakongCheckEnabled()) {
      const checkPayload = buildCheckStatusPayload({
        row,
        orderId,
        merchantReference,
        transactionId,
      });
      const response = await checkKhqrStatus(checkPayload);
      if (!response.ok) {
        const error = new Error(
          (response.data?.message || "failed to check khqr payment status").toString(),
        );
        error.status = 400;
        throw error;
      }
      status = extractPaymentStatus(response.data) || status;
      paid = isPaidText(status) || response.data?.paid === true;
      verifiedTransactionId =
        extractTransactionId(response.data) || verifiedTransactionId;
    } else if (env.BAKONG_ALLOW_MOCK) {
      paid = true;
      status = "paid";
      verifiedTransactionId =
        verifiedTransactionId || `MOCK_TXN_${Date.now()}`;
    } else {
      const error = new Error(
        "Bakong check-status credentials are missing. Configure backend .env first.",
      );
      error.status = 400;
      throw error;
    }

    if (!paid) {
      return {
        data: {
          paid: false,
          paymentStatus: "pending",
          status,
          order: mapOrderDoc(orderSnap),
        },
      };
    }

    await orderRef.update({
      paymentStatus: "paid",
      paymentTransactionId: verifiedTransactionId,
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
    const secret = env.BAKONG_WEBHOOK_SECRET.trim();
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
