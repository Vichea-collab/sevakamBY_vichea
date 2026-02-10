import admin from "firebase-admin";
import { db } from "../config/firebase.js";

class PostService {
  static async createFinderRequest(uid, user, payload) {
    const docRef = db.collection("finderPosts").doc();
    const now = admin.firestore.FieldValue.serverTimestamp();
    const item = {
      id: docRef.id,
      finderUid: uid,
      clientName: user?.name || "Finder User",
      clientAvatarUrl: user?.picture || "",
      category: payload.category.toString().trim(),
      service: payload.service.toString().trim(),
      location: payload.location.toString().trim(),
      message: payload.message.toString().trim(),
      preferredDate: payload.preferredDate
        ? new Date(payload.preferredDate).toISOString()
        : null,
      status: "open",
      createdAt: now,
      updatedAt: now,
    };
    await docRef.set(item);
    return { data: item };
  }

  static async getFinderRequests() {
    const snap = await db
      .collection("finderPosts")
      .orderBy("createdAt", "desc")
      .limit(80)
      .get();
    if (snap.empty) return { data: [] };

    const items = snap.docs
      .map((doc) => {
      const row = doc.data();
      return {
        id: doc.id,
        finderUid: row.finderUid || "",
        clientName: row.clientName || "Finder User",
        clientAvatarUrl: row.clientAvatarUrl || "",
        category: row.category || "",
        service: row.service || "",
        location: row.location || "",
        message: row.message || "",
        preferredDate: row.preferredDate || null,
        status: row.status || "open",
        createdAt: row.createdAt || null,
      };
      })
      .filter((item) => item.status === "open")
      .slice(0, 50);
    return { data: items };
  }
}

export default PostService;
