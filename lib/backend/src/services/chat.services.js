import admin from "firebase-admin";
import { db } from "../config/firebase.js";

const CHAT_COLLECTION = "chats";
const MAX_MESSAGES = 120;

function normalizeRole(value) {
  const role = (value || "").toString().trim().toLowerCase();
  if (role === "providers") return "provider";
  if (role === "finders") return "finder";
  return role;
}

function safeString(value, fallback = "") {
  const text = (value ?? "").toString().trim();
  return text.length === 0 ? fallback : text;
}

function directChatId(uidA, uidB) {
  const ids = [uidA.toString().trim(), uidB.toString().trim()].sort();
  return `direct_${ids[0]}_${ids[1]}`;
}

function toIsoDate(value) {
  if (!value) return new Date().toISOString();
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
    const parsed = new Date(Number(value._seconds) * 1000);
    if (!Number.isNaN(parsed.getTime())) return parsed.toISOString();
  }
  return new Date().toISOString();
}

function toInt(value, fallback = 0) {
  if (typeof value === "number" && Number.isFinite(value)) {
    return Math.round(value);
  }
  if (typeof value === "string") {
    const parsed = Number.parseInt(value, 10);
    if (Number.isFinite(parsed)) return parsed;
  }
  return fallback;
}

function mapThreadDoc(doc, currentUid) {
  const row = doc.data() || {};
  const participants = Array.isArray(row.participants)
    ? row.participants.map((value) => (value || "").toString().trim()).filter(Boolean)
    : [];
  if (!participants.includes(currentUid)) return null;

  const peerUid = participants.find((uid) => uid !== currentUid) || "";
  const participantMeta =
    row.participantMeta && typeof row.participantMeta === "object"
      ? row.participantMeta
      : {};
  const peerMeta =
    peerUid && participantMeta[peerUid] && typeof participantMeta[peerUid] === "object"
      ? participantMeta[peerUid]
      : {};
  const unreadCounts =
    row.unreadCounts && typeof row.unreadCounts === "object" ? row.unreadCounts : {};

  return {
    id: doc.id,
    title: safeString(peerMeta.name, "Chat"),
    subtitle: safeString(row.lastMessageText, "Start conversation"),
    avatarPath: "assets/images/profile.jpg",
    updatedAt: toIsoDate(row.lastMessageAt || row.updatedAt || row.createdAt),
    unreadCount: toInt(unreadCounts[currentUid], 0),
    peerUid,
  };
}

function mapMessageDoc(doc) {
  const row = doc.data() || {};
  return {
    id: doc.id,
    text: safeString(row.text),
    senderUid: safeString(row.senderUid),
    senderName: safeString(row.senderName, "User"),
    sentAt: toIsoDate(row.sentAt || row.createdAt),
  };
}

async function ensureChatParticipant(uid, threadId) {
  const chatRef = db.collection(CHAT_COLLECTION).doc(threadId);
  const chatSnap = await chatRef.get();
  if (!chatSnap.exists) {
    const error = new Error("chat not found");
    error.status = 404;
    throw error;
  }
  const row = chatSnap.data() || {};
  const participants = Array.isArray(row.participants)
    ? row.participants.map((value) => (value || "").toString().trim()).filter(Boolean)
    : [];
  if (!participants.includes(uid)) {
    const error = new Error("forbidden");
    error.status = 403;
    throw error;
  }
  return { chatRef, chatSnap, participants };
}

class ChatService {
  static async listThreads(uid) {
    const snap = await db
      .collection(CHAT_COLLECTION)
      .where("participants", "array-contains", uid)
      .limit(120)
      .get();

    const threads = snap.docs
      .map((doc) => mapThreadDoc(doc, uid))
      .filter(Boolean)
      .sort((a, b) => {
        const aTime = new Date(a.updatedAt).getTime();
        const bTime = new Date(b.updatedAt).getTime();
        return bTime - aTime;
      });
    return { data: threads };
  }

