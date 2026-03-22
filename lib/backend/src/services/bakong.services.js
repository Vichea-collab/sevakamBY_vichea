import crypto from "crypto";
import { env } from "../config/env.js";

const KHQR_SDK_CANDIDATES = ["bakong-khqr", "@bakong/khqr", "@api-bakong-khqr/core"];

function normalizeText(value, fallback = "") {
  const text = (value || "").toString().trim();
  return text || fallback;
}

function toNumber(value, fallback = 0) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
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

function isPaidText(value) {
  const text = (value || "").toString().trim().toLowerCase();
  return ["paid", "success", "completed", "settled", "approved"].includes(text);
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

function buildKhqrSdkPayload({ referenceId, amount, merchantReference, purpose }) {
  const expiryMinutes = Number.isFinite(env.BAKONG_KHQR_EXP_MINUTES)
    ? Math.max(1, Math.floor(env.BAKONG_KHQR_EXP_MINUTES))
    : 30;
  const payload = {
    accountId: normalizeText(env.BAKONG_KHQR_ACCOUNT),
    merchantName: normalizeText(env.BAKONG_KHQR_MERCHANT_NAME, "Sevakam"),
    merchantCity: normalizeText(env.BAKONG_KHQR_MERCHANT_CITY, "Phnom Penh"),
    merchantCategoryCode: normalizeText(env.BAKONG_KHQR_MERCHANT_CATEGORY, "5999"),
    amount,
    currency: normalizeText(env.BAKONG_CURRENCY, "USD"),
    billNumber: referenceId,
    merchantReference,
    storeLabel: normalizeText(env.BAKONG_KHQR_MERCHANT_NAME, "Sevakam"),
    purposeOfTransaction: normalizeText(purpose, referenceId),
    expirationTimestamp: Math.floor(Date.now() / 1000) + expiryMinutes * 60,
  };
  const merchantId = normalizeText(env.BAKONG_MERCHANT_ID);
  const terminalId = normalizeText(env.BAKONG_TERMINAL_ID);
  if (merchantId) payload.merchantId = merchantId;
  if (terminalId) payload.terminalId = terminalId;
  return payload;
}

async function generateKhqrFromSdk({ referenceId, amount, merchantReference, purpose }) {
  const sdk = await loadKhqrSdk();
  if (!sdk) {
    const error = new Error(
      "KHQR SDK is missing. Install one of: bakong-khqr, @bakong/khqr, or @api-bakong-khqr/core.",
    );
    error.status = 400;
    throw error;
  }

  const payload = buildKhqrSdkPayload({
    referenceId,
    amount,
    merchantReference,
    purpose,
  });

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
          if (typeof sdk.MerchantInfo === "function") {
            try {
              const merchantInfo = new sdk.MerchantInfo(payload);
              const wrapped = await method(merchantInfo);
              const qrPayload = firstKhqrString(wrapped);
              if (qrPayload) return qrPayload;
            } catch (_) {
              // Continue.
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

function buildCheckStatusPayload({
  referenceId,
  amount,
  currency,
  merchantReference,
  transactionId,
  qrPayload,
  khqrMd5,
}) {
  const resolvedKhqrMd5 = normalizeText(khqrMd5) || md5Hex(normalizeText(qrPayload));
  const payload = {
    merchantReference,
    merchantRef: merchantReference,
    transactionId: transactionId || undefined,
    orderId: referenceId,
    md5: resolvedKhqrMd5 || undefined,
    hash: resolvedKhqrMd5 || undefined,
    amount: toNumber(amount, 0),
    currency: normalizeText(currency, normalizeText(env.BAKONG_CURRENCY, "USD")),
  };
  const merchantId = normalizeText(env.BAKONG_MERCHANT_ID);
  const terminalId = normalizeText(env.BAKONG_TERMINAL_ID);
  if (merchantId) payload.merchantId = merchantId;
  if (terminalId) payload.terminalId = terminalId;
  return payload;
}

export async function createBakongKhqrCharge({
  referenceId,
  amount,
  merchantReference,
  purpose,
}) {
  const normalizedReference = normalizeText(referenceId);
  const normalizedMerchantReference = normalizeText(
    merchantReference,
    `KHQR_${normalizedReference}_${Date.now()}`,
  );
  const normalizedAmount = toNumber(amount, 0);
  if (!normalizedReference) {
    const error = new Error("referenceId is required for bakong payment");
    error.status = 400;
    throw error;
  }
  if (normalizedAmount <= 0) {
    const error = new Error("amount must be greater than zero");
    error.status = 400;
    throw error;
  }

  let qrPayload = "";
  let qrImageUrl = "";
  let transactionId = "";

  try {
    qrPayload = await generateKhqrFromSdk({
      referenceId: normalizedReference,
      amount: normalizedAmount,
      merchantReference: normalizedMerchantReference,
      purpose,
    });
    qrImageUrl = buildQrImageUrl(qrPayload);
  } catch (sdkError) {
    if (env.BAKONG_ALLOW_MOCK) {
      qrPayload = `KHQR-MOCK:${normalizedMerchantReference}:${normalizeText(env.BAKONG_CURRENCY, "USD")}:${normalizedAmount.toFixed(2)}`;
      qrImageUrl = "";
      transactionId = `MOCK_TXN_${Date.now()}`;
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

  return {
    amount: normalizedAmount,
    currency: normalizeText(env.BAKONG_CURRENCY, "USD"),
    merchantReference: normalizedMerchantReference,
    transactionId,
    qrPayload,
    qrImageUrl,
    khqrMd5: md5Hex(qrPayload),
    paymentStatus: "pending",
  };
}

export async function verifyBakongKhqrCharge({
  referenceId,
  amount,
  currency,
  merchantReference,
  transactionId,
  qrPayload,
  khqrMd5,
}) {
  const normalizedReference = normalizeText(referenceId);
  const normalizedMerchantReference = normalizeText(merchantReference);
  let verifiedTransactionId = normalizeText(transactionId);
  let paid = false;
  let status = "pending";

  if (!normalizedReference || !normalizedMerchantReference) {
    const error = new Error("referenceId and merchantReference are required");
    error.status = 400;
    throw error;
  }

  if (bakongCheckEnabled()) {
    const checkPayload = buildCheckStatusPayload({
      referenceId: normalizedReference,
      amount,
      currency,
      merchantReference: normalizedMerchantReference,
      transactionId: verifiedTransactionId,
      qrPayload,
      khqrMd5,
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
    verifiedTransactionId = extractTransactionId(response.data) || verifiedTransactionId;
  } else if (env.BAKONG_ALLOW_MOCK) {
    paid = true;
    status = "paid";
    verifiedTransactionId = verifiedTransactionId || `MOCK_TXN_${Date.now()}`;
  } else {
    const error = new Error(
      "Bakong check-status credentials are missing. Configure backend .env first.",
    );
    error.status = 400;
    throw error;
  }

  return {
    paid,
    paymentStatus: paid ? "paid" : "pending",
    status,
    transactionId: verifiedTransactionId,
  };
}

export function getBakongWebhookSecret() {
  return env.BAKONG_WEBHOOK_SECRET.trim();
}

export { deepFind, extractPaymentStatus, extractTransactionId, isPaidText, md5Hex };
