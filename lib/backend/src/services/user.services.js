import admin from "firebase-admin";
import { db } from "../config/firebase.js";
import { paginateArray } from "../utils/pagination.util.js";

const MAX_TICKET_SCAN = 120;
const MAX_TICKET_MESSAGES_SCAN = 200;
const MAX_ADDRESS_SCAN = 100;
const MAX_NOTIFICATION_SCAN = 200;

function readWindow(pagination, maxLimit) {
    const page = Math.max(1, Number.parseInt((pagination?.page ?? 1).toString(), 10) || 1);
    const limit = Math.max(1, Number.parseInt((pagination?.limit ?? 10).toString(), 10) || 10);
    return Math.min(maxLimit, page * limit + limit);
}

function safeString(value) {
    return (value ?? "").toString().trim();
}

function toMillis(value) {
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

function toIso(value) {
    const millis = toMillis(value);
    if (millis <= 0) return null;
    return new Date(millis).toISOString();
}

function normalizeRole(value) {
    const role = (value || "").toString().trim().toLowerCase();
    if (role === "providers") return "provider";
    if (role === "finders") return "finder";
    return role;
}

function normalizeRoleList(value, fallback = ["finder", "provider"]) {
    const source = Array.isArray(value)
        ? value
        : typeof value === "string"
            ? value.split(",")
            : [];
    const normalized = Array.from(
        new Set(
            source
                .map((entry) => normalizeRole(entry))
                .filter((entry) => ["finder", "provider"].includes(entry)),
        ),
    );
    return normalized.length > 0 ? normalized : fallback;
}

function normalizeNotificationType(value) {
    const normalized = (value || "").toString().trim().toLowerCase();
    if (normalized === "promotion" || normalized === "promo") return "promotion";
    return "system";
}

function normalizeLifecycle(value) {
    const normalized = (value || "").toString().trim().toLowerCase();
    if (["active", "scheduled", "expired", "inactive"].includes(normalized)) {
        return normalized;
    }
    return "active";
}

class UserService {
    static async _resolveUserMeta(uid) {
        const userSnap = await db.collection("users").doc(uid).get();
        const row = userSnap.exists ? (userSnap.data() || {}) : {};
        const roleRaw = safeString(row.role).toLowerCase();
        const role = roleRaw === "provider" ? "provider" : "finder";
        return {
            name: safeString(row.name) || "User",
            role,
        };
    }

    static async initUser(user, role) {
        if (!["finder", "provider"].includes(role)) {
            const e = new Error("role must be finder or provider");
            e.status = 400;
            throw e;
        }

        const userRef = db.collection("users").doc(user.uid);
        const userSnap = await userRef.get();

        const existingUser = userSnap.exists ? userSnap.data() : {};
        const roleSet = new Set();
        if (existingUser?.role) {
            roleSet.add(existingUser.role.toString().toLowerCase());
        }
        if (Array.isArray(existingUser?.roles)) {
            existingUser.roles.forEach((value) => {
                if (value) roleSet.add(value.toString().toLowerCase());
            });
        }
        roleSet.add(role);
        const roles = Array.from(roleSet).filter((value) =>
            ["finder", "provider"].includes(value)
        );

        //  Role-specific doc
        const roleRef = role === "provider"
            ? db.collection("providers").doc(user.uid)
            : db.collection("finders").doc(user.uid);
        const roleSnap = await roleRef.get();
        const rolePayload = role === "provider"
            ? {
                bio: "",
                phoneNumber: "",
                PhotoUrl: user.picture ?? "",
                ratePerHour: 0,
                city: "",
                location: null,
                serviceId: "",
                serviceName: "",
                serviceImageUrl: "",
                expertIn: "",
                availableFrom: "",
                availableTo: "",
                experienceYears: "",
                serviceArea: "",
                birthday: null,
                ratingCount: 0,
                ratingSum: 0,
                activeOrder: 0,
                completedOrder: 0,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            }
            : {
                city: "",
                PhotoUrl: user.picture ?? "",
                phoneNumber: "",
                birthday: null,
                location: null,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            };

        //  Common user doc
        const userPayload = {
            name: user.name || existingUser?.name || "",
            email: user.email || existingUser?.email || "",
            role,
            roles,
            photoUrl: user.picture || existingUser?.photoUrl || "",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        if (!userSnap.exists) {
            userPayload.createdAt = admin.firestore.FieldValue.serverTimestamp();
        }

        const batch = db.batch();
        batch.set(userRef, userPayload, { merge: true });
        if (!roleSnap.exists) {
            batch.set(roleRef, rolePayload, { merge: true });
        }
        await batch.commit();

        try {
            await admin.auth().setCustomUserClaims(user.uid, { role, roles });
        } catch (_) {}

        return { 
            data: { 
                user: userPayload, 
                roleData: roleSnap.exists ? roleSnap.data() : rolePayload,
                roles,
            },
        };
    }

    static async getSettings(uid) {
        const settingsRef = db.collection("users").doc(uid).collection("app").doc("settings");
        const snap = await settingsRef.get();
        const defaults = {
            paymentMethod: "credit_card",
            notifications: {
                general: true,
                sound: false,
                vibrate: true,
                newService: false,
                payment: true,
            },
        };
        if (!snap.exists) return { data: defaults };
        return { data: { ...defaults, ...snap.data() } };
    }

    static async getNotifications(uid, pagination, filters = {}) {
        const requestedRole = normalizeRole(filters.role);
        const typeFilter = (filters.type || "").toString().trim().toLowerCase();
        const query = safeString(filters.q || filters.query).toLowerCase();
        const queryLimit = readWindow(pagination, MAX_NOTIFICATION_SCAN);

        const userSnap = await db.collection("users").doc(uid).get();
        const userRow = userSnap.exists ? (userSnap.data() || {}) : {};
        const userRoles = normalizeRoleList(userRow.roles, [
            normalizeRole(userRow.role) || "finder",
        ]);
        const role = ["finder", "provider"].includes(requestedRole)
            ? requestedRole
            : userRoles.includes("provider") && !userRoles.includes("finder")
                ? "provider"
                : "finder";

        let snap;
        try {
            snap = await db
                .collection("adminBroadcasts")
                .where("targetRoles", "array-contains", role)
                .limit(queryLimit)
                .get();
        } catch (_) {
            snap = await db.collection("adminBroadcasts").limit(queryLimit).get();
        }

        const now = Date.now();
        const items = snap.docs
            .map((doc) => {
                const row = doc.data() || {};
                const roles = normalizeRoleList(row.targetRoles);
                if (!roles.includes(role)) return null;

                const type = normalizeNotificationType(row.type);
                const active = row.active !== false;
                const startAt = toIso(row.startAt);
                const endAt = toIso(row.endAt);
                const startMillis = toMillis(row.startAt);
                const endMillis = toMillis(row.endAt);
                let lifecycle = "active";
                if (!active) {
                    lifecycle = "inactive";
                } else if (startMillis > 0 && now < startMillis) {
                    lifecycle = "scheduled";
                } else if (endMillis > 0 && now > endMillis) {
                    lifecycle = "expired";
                }

                return {
                    id: doc.id,
                    type,
                    title: safeString(row.title) || "Platform update",
                    message: safeString(row.message),
                    promoCode: safeString(row.promoCode).toUpperCase(),
                    promoCodeId: safeString(row.promoCodeId),
                    targetRoles: roles,
                    lifecycle: normalizeLifecycle(lifecycle),
                    active,
                    createdAt: toIso(row.createdAt),
                    updatedAt: toIso(row.updatedAt),
                    startAt,
                    endAt,
                };
            })
            .filter(Boolean)
            .filter((item) => {
                if (typeFilter && typeFilter !== "all") {
                    if (typeFilter === "promos" || typeFilter === "promo") {
                        if (item.type !== "promotion") return false;
                    } else if (typeFilter === "system") {
                        if (item.type !== "system") return false;
                    }
                }
                if (!query) return true;
                return [item.id, item.title, item.message, item.type, item.promoCode]
                    .map((value) => safeString(value).toLowerCase())
                    .join(" ")
                    .includes(query);
            })
            .sort((a, b) => toMillis(b.createdAt) - toMillis(a.createdAt));

        const paged = paginateArray(items, pagination);
        return { data: paged.items, pagination: paged.pagination };
    }

    static async updateSettings(uid, payload) {
        const settingsRef = db.collection("users").doc(uid).collection("app").doc("settings");
        const current = (await this.getSettings(uid)).data;
        const updated = {
            paymentMethod: (payload.paymentMethod ?? current.paymentMethod ?? "credit_card").toString(),
            notifications: {
                ...current.notifications,
                ...(payload.notifications || {}),
            },
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        await settingsRef.set(updated, { merge: true });
        return { data: updated };
    }

    static async updateUserProfile(uid, payload) {
        const userRef = db.collection("users").doc(uid);
        const userSnap = await userRef.get();
        if (!userSnap.exists) {
            const e = new Error("user not found");
            e.status = 404;
            throw e;
        }

        const updatePayload = {
            name: (payload.name ?? '').toString(),
            email: (payload.email ?? '').toString(),
            photoUrl: (payload.photoUrl ?? '').toString(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        Object.keys(updatePayload).forEach((key) => {
            if (updatePayload[key] === '') {
                delete updatePayload[key];
            }
        });
        if (Object.keys(updatePayload).length > 0) {
            await userRef.update(updatePayload);
        }
        const updated = await userRef.get();
        return { data: updated.data() };
    }

    static async getHelpTickets(uid, pagination) {
        const ticketsRef = db.collection("users").doc(uid).collection("helpTickets");
        const snap = await ticketsRef
            .orderBy("createdAt", "desc")
            .limit(readWindow(pagination, MAX_TICKET_SCAN))
            .get();
        if (snap.empty) {
            const paged = paginateArray([], pagination);
            return { data: paged.items, pagination: paged.pagination };
        }
        const items = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
        const paged = paginateArray(items, pagination);
        return { data: paged.items, pagination: paged.pagination };
    }

    static async createHelpTicket(uid, payload) {
        const ticketsRef = db.collection("users").doc(uid).collection("helpTickets");
        const docRef = ticketsRef.doc();
        const message = safeString(payload.message);
        const title = safeString(payload.title);
        const userMeta = await this._resolveUserMeta(uid);
        const item = {
            title,
            message,
            status: "open",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            lastMessageText: message,
            lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        const firstMessageRef = docRef.collection("messages").doc();
        await db.runTransaction(async (tx) => {
            tx.set(docRef, item);
            tx.set(firstMessageRef, {
                id: firstMessageRef.id,
                text: message,
                type: "text",
                senderUid: uid,
                senderRole: userMeta.role,
                senderName: userMeta.name,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        });
        return { data: { id: docRef.id, ...item } };
    }

    static async getHelpTicketMessages(uid, ticketId, pagination) {
        const ticketRef = db.collection("users").doc(uid).collection("helpTickets").doc(ticketId);
        const ticketSnap = await ticketRef.get();
        if (!ticketSnap.exists) {
            const error = new Error("help ticket not found");
            error.status = 404;
            throw error;
        }
        const snap = await ticketRef
            .collection("messages")
            .orderBy("createdAt", "desc")
            .limit(readWindow(pagination, MAX_TICKET_MESSAGES_SCAN))
            .get();
        if (snap.empty) {
            const paged = paginateArray([], pagination);
            return { data: paged.items, pagination: paged.pagination };
        }
        const items = snap.docs.map((doc) => {
            const row = doc.data() || {};
            return {
                id: doc.id,
                text: safeString(row.text),
                type: safeString(row.type) || "text",
                senderUid: safeString(row.senderUid),
                senderRole: safeString(row.senderRole) || "finder",
                senderName: safeString(row.senderName) || "User",
                createdAt: toIso(row.createdAt),
            };
        });
        const paged = paginateArray(items, pagination);
        const ordered = [...paged.items].sort(
            (a, b) => toMillis(a.createdAt) - toMillis(b.createdAt),
        );
        return { data: ordered, pagination: paged.pagination };
    }

    static async sendHelpTicketMessage(uid, ticketId, payload) {
        const text = safeString(payload.text || payload.message);
        if (!text) {
            const error = new Error("message text is required");
            error.status = 400;
            throw error;
        }
        const ticketRef = db.collection("users").doc(uid).collection("helpTickets").doc(ticketId);
        const ticketSnap = await ticketRef.get();
        if (!ticketSnap.exists) {
            const error = new Error("help ticket not found");
            error.status = 404;
            throw error;
        }
        const ticket = ticketSnap.data() || {};
        const status = safeString(ticket.status).toLowerCase();
        if (status === "closed") {
            const error = new Error("cannot send message to a closed ticket");
            error.status = 400;
            throw error;
        }

        const userMeta = await this._resolveUserMeta(uid);
        const messageRef = ticketRef.collection("messages").doc();
        const nextStatus = status === "resolved" ? "open" : (status || "open");
        const now = admin.firestore.FieldValue.serverTimestamp();
        await db.runTransaction(async (tx) => {
            tx.set(messageRef, {
                id: messageRef.id,
                text,
                type: "text",
                senderUid: uid,
                senderRole: userMeta.role,
                senderName: userMeta.name,
                createdAt: now,
            });
            tx.set(
                ticketRef,
                {
                    status: nextStatus,
                    updatedAt: now,
                    lastMessageText: text,
                    lastMessageAt: now,
                },
                { merge: true },
            );
        });
        return {
            data: {
                id: messageRef.id,
                text,
                type: "text",
                senderUid: uid,
                senderRole: userMeta.role,
                senderName: userMeta.name,
            },
        };
    }

    static async getAddresses(uid) {
        const addressesRef = db.collection("users").doc(uid).collection("addresses");
        const snap = await addressesRef
            .orderBy("updatedAt", "desc")
            .limit(MAX_ADDRESS_SCAN)
            .get();
        if (!snap.empty) {
            const items = snap.docs.map((doc) => {
                const row = doc.data() || {};
                return {
                    id: doc.id,
                    label: (row.label || "").toString(),
                    mapLink: (row.mapLink || "").toString(),
                    street: (row.street || "").toString(),
                    city: (row.city || "").toString(),
                    isDefault: row.isDefault === true,
                    createdAt: row.createdAt || null,
                    updatedAt: row.updatedAt || null,
                };
            });
            const sorted = items.sort((a, b) => {
                if (a.isDefault && !b.isDefault) return -1;
                if (!a.isDefault && b.isDefault) return 1;
                return 0;
            });
            return { data: sorted };
        }

        // Fallback for first-time users from finder profile location/city.
        const finderSnap = await db.collection("finders").doc(uid).get();
        if (!finderSnap.exists) return { data: [] };
        const finder = finderSnap.data() || {};
        const location = (finder.location || "").toString().trim();
        const city = (finder.city || "").toString().trim();
        const street = location || city;
        if (!street) return { data: [] };
        return {
            data: [
                {
                    id: "addr-home",
                    label: "Home",
                    mapLink: "",
                    street,
                    city: city || "Phnom Penh",
                    isDefault: true,
                    createdAt: null,
                    updatedAt: null,
                },
            ],
        };
    }

    static async createAddress(uid, payload) {
        const addressesRef = db.collection("users").doc(uid).collection("addresses");
        const docRef = addressesRef.doc();
        const now = admin.firestore.FieldValue.serverTimestamp();
        const item = {
            label: payload.label.toString().trim(),
            mapLink: (payload.mapLink || "").toString().trim(),
            street: payload.street.toString().trim(),
            city: payload.city.toString().trim(),
            isDefault: payload.isDefault === true,
            createdAt: now,
            updatedAt: now,
        };

        if (item.isDefault) {
            const existing = await addressesRef.where("isDefault", "==", true).get();
            if (!existing.empty) {
                const batch = db.batch();
                existing.docs.forEach((doc) => {
                    batch.update(doc.ref, {
                        isDefault: false,
                        updatedAt: now,
                    });
                });
                batch.set(docRef, item);
                await batch.commit();
            } else {
                await docRef.set(item);
            }
        } else {
            await docRef.set(item);
        }

        const created = await docRef.get();
        const row = created.data() || {};
        return {
            data: {
                id: docRef.id,
                label: (row.label || "").toString(),
                mapLink: (row.mapLink || "").toString(),
                street: (row.street || "").toString(),
                city: (row.city || "").toString(),
                isDefault: row.isDefault === true,
                createdAt: row.createdAt || null,
                updatedAt: row.updatedAt || null,
            },
        };
    }
}

export default UserService;
