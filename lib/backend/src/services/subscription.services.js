import Stripe from "stripe";
import admin from "firebase-admin";
import { db } from "../config/firebase.js";

const PLAN_CONFIG = {
  basic: { tier: "basic", bookingLimit: 5, price: 0 },
  professional: { tier: "professional", bookingLimit: 25, price: 10 },
  elite: { tier: "elite", bookingLimit: -1, price: 25 },
};

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

function resolveTier(value) {
  const tier = safeString(value).toLowerCase();
  if (["professional", "elite"].includes(tier)) return tier;
  return "basic";
}

function resolveBookingLimit(tier) {
  const config = PLAN_CONFIG[tier] || PLAN_CONFIG.basic;
  return config.bookingLimit;
}

function subscriptionFromProviderDoc(providerData) {
  const sub = providerData?.subscription || {};
  const tier = resolveTier(sub.tier);
  const limit = resolveBookingLimit(tier);
  return {
    tier,
    status: safeString(sub.status) || (tier === "basic" ? "active" : "inactive"),
    stripeCustomerId: safeString(sub.stripeCustomerId),
    stripeSubscriptionId: safeString(sub.stripeSubscriptionId),
    currentPeriodStart: toIso(sub.currentPeriodStart),
    currentPeriodEnd: toIso(sub.currentPeriodEnd),
    cancelAtPeriodEnd: sub.cancelAtPeriodEnd === true,
    bookingLimit: limit,
    bookingsUsed: Number(providerData?.bookingsThisPeriod ?? 0),
    canAcceptBookings: limit < 0 || Number(providerData?.bookingsThisPeriod ?? 0) < limit,
  };
}

async function syncProviderSubscriptionToPosts(uid, tier) {
  const snap = await db
    .collection("providerPosts")
    .where("providerUid", "==", uid)
    .where("status", "==", "open")
    .get();
  if (snap.empty) return;

  const safeTier = resolveTier(tier);
  const batch = db.batch();
  snap.docs.forEach((doc) => {
    batch.set(
      doc.ref,
      {
        subscriptionTier: safeTier,
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
    const data = snap.data() || {};
    return { data: subscriptionFromProviderDoc(data) };
  }

  static async createCheckoutSession(uid, payload) {
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
      },
    };
  }

  /**
   * Verify a checkout session and apply subscription if paid.
   * This is the fallback for when webhooks can't reach the server (e.g. local dev).
   */
  static async verifyCheckoutSession(uid, payload) {
    const stripe = getStripe();
    const sessionId = safeString(payload.sessionId);
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
            stripeCustomerId: safeString(currentSession.customer),
            stripeSubscriptionId: subscriptionId,
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
    const stripe = getStripe();
    const providerRef = db.collection("providers").doc(uid);
    const snap = await providerRef.get();
    if (!snap.exists) {
      const error = new Error("Provider not found");
      error.status = 404;
      throw error;
    }
    const sub = (snap.data() || {}).subscription || {};
    const subscriptionId = safeString(sub.stripeSubscriptionId);
    if (!subscriptionId) {
      const error = new Error("No active subscription to cancel");
      error.status = 400;
      throw error;
    }

    await stripe.subscriptions.update(subscriptionId, {
      cancel_at_period_end: true,
    });

    await providerRef.set(
      { subscription: { cancelAtPeriodEnd: true } },
      { merge: true },
    );

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
          stripeCustomerId: safeString(session.customer),
          stripeSubscriptionId: subscriptionId,
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
        ...existingSub,
        tier: status === "active" ? plan : "basic",
        status,
        currentPeriodStart: stripeToIso(subscription.current_period_start),
        currentPeriodEnd: stripeToIso(subscription.current_period_end),
        cancelAtPeriodEnd: subscription.cancel_at_period_end === true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
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
        subscription: {
          tier: "basic",
          status: "canceled",
          stripeSubscriptionId: "",
          cancelAtPeriodEnd: false,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
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

    const data = snap.data() || {};
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
}

export default SubscriptionService;
export { PLAN_CONFIG, resolveTier, resolveBookingLimit };
