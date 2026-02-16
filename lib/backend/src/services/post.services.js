import admin from "firebase-admin";
import { db } from "../config/firebase.js";
import { paginateArray } from "../utils/pagination.util.js";

class PostService {
  static async createFinderRequest(uid, user, payload) {
    const finderRef = db.collection("finders").doc(uid);
    const finderSnap = await finderRef.get();
    const finderData = finderSnap.exists ? finderSnap.data() : {};
    const userSnap = await db.collection("users").doc(uid).get();
    const userData = userSnap.exists ? userSnap.data() : {};
    const payloadLocation = (payload.location || "").toString().trim();
    const profileCity = (finderData?.city || "").toString().trim();
    const profileLocation = (finderData?.location || "").toString().trim();
    const resolvedLocation =
      payloadLocation || profileLocation || profileCity || "Phnom Penh, Cambodia";
    const clientName =
      (userData?.name || user?.name || "Finder User").toString().trim() || "Finder User";

    const docRef = db.collection("finderPosts").doc();
    const now = admin.firestore.FieldValue.serverTimestamp();
    const item = {
      id: docRef.id,
      finderUid: uid,
      clientName,
      clientAvatarUrl: user?.picture || "",
      category: payload.category.toString().trim(),
      service: payload.service.toString().trim(),
      location: resolvedLocation,
      message: payload.message.toString().trim(),
      preferredDate: payload.preferredDate
        ? new Date(payload.preferredDate).toISOString()
        : null,
      status: "open",
      createdAt: now,
      updatedAt: now,
    };
    await docRef.set(item);
    await finderRef.set(
      {
        city: resolvedLocation,
        location: resolvedLocation,
      },
      { merge: true },
    );
    return { data: item };
  }

  static async getFinderRequests(pagination) {
    const snap = await db
      .collection("finderPosts")
      .orderBy("createdAt", "desc")
      .limit(500)
      .get();
    if (snap.empty) {
      const paged = paginateArray([], pagination);
      return { data: paged.items, pagination: paged.pagination };
    }

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
      .filter((item) => item.status === "open");
    const paged = paginateArray(items, pagination);
    return { data: paged.items, pagination: paged.pagination };
  }

  static async createProviderOffer(uid, user, payload) {
    const docRef = db.collection("providerPosts").doc();
    const now = admin.firestore.FieldValue.serverTimestamp();
    const item = {
      id: docRef.id,
      providerUid: uid,
      providerName: user?.name || "Service Provider",
      providerAvatarUrl: user?.picture || "",
      category: payload.category.toString().trim(),
      service: payload.service.toString().trim(),
      area: payload.area.toString().trim(),
      details: payload.details.toString().trim(),
      ratePerHour: Number(payload.ratePerHour || 0),
      availableNow: payload.availableNow === true,
      status: "open",
      createdAt: now,
      updatedAt: now,
    };
    await docRef.set(item);
    return { data: item };
  }

  static async getProviderOffers(pagination) {
    const snap = await db
      .collection("providerPosts")
      .orderBy("createdAt", "desc")
      .limit(500)
      .get();
    if (snap.empty) {
      const paged = paginateArray([], pagination);
      return { data: paged.items, pagination: paged.pagination };
    }

    const items = snap.docs
      .map((doc) => {
        const row = doc.data();
        return {
          id: doc.id,
          providerUid: row.providerUid || "",
          providerName: row.providerName || "Service Provider",
          providerAvatarUrl: row.providerAvatarUrl || "",
          category: row.category || "",
          service: row.service || "",
          area: row.area || "",
          details: row.details || "",
          ratePerHour: Number(row.ratePerHour || 0),
          availableNow: row.availableNow === true,
          status: row.status || "open",
          createdAt: row.createdAt || null,
        };
      })
      .filter((item) => item.status === "open");
    const paged = paginateArray(items, pagination);
    return { data: paged.items, pagination: paged.pagination };
  }
}

export default PostService;
