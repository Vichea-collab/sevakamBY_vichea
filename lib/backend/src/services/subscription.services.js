import Stripe from "stripe";
import admin from "firebase-admin";
import { db } from "../config/firebase.js";
import { env } from "../config/env.js";
import {
  createBakongKhqrCharge,
  verifyBakongKhqrCharge,
} from "./bakong.services.js";

const PLAN_CONFIG = {
  basic: { tier: "basic", bookingLimit: 5, price: 0, maxPhotos: 5 },
  professional: { tier: "professional", bookingLimit: 25, price: 5, maxPhotos: 15 },
  elite: { tier: "elite", bookingLimit: -1, price: 10, maxPhotos: -1 },
};
const SUBSCRIPTION_PAYMENT_COLLECTION = "subscriptionPayments";

function getStripe() {
  const key = process.env.STRIPE_SECRET_KEY || "";
  if (!key) {
    const error = new Error("Stripe is not configured");
    error.status = 500;
    throw error;
  }
  return new Stripe(key);
}

function safeString(value) {
  return (value ?? "").toString().trim();
}

function toIso(value) {
  if (!value) return null;
  if (typeof value?.toDate === "function") return value.toDate().toISOString();
  if (value instanceof Date) {
    if (isNaN(value.getTime())) return null;
    return value.toISOString();
  }
  if (typeof value === "string") {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) return parsed.toISOString();
  }
  if (typeof value === "object" && value._seconds) {
    const seconds = Number(value._seconds);
    if (Number.isFinite(seconds)) return new Date(Math.round(seconds * 1000)).toISOString();
  }
  return null;
}

function stripeToIso(ts) {
  if (!ts || typeof ts !== "number") return new Date().toISOString();
  const date = new Date(ts * 1000);
  return isNaN(date.getTime()) ? new Date().toISOString() : date.toISOString();
}

function addDaysIso(baseDate, days) {
  const value = new Date(baseDate);
  value.setUTCDate(value.getUTCDate() + days);
  return value.toISOString();
}