  static async openDirectThread(uid, user, payload) {
    const peerUid = safeString(payload.peerUid);
    if (!peerUid) {
      const error = new Error("peerUid is required");
      error.status = 400;
      throw error;
    }
    if (peerUid === uid) {
      const error = new Error("Cannot chat with yourself");
      error.status = 400;
      throw error;
    }

    const chatId = directChatId(uid, peerUid);
    const chatRef = db.collection(CHAT_COLLECTION).doc(chatId);
    const chatSnap = await chatRef.get();
    const exists = chatSnap.exists;

    const selfRole = normalizeRole(payload.selfRole || user?.role);
    const selfName = safeString(payload.selfName || user?.name, "User");
    const peerName = safeString(payload.peerName, "User");
    const now = admin.firestore.FieldValue.serverTimestamp();
    const peerIsProvider = payload.peerIsProvider === true;

    if (!exists) {
      await chatRef.set({
        id: chatId,
        kind: "direct",
        participants: [uid, peerUid],
        participantMeta: {
          [uid]: {
            name: selfName,
            role: selfRole === "provider" ? "provider" : "finder",
            avatarPath: "assets/images/profile.jpg",
          },
          [peerUid]: {
            name: peerName,
            role: peerIsProvider ? "provider" : "finder",
            avatarPath: "assets/images/profile.jpg",
          },
        },
        unreadCounts: {
          [uid]: 0,
          [peerUid]: 0,
        },
        lastMessageText: "",
        lastSenderUid: "",
        createdAt: now,
        updatedAt: now,
        lastMessageAt: now,
      });

      const starterText = safeString(
        payload.starterText,
        peerIsProvider
          ? `Hi ${peerName}, I want to discuss your service.`
          : `Hi ${peerName}, I can help with your request.`,
      );
      const msgRef = chatRef.collection("messages").doc();
      await msgRef.set({
        id: msgRef.id,
        text: starterText,
        senderUid: uid,
        senderName: selfName,
        sentAt: now,
        seenBy: [uid],
      });
      await chatRef.set(
        {
          lastMessageText: starterText,
          lastSenderUid: uid,
          lastMessageAt: now,
          updatedAt: now,
          unreadCounts: {
            [uid]: 0,
            [peerUid]: 1,
          },
        },
        { merge: true },
      );
    } else {
      await chatRef.set(
        {
          id: chatId,
          kind: "direct",
          participants: [uid, peerUid],
          [`participantMeta.${uid}`]: {
            name: selfName,
            role: selfRole === "provider" ? "provider" : "finder",
            avatarPath: "assets/images/profile.jpg",
          },
          [`participantMeta.${peerUid}`]: {
            name: peerName,
            role: peerIsProvider ? "provider" : "finder",
            avatarPath: "assets/images/profile.jpg",
          },
          [`unreadCounts.${uid}`]: 0,
          updatedAt: now,
        },
        { merge: true },
      );
    }

    const finalSnap = await chatRef.get();
    const thread = mapThreadDoc(finalSnap, uid);
    return { data: thread };
  }

  static async listMessages(uid, threadId) {
    const { chatRef } = await ensureChatParticipant(uid, threadId);
    const snap = await chatRef
      .collection("messages")
      .orderBy("sentAt", "desc")
      .limit(MAX_MESSAGES)
      .get();
    const items = snap.docs.map(mapMessageDoc).reverse();
    return { data: items };
  }

  static async sendMessage(uid, user, threadId, payload) {
    const text = safeString(payload.text);
    if (!text) {
      const error = new Error("text is required");
      error.status = 400;
      throw error;
    }
    const { chatRef, participants } = await ensureChatParticipant(uid, threadId);
    const msgRef = chatRef.collection("messages").doc();
    const now = admin.firestore.FieldValue.serverTimestamp();
    const senderName = safeString(payload.senderName || user?.name, "User");
    await msgRef.set({
      id: msgRef.id,
      text,
      senderUid: uid,
      senderName,
      sentAt: now,
      seenBy: [uid],
    });

    const unreadUpdates = { [`unreadCounts.${uid}`]: 0 };
    for (const participantUid of participants) {
      if (participantUid && participantUid !== uid) {
        unreadUpdates[`unreadCounts.${participantUid}`] = admin.firestore.FieldValue.increment(1);
      }
    }

    await chatRef.set(
      {
        lastMessageText: text,
        lastSenderUid: uid,
        lastMessageAt: now,
        updatedAt: now,
        ...unreadUpdates,
      },
      { merge: true },
    );

    const finalMessage = await msgRef.get();
    return { data: mapMessageDoc(finalMessage) };
  }

  static async markAsRead(uid, threadId) {
    const { chatRef } = await ensureChatParticipant(uid, threadId);
    await chatRef.set(
      {
        [`unreadCounts.${uid}`]: 0,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    return { data: { threadId, unreadCount: 0 } };
  }
}

export default ChatService;
