import crypto from "crypto";
import admin from "firebase-admin";

import { db, messaging } from "../config/firebase.js";

const PUSH_REGISTRATION_COLLECTION = "pushRegistrations";
const MAX_USER_PUSH_TOKENS = 12;
const INVALID_TOKEN_CODES = new Set([
  "messaging/invalid-registration-token",
  "messaging/registration-token-not-registered",
]);
const GENERAL_CHANNEL_ID = "sevakam_general";
const SILENT_CHANNEL_ID = "sevakam_general_silent";

function safeString(value) {
  return (value ?? "").toString().trim();
}

function normalizePlatform(value) {
  const platform = safeString(value).toLowerCase();
  if (["android", "ios", "web"].includes(platform)) return platform;
  return "unknown";
}

function tokenDocId(token) {
  return crypto.createHash("sha256").update(token).digest("hex");
}

function sanitizeData(data = {}) {
  const next = {};
  Object.entries(data || {}).forEach(([key, value]) => {
    const safeKey = safeString(key);
    if (!safeKey) return;
    if (value === undefined || value === null) return;
    next[safeKey] = typeof value === "string" ? value : JSON.stringify(value);
  });
  return next;
}

async function getUserNotificationPreferences(uid) {
  const targetUid = safeString(uid);
  if (!targetUid) {
    return {
      general: true,
      sound: true,
      vibrate: true,
    };
  }

  try {
    const settingsSnap = await db
      .collection("users")
      .doc(targetUid)
      .collection("app")
      .doc("settings")
      .get();
    const notifications = settingsSnap.data()?.notifications || {};
    return {
      general: notifications.general !== false,
      sound: notifications.sound !== false,
      vibrate: notifications.vibrate !== false,
    };
  } catch (_) {
    return {
      general: true,
      sound: true,
      vibrate: true,
    };
  }
}

async function pruneUserRegistrations(uid) {
  const snap = await db
    .collection(PUSH_REGISTRATION_COLLECTION)
    .where("uid", "==", uid)
    .limit(MAX_USER_PUSH_TOKENS + 12)
    .get();
  if (snap.empty || snap.size <= MAX_USER_PUSH_TOKENS) return;

  const sorted = snap.docs.sort((left, right) => {
    const leftAt = left.data()?.updatedAt?.toMillis?.() ?? 0;
    const rightAt = right.data()?.updatedAt?.toMillis?.() ?? 0;
    return rightAt - leftAt;
  });
  const staleDocs = sorted.slice(MAX_USER_PUSH_TOKENS);
  if (staleDocs.length == 0) return;

  const batch = db.batch();
  staleDocs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
}

async function deleteRegistrationDocs(docs = []) {
  if (!Array.isArray(docs) || docs.length === 0) return;
  const batch = db.batch();
  docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
}

class PushService {
  static async registerToken(uid, payload = {}) {
    const token = safeString(payload.token);
    if (!token) {
      const error = new Error("push token is required");
      error.status = 400;
      throw error;
    }

    const platform = normalizePlatform(payload.platform);
    const docRef = db.collection(PUSH_REGISTRATION_COLLECTION).doc(tokenDocId(token));
    const existing = await docRef.get();
    const now = admin.firestore.FieldValue.serverTimestamp();
    await docRef.set(
      {
        uid,
        token,
        platform,
        updatedAt: now,
        ...(existing.exists ? {} : { createdAt: now }),
      },
      { merge: true },
    );
    await pruneUserRegistrations(uid);
    return { data: { token, platform, registered: true } };
  }

  static async unregisterToken(uid, payload = {}) {
    const token = safeString(payload.token);
    if (!token) {
      const error = new Error("push token is required");
      error.status = 400;
      throw error;
    }

    const docRef = db.collection(PUSH_REGISTRATION_COLLECTION).doc(tokenDocId(token));
    const snap = await docRef.get();
    if (snap.exists && safeString(snap.data()?.uid) === uid) {
      await docRef.delete();
    }
    return { data: { token, unregistered: true } };
  }

  static async sendToUser({ uid, title, body, data = {} }) {
    const targetUid = safeString(uid);
    if (!targetUid) return { sentCount: 0, failedCount: 0 };

    const preferences = await getUserNotificationPreferences(targetUid);
    if (!preferences.general) {
      return { sentCount: 0, failedCount: 0 };
    }

    const registrationsSnap = await db
      .collection(PUSH_REGISTRATION_COLLECTION)
      .where("uid", "==", targetUid)
      .limit(MAX_USER_PUSH_TOKENS)
      .get();
    if (registrationsSnap.empty) {
      return { sentCount: 0, failedCount: 0 };
    }

    const tokens = [];
    const tokenDocs = [];
    registrationsSnap.docs.forEach((doc) => {
      const token = safeString(doc.data()?.token);
      if (!token) return;
      tokens.push(token);
      tokenDocs.push(doc);
    });
    if (tokens.length === 0) {
      return { sentCount: 0, failedCount: 0 };
    }

    const response = await messaging.sendEachForMulticast({
      tokens,
      notification: {
        title: safeString(title) || "Sevakam",
        body: safeString(body) || "You have a new notification.",
      },
      data: sanitizeData(data),
      android: {
        priority: "high",
        notification: {
          channelId: preferences.sound ? GENERAL_CHANNEL_ID : SILENT_CHANNEL_ID,
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
          ...(preferences.sound ? { sound: "default" } : {}),
        },
      },
      apns: {
        headers: {
          "apns-priority": "10",
        },
        payload: {
          aps: {
            badge: 1,
            contentAvailable: true,
            ...(preferences.sound ? { sound: "default" } : {}),
          },
        },
      },
    });

    const invalidDocs = [];
    response.responses.forEach((row, index) => {
      if (row.success) return;
      const code = safeString(row.error?.code);
      if (!INVALID_TOKEN_CODES.has(code)) return;
      if (tokenDocs[index]) invalidDocs.push(tokenDocs[index]);
    });
    await deleteRegistrationDocs(invalidDocs);

    return {
      sentCount: response.successCount,
      failedCount: response.failureCount,
    };
  }

  static async sendToRoles({ roles = [], title, body, data = {} }) {
    const normalizedRoles = Array.from(
      new Set(
        (Array.isArray(roles) ? roles : [roles])
          .map((role) => safeString(role).toLowerCase())
          .filter((role) => ["finder", "provider"].includes(role)),
      ),
    );
    if (normalizedRoles.length === 0) {
      return { sentCount: 0, failedCount: 0 };
    }

    const userIds = new Set();
    try {
      const rolesSnap = await db
        .collection("users")
        .where("roles", "array-contains-any", normalizedRoles)
        .get();
      rolesSnap.docs.forEach((doc) => userIds.add(doc.id));
    } catch (_) {}

    for (const role of normalizedRoles) {
      try {
        const roleSnap = await db.collection("users").where("role", "==", role).get();
        roleSnap.docs.forEach((doc) => userIds.add(doc.id));
      } catch (_) {}
    }

    let sentCount = 0;
    let failedCount = 0;
    for (const uid of userIds) {
      const result = await this.sendToUser({
        uid,
        title,
        body,
        data,
      });
      sentCount += result.sentCount ?? 0;
      failedCount += result.failedCount ?? 0;
    }
    return { sentCount, failedCount };
  }
}

export default PushService;