function parseDate(value) {
  if (!value) return null;
  if (typeof value?.toDate === "function") {
    const date = value.toDate();
    return Number.isNaN(date.getTime()) ? null : date;
  }
  if (value instanceof Date) {
    return Number.isNaN(value.getTime()) ? null : value;
  }
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function resolveTier(value) {
  const tier = safeString(value).toLowerCase();
  if (["professional", "elite"].includes(tier)) return tier;
  return "basic";
}

function resolveBookingLimit(tier) {
  const config = PLAN_CONFIG[tier] || PLAN_CONFIG.basic;
  return config.bookingLimit;
}

function resolveMaxPhotos(tier) {
  const config = PLAN_CONFIG[tier] || PLAN_CONFIG.basic;
  return Number.isFinite(config.maxPhotos) ? config.maxPhotos : PLAN_CONFIG.basic.maxPhotos;
}

function basicSubscriptionState(existingSub = {}, status = "canceled") {
  return {
    ...existingSub,
    tier: "basic",
    status,
    paymentProvider: "",
    stripeSubscriptionId: "",
    bakongMerchantReference: "",
    bakongTransactionId: "",
    bakongKhqrMd5: "",
    currentPeriodStart: null,
    currentPeriodEnd: null,
    cancelAtPeriodEnd: false,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

function subscriptionFromProviderDoc(providerData) {
  const sub = providerData?.subscription || {};
  const tier = resolveTier(sub.tier);
  const limit = resolveBookingLimit(tier);
  const paymentProvider =
    safeString(sub.paymentProvider) ||
    (safeString(sub.stripeSubscriptionId) ? "stripe" : "");
  const stripeSubscriptionId = safeString(sub.stripeSubscriptionId);
  const autoRenews = paymentProvider === "stripe" && stripeSubscriptionId.length > 0;
  const status = tier === "basic"
    ? "active"
    : (safeString(sub.status) || "inactive");
  return {
    tier,
    status,
    paymentProvider,
    stripeCustomerId: safeString(sub.stripeCustomerId),
    stripeSubscriptionId,
    currentPeriodStart: toIso(sub.currentPeriodStart),
    currentPeriodEnd: toIso(sub.currentPeriodEnd),
    cancelAtPeriodEnd: sub.cancelAtPeriodEnd === true,
    autoRenews,
    canCancel: autoRenews,
    bookingLimit: limit,
    bookingsUsed: Number(providerData?.bookingsThisPeriod ?? 0),
    canAcceptBookings: limit < 0 || Number(providerData?.bookingsThisPeriod ?? 0) < limit,
  };
}

async function normalizeProviderSubscriptionState(uid, providerData) {
  const sub = providerData?.subscription || {};
  const paymentProvider = safeString(sub.paymentProvider).toLowerCase();
  const tier = resolveTier(sub.tier);
  const currentPeriodStart = parseDate(sub.currentPeriodStart);
  const currentPeriodEnd = parseDate(sub.currentPeriodEnd);
  if (tier === "basic" || paymentProvider !== "bakong" || !currentPeriodEnd) {
    return providerData || {};
  }

  if (
    currentPeriodStart &&
    currentPeriodEnd &&
    currentPeriodEnd.getTime() <= currentPeriodStart.getTime()
  ) {
    const fixedStart = currentPeriodStart;
    const fixedEnd = addDaysIso(fixedStart, 30);
    const providerRef = db.collection("providers").doc(uid);
    await providerRef.set(
      {
        subscription: {
          ...(providerData?.subscription || {}),
          currentPeriodStart: fixedStart.toISOString(),
          currentPeriodEnd: fixedEnd,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      },
      { merge: true },
    );

    const repaired = await providerRef.get();
    return repaired.data() || {};
  }

  if (currentPeriodEnd.getTime() > Date.now()) {
    return providerData || {};
  }

  const providerRef = db.collection("providers").doc(uid);
  const nextData = {
    ...(providerData || {}),
    subscription: basicSubscriptionState(providerData?.subscription || {}, "expired"),
    bookingsThisPeriod: 0,
  };
  await providerRef.set(nextData, { merge: true });
  await syncProviderSubscriptionToPosts(uid, "basic");

  const refreshed = await providerRef.get();
  return refreshed.data() || {};
}

function resolveSubscriptionPaymentMethod(value) {
  const method = safeString(value).toLowerCase();
  if (["khqr", "bakong"].includes(method)) return "bakong";
  return "stripe";
}

async function syncProviderSubscriptionToPosts(uid, tier) {
  const snap = await db
    .collection("providerPosts")
    .where("providerUid", "==", uid)
    .where("status", "==", "open")
    .get();
  if (snap.empty) return;

  const safeTier = resolveTier(tier);
  const maxPhotos = resolveMaxPhotos(safeTier);
  const batch = db.batch();
  snap.docs.forEach((doc) => {
    const row = doc.data() || {};
    const currentPhotos = Array.isArray(row.portfolioPhotos)
      ? row.portfolioPhotos
      : [];
    const nextPhotos = maxPhotos < 0 ? currentPhotos : currentPhotos.slice(0, maxPhotos);
    batch.set(
      doc.ref,
      {
        subscriptionTier: safeTier,
        portfolioPhotos: nextPhotos,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });
  await batch.commit();
}

class SubscriptionService {
  static async getStatus(uid) {
    const providerRef = db.collection("providers").doc(uid);
    const snap = await providerRef.get();
    if (!snap.exists) {
      const error = new Error("Provider not found");
      error.status = 404;
      throw error;
    }
    const data = await normalizeProviderSubscriptionState(uid, snap.data() || {});
    return { data: subscriptionFromProviderDoc(data) };
  }

  static async createCheckoutSession(uid, payload) {
    const paymentMethod = resolveSubscriptionPaymentMethod(payload.paymentMethod);
    if (paymentMethod === "bakong") {
      return this._createBakongCheckoutSession(uid, payload);
    }

    const stripe = getStripe();
    const planKey = safeString(payload.plan).toLowerCase();

    if (!["professional", "elite"].includes(planKey)) {
      const error = new Error("Invalid plan. Choose professional or elite.");
      error.status = 400;
      throw error;
    }

    const priceEnvKey = planKey === "professional"
      ? "STRIPE_PRICE_PROFESSIONAL"
      : "STRIPE_PRICE_ELITE";
    const priceId = process.env[priceEnvKey] || "";
    if (!priceId) {
      const error = new Error(`Stripe price not configured for ${planKey}`);
      error.status = 500;
      throw error;
    }

    const providerRef = db.collection("providers").doc(uid);
    const providerSnap = await providerRef.get();
    if (!providerSnap.exists) {
      const error = new Error("Provider not found");
      error.status = 404;
      throw error;
    }
    const providerData = providerSnap.data() || {};
    const sub = providerData.subscription || {};

    let customerId = safeString(sub.stripeCustomerId);
    if (!customerId) {
      const userSnap = await db.collection("users").doc(uid).get();
      const userData = userSnap.exists ? userSnap.data() || {} : {};
      const customer = await stripe.customers.create({
        metadata: { firebaseUid: uid },
        email: safeString(userData.email) || undefined,
        name: safeString(userData.name) || undefined,
      });
      customerId = customer.id;
      await providerRef.set(
        { "subscription.stripeCustomerId": customerId },
        { merge: true },
      );
      console.log(`[Stripe] Created/linked customer ${customerId} for provider ${uid}`);
    }

    const successUrl = safeString(payload.successUrl) || "sevakam://subscription/success";
    const cancelUrl = safeString(payload.cancelUrl) || "sevakam://subscription/cancel";

    const session = await stripe.checkout.sessions.create({
      customer: customerId,
      mode: "subscription",
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: successUrl,
      cancel_url: cancelUrl,
      metadata: { firebaseUid: uid, plan: planKey },
      subscription_data: { metadata: { firebaseUid: uid, plan: planKey } },
    });

    return {
      data: {
        sessionId: session.id,
        url: session.url,
        paymentMethod: "stripe",
      },
    };
  }

  /**
   * Verify a checkout session and apply subscription if paid.
   * This is the fallback for when webhooks can't reach the server (e.g. local dev).
   */
  static async verifyCheckoutSession(uid, payload) {
    const paymentMethod = resolveSubscriptionPaymentMethod(payload.paymentMethod);
    const sessionId = safeString(payload.sessionId);
    if (paymentMethod === "bakong" || sessionId.startsWith("khqr_")) {
      return this._verifyBakongCheckoutSession(uid, payload);
    }

    const stripe = getStripe();
    if (!sessionId) {
      const error = new Error("sessionId is required");
      error.status = 400;
      throw error;
    }

    const session = await stripe.checkout.sessions.retrieve(sessionId);
    if (!session) {
      const error = new Error("Checkout session not found");
      error.status = 404;
      throw error;
    }

    // Only apply if the session belongs to this user
    const sessionUid = safeString(session.metadata?.firebaseUid);
    if (sessionUid !== uid) {
      const error = new Error("Session does not belong to this user");
      error.status = 403;
      throw error;
    }

    // Performance: Retry up to 3 times if not yet paid (Stripe propagation delay)
    let currentSession = session;
    for (let i = 0; i < 3; i++) {
      if (currentSession.payment_status === "paid") break;
      console.log(`[Stripe Verify] Attempt ${i + 1}: Session not paid yet, retrying...`);
      await new Promise((resolve) => setTimeout(resolve, 1000));
      currentSession = await stripe.checkout.sessions.retrieve(sessionId);
    }

    if (currentSession.payment_status !== "paid") {
      return { data: { verified: false, status: currentSession.payment_status } };
    }

    // Apply the subscription
    const subscriptionId = safeString(currentSession.subscription);
    const plan = safeString(currentSession.metadata?.plan) || "professional";
    console.log(`[Stripe Verify] Session paid. Subscription: ${subscriptionId}, Plan: ${plan}`);

    if (subscriptionId) {
      try {
        const subscription = await stripe.subscriptions.retrieve(subscriptionId);
        const providerRef = db.collection("providers").doc(uid);

        const updates = {
          subscription: {
            tier: plan,
            status: "active",
            paymentProvider: "stripe",
            stripeCustomerId: safeString(currentSession.customer),
            stripeSubscriptionId: subscriptionId,
            bakongMerchantReference: "",
            bakongTransactionId: "",
            bakongKhqrMd5: "",
            currentPeriodStart: stripeToIso(subscription.current_period_start),
            currentPeriodEnd: stripeToIso(subscription.current_period_end),
            cancelAtPeriodEnd: false,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          bookingsThisPeriod: 0,
        };

        await providerRef.set(updates, { merge: true });
        await syncProviderSubscriptionToPosts(uid, plan);
        console.log(`[Stripe Verify] Successfully updated Firestore for ${uid} to plan ${plan}`);
      } catch (err) {
        console.error(`[Stripe Verify] Error updating Firestore or retrieving subscription: ${err.message}`);
        throw err;
      }
    } else {
      console.warn(`[Stripe Verify] No subscriptionId found in session ${sessionId}`);
    }

    const providerSnap = await db.collection("providers").doc(uid).get();
    return { data: subscriptionFromProviderDoc(providerSnap.data() || {}) };
  }

  static async cancelSubscription(uid) {
    const providerRef = db.collection("providers").doc(uid);
    const snap = await providerRef.get();
    if (!snap.exists) {
      const error = new Error("Provider not found");
      error.status = 404;
      throw error;
    }
    const sub = (snap.data() || {}).subscription || {};
    const paymentProvider = safeString(sub.paymentProvider).toLowerCase();
    if (paymentProvider === "bakong") {
      await providerRef.set(
        {
          subscription: basicSubscriptionState(sub, "canceled"),
          bookingsThisPeriod: 0,
        },
        { merge: true },
      );
      await syncProviderSubscriptionToPosts(uid, "basic");
      const updated = await providerRef.get();
      return { data: subscriptionFromProviderDoc(updated.data() || {}) };
    }

    const stripe = getStripe();
    const subscriptionId = safeString(sub.stripeSubscriptionId);
    if (!subscriptionId) {
      const error = new Error("No active subscription to cancel");
      error.status = 400;
      throw error;
    }

    await stripe.subscriptions.cancel(subscriptionId);

    await providerRef.set(
      {
        subscription: basicSubscriptionState(sub, "canceled"),
        bookingsThisPeriod: 0,
      },
      { merge: true },
    );
    await syncProviderSubscriptionToPosts(uid, "basic");

    const updated = await providerRef.get();
    return { data: subscriptionFromProviderDoc(updated.data() || {}) };
  }

  static async handleWebhook(rawBody, signature) {
    const stripe = getStripe();
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET || "";

    let event;
    if (webhookSecret) {
      try {
        event = stripe.webhooks.constructEvent(rawBody, signature, webhookSecret);
      } catch (err) {
        const error = new Error(`Webhook signature verification failed: ${err.message}`);
        error.status = 400;
        throw error;
      }
    } else {
      event = JSON.parse(rawBody.toString());
    }

    const type = event.type;
    console.log(`[Stripe Webhook] ${type}`);

    switch (type) {
      case "checkout.session.completed":
        await this._onCheckoutCompleted(event.data.object);
        break;
      case "customer.subscription.updated":
        await this._onSubscriptionUpdated(event.data.object);
        break;
      case "customer.subscription.deleted":
        await this._onSubscriptionDeleted(event.data.object);
        break;
      case "invoice.payment_succeeded":
        await this._onInvoicePaid(event.data.object);
        break;
      default:
        console.log(`[Stripe Webhook] Unhandled event: ${type}`);
    }

    return { data: { received: true } };
  }

  static async _onCheckoutCompleted(session) {
    const uid = safeString(session.metadata?.firebaseUid);
    const plan = safeString(session.metadata?.plan);
    if (!uid || !plan) return;

    const stripe = getStripe();
    const subscriptionId = safeString(session.subscription);
    if (!subscriptionId) return;

    const subscription = await stripe.subscriptions.retrieve(subscriptionId);
    const providerRef = db.collection("providers").doc(uid);

    await providerRef.set(
      {
        subscription: {
          tier: plan,
          status: "active",
          paymentProvider: "stripe",
          stripeCustomerId: safeString(session.customer),
          stripeSubscriptionId: subscriptionId,
          bakongMerchantReference: "",
          bakongTransactionId: "",
          bakongKhqrMd5: "",
          currentPeriodStart: stripeToIso(subscription.current_period_start),
          currentPeriodEnd: stripeToIso(subscription.current_period_end),
          cancelAtPeriodEnd: false,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        bookingsThisPeriod: 0,
      },
      { merge: true },
    );
    await syncProviderSubscriptionToPosts(uid, plan);
    console.log(`[Stripe] Subscription activated for ${uid}: ${plan}`);
  }

  static async _onSubscriptionUpdated(subscription) {
    const uid = safeString(subscription.metadata?.firebaseUid);
    if (!uid) return;

    const providerRef = db.collection("providers").doc(uid);
    const snap = await providerRef.get();
    if (!snap.exists) return;

    const status = subscription.status === "active" ? "active" : subscription.status;
    const plan = safeString(subscription.metadata?.plan) || resolveTier((snap.data()?.subscription || {}).tier);
    const existingSub = snap.data()?.subscription || {};

    const updatePayload = {
      subscription: {
        ...(status === "active"
            ? {
                ...existingSub,
                tier: plan,
                status,
                paymentProvider: "stripe",
                currentPeriodStart: stripeToIso(subscription.current_period_start),
                currentPeriodEnd: stripeToIso(subscription.current_period_end),
                cancelAtPeriodEnd: subscription.cancel_at_period_end === true,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              }
            : basicSubscriptionState(existingSub, status)),
      },
    };

    await providerRef.set(updatePayload, { merge: true });
    await syncProviderSubscriptionToPosts(
      uid,
      status === "active" ? plan : "basic",
    );
    console.log(`[Stripe] Subscription updated for ${uid}: ${status}`);
  }

  static async _onSubscriptionDeleted(subscription) {
    const uid = safeString(subscription.metadata?.firebaseUid);
    if (!uid) return;

    const providerRef = db.collection("providers").doc(uid);
    await providerRef.set(
      {
        subscription: basicSubscriptionState({}, "canceled"),
        bookingsThisPeriod: 0,
      },
      { merge: true },
    );
    await syncProviderSubscriptionToPosts(uid, "basic");
    console.log(`[Stripe] Subscription canceled for ${uid}`);
  }

  static async _onInvoicePaid(invoice) {
    const subscriptionId = safeString(invoice.subscription);
    if (!subscriptionId) return;

    const stripe = getStripe();
    const subscription = await stripe.subscriptions.retrieve(subscriptionId);
    const uid = safeString(subscription.metadata?.firebaseUid);
    if (!uid) return;

    const providerRef = db.collection("providers").doc(uid);
    const snap = await providerRef.get();
    const existingSub = snap.data()?.subscription || {};
    await providerRef.set(
      {
        subscription: {
          ...existingSub,
          paymentProvider: "stripe",
          currentPeriodStart: stripeToIso(subscription.current_period_start),
          currentPeriodEnd: stripeToIso(subscription.current_period_end),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        bookingsThisPeriod: 0,
      },
      { merge: true },
    );
    console.log(`[Stripe] Invoice paid, period reset for ${uid}`);
  }

  static async checkBookingAllowance(uid) {
    const providerRef = db.collection("providers").doc(uid);
    const snap = await providerRef.get();
    if (!snap.exists) return { allowed: true, tier: "basic", used: 0, limit: 5 };

    const data = await normalizeProviderSubscriptionState(uid, snap.data() || {});
    const sub = subscriptionFromProviderDoc(data);
    return {
      allowed: sub.canAcceptBookings,
      tier: sub.tier,
      used: sub.bookingsUsed,
      limit: sub.bookingLimit,
    };
  }

  static async incrementBookingCount(uid) {
    const providerRef = db.collection("providers").doc(uid);
    await providerRef.set(
      { bookingsThisPeriod: admin.firestore.FieldValue.increment(1) },
      { merge: true },
    );
  }

  static async _createBakongCheckoutSession(uid, payload) {
    const planKey = safeString(payload.plan).toLowerCase();
    if (!["professional", "elite"].includes(planKey)) {
      const error = new Error("Invalid plan. Choose professional or elite.");
      error.status = 400;
      throw error;
    }

    const providerRef = db.collection("providers").doc(uid);
    const providerSnap = await providerRef.get();
    if (!providerSnap.exists) {
      const error = new Error("Provider not found");
      error.status = 404;
      throw error;
    }

    const amount = Number(PLAN_CONFIG[planKey]?.price ?? 0);
    if (!Number.isFinite(amount) || amount <= 0) {
      const error = new Error("Invalid plan amount for Bakong payment.");
      error.status = 400;
      throw error;
    }

    const sessionId = `khqr_${db.collection(SUBSCRIPTION_PAYMENT_COLLECTION).doc().id}`;
    const merchantReference = `SUB_${sessionId}_${Date.now()}`;
    const checkout = await createBakongKhqrCharge({
      referenceId: sessionId,
      amount,
      merchantReference,
      purpose: `Subscription ${planKey}`,
    });

    const paymentRef = db.collection(SUBSCRIPTION_PAYMENT_COLLECTION).doc(sessionId);
    await paymentRef.set({
      uid,
      plan: planKey,
      amount,
      currency: checkout.currency,
      paymentMethod: "bakong",
      paymentProvider: "bakong",
      paymentStatus: "pending",
      merchantReference: checkout.merchantReference,
      transactionId: checkout.transactionId,
      khqrPayload: checkout.qrPayload,
      qrImageUrl: checkout.qrImageUrl,
      khqrMd5: checkout.khqrMd5,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      data: {
        sessionId,
        paymentMethod: "bakong",
        amount,
        currency: checkout.currency,
        merchantReference: checkout.merchantReference,
        transactionId: checkout.transactionId,
        qrPayload: checkout.qrPayload,
        qrImageUrl: checkout.qrImageUrl,
      },
    };
  }

  static async _verifyBakongCheckoutSession(uid, payload) {
    const sessionId = safeString(payload.sessionId);
    if (!sessionId) {
      const error = new Error("sessionId is required");
      error.status = 400;
      throw error;
    }

    const paymentRef = db.collection(SUBSCRIPTION_PAYMENT_COLLECTION).doc(sessionId);
    const paymentSnap = await paymentRef.get();
    if (!paymentSnap.exists) {
      const error = new Error("Bakong checkout session not found");
      error.status = 404;
      throw error;
    }

    const paymentData = paymentSnap.data() || {};
    if (safeString(paymentData.uid) !== uid) {
      const error = new Error("Session does not belong to this user");
      error.status = 403;
      throw error;
    }

    const verification = await verifyBakongKhqrCharge({
      referenceId: sessionId,
      amount: paymentData.amount,
      currency: paymentData.currency || env.BAKONG_CURRENCY,
      merchantReference: paymentData.merchantReference,
      transactionId: paymentData.transactionId,
      qrPayload: paymentData.khqrPayload,
      khqrMd5: paymentData.khqrMd5,
    });

    if (!verification.paid) {
      await paymentRef.set(
        {
          paymentStatus: "pending",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      return {
        data: {
          verified: false,
          paymentMethod: "bakong",
          status: verification.status,
          paymentStatus: "pending",
        },
      };
    }

    const providerRef = db.collection("providers").doc(uid);
    const providerSnap = await providerRef.get();
    if (!providerSnap.exists) {
      const error = new Error("Provider not found");
      error.status = 404;
      throw error;
    }

    const providerData = providerSnap.data() || {};
    const existingSub = providerData.subscription || {};
    const now = new Date();
    const existingEnd = parseDate(existingSub.currentPeriodEnd);
    const periodStart = existingEnd && existingEnd.getTime() > now.getTime()
      ? now.toISOString()
      : now.toISOString();
    const periodEnd = existingEnd && existingEnd.getTime() > now.getTime()
      ? addDaysIso(existingEnd, 30)
      : addDaysIso(now, 30);
    const plan = resolveTier(paymentData.plan);

    await providerRef.set(
      {
        subscription: {
          ...existingSub,
          tier: plan,
          status: "active",
          paymentProvider: "bakong",
          stripeCustomerId: "",
          stripeSubscriptionId: "",
          bakongMerchantReference: safeString(paymentData.merchantReference),
          bakongTransactionId: verification.transactionId,
          bakongKhqrMd5: safeString(paymentData.khqrMd5),
          currentPeriodStart: periodStart,
          currentPeriodEnd: periodEnd,
          cancelAtPeriodEnd: false,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        bookingsThisPeriod: 0,
      },
      { merge: true },
    );
    await syncProviderSubscriptionToPosts(uid, plan);

    await paymentRef.set(
      {
        paymentStatus: "paid",
        transactionId: verification.transactionId,
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    const refreshedProvider = await providerRef.get();
    return { data: subscriptionFromProviderDoc(refreshedProvider.data() || {}) };
  }
}

export default SubscriptionService;
export { PLAN_CONFIG, resolveTier, resolveBookingLimit, resolveMaxPhotos };
