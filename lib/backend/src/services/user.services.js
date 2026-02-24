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
    return Math.min(maxLimit, page * limit + 1);
}

function normalizePagination(pagination, maxLimit) {
    return {
        page: Math.max(1, Number.parseInt((pagination?.page ?? 1).toString(), 10) || 1),
        limit: Math.min(
            maxLimit,
            Math.max(1, Number.parseInt((pagination?.limit ?? 10).toString(), 10) || 10),
        ),
        cursor: (pagination?.cursor ?? "").toString().trim(),
    };
}

async function applyCollectionCursor(query, collectionRef, cursor) {
    const cursorId = (cursor || "").toString().trim();
    if (!cursorId) return query;
    const snap = await collectionRef.doc(cursorId).get();
    if (!snap.exists) return query;
    return query.startAfter(snap);
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

function normalizePaymentMethod(value) {
    const method = safeString(value).toLowerCase();
    if (method === "bank_account" || method === "bank account") {
        return "credit_card";
    }
    if (["credit_card", "cash", "khqr"].includes(method)) {
        return method;
    }
    return "credit_card";
}

function normalizeOrderStatus(value) {
    const status = safeString(value).toLowerCase();
    if ([
        "booked",
        "on_the_way",
        "started",
        "completed",
        "cancelled",
        "declined",
    ].includes(status)) {
        return status;
    }
    return "booked";
}

function timelineFieldForStatus(status) {
    switch (status) {
        case "on_the_way":
            return "onTheWayAt";
        case "started":
            return "startedAt";
        case "completed":
            return "completedAt";
        case "cancelled":
            return "cancelledAt";
        case "declined":
            return "declinedAt";
        case "booked":
        default:
            return "bookedAt";
    }
}

function orderStatusEventMillis(row, status) {
    const timeline = row?.statusTimeline && typeof row.statusTimeline === "object"
        ? row.statusTimeline
        : {};
    const field = timelineFieldForStatus(status);
    return (
        toMillis(timeline[field]) ||
        toMillis(row?.updatedAt) ||
        toMillis(row?.createdAt)
    );
}

function orderStatusTitle(status) {
    switch (status) {
        case "on_the_way":
            return "Provider On The Way";
        case "started":
            return "Service Started";
        case "completed":
            return "Order Completed";
        case "cancelled":
            return "Order Cancelled";
        case "declined":
            return "Order Declined";
        case "booked":
        default:
            return "Order Booked";
    }
}

function orderStatusMessage(row, status, role) {
    const serviceName = safeString(row?.serviceName) || "service";
    const providerName = safeString(row?.providerName) || "Provider";
    if (role === "provider") {
        switch (status) {
            case "booked":
                return `New booking received for ${serviceName}.`;
            case "on_the_way":
                return `You are on the way for ${serviceName}.`;
            case "started":
                return `Service started for ${serviceName}.`;
            case "completed":
                return `Service completed for ${serviceName}.`;
            case "cancelled":
                return `Finder cancelled ${serviceName}.`;
            case "declined":
                return `You declined ${serviceName}.`;
            default:
                return `Order status updated for ${serviceName}.`;
        }
    }

    switch (status) {
        case "booked":
            return `Your booking for ${serviceName} is confirmed.`;
        case "on_the_way":
            return `${providerName} is on the way for ${serviceName}.`;
        case "started":
            return `${providerName} started ${serviceName}.`;
        case "completed":
            return `${serviceName} has been completed.`;
        case "cancelled":
            return `Your booking for ${serviceName} was cancelled.`;
        case "declined":
            return `Your booking for ${serviceName} was declined.`;
        default:
            return `Order status updated for ${serviceName}.`;
    }
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
        const merged = { ...defaults, ...snap.data() };
        return {
            data: {
                ...merged,
                paymentMethod: normalizePaymentMethod(merged.paymentMethod),
            },
        };
    }

    static async getNotifications(uid, pagination, filters = {}) {
        const requestedRole = normalizeRole(filters.role);
        const typeFilter = (filters.type || "").toString().trim().toLowerCase();
        const query = safeString(filters.q || filters.query).toLowerCase();
        const normalized = normalizePagination(pagination, MAX_NOTIFICATION_SCAN);
        const queryLimit = readWindow(pagination, MAX_NOTIFICATION_SCAN);
        const includeOrderNotices = !["promo", "promos", "promotion"].includes(
            typeFilter,
        );

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
        const canUseCursor =
            !includeOrderNotices &&
            (!typeFilter || typeFilter === "all") &&
            !query &&
            (normalized.page === 1 || Boolean(normalized.cursor));

        let snap;
        if (canUseCursor) {
            const collectionRef = db.collection("adminBroadcasts");
            const fetchLimit = normalized.cursor ? normalized.limit + 1 : normalized.limit;
            try {
                let queryRef = collectionRef.where("targetRoles", "array-contains", role);
                queryRef = await applyCollectionCursor(queryRef, collectionRef, normalized.cursor);
                snap = await queryRef.limit(fetchLimit).get();
            } catch (_) {
                let queryRef = collectionRef;
                queryRef = await applyCollectionCursor(queryRef, collectionRef, normalized.cursor);
                snap = await queryRef.limit(fetchLimit).get();
            }
        } else {
            try {
                snap = await db
                    .collection("adminBroadcasts")
                    .where("targetRoles", "array-contains", role)
                    .limit(queryLimit)
                    .get();
            } catch (_) {
                snap = await db.collection("adminBroadcasts").limit(queryLimit).get();
            }
        }

        const now = Date.now();
        let sourceDocs = snap.docs;
        if (canUseCursor && normalized.cursor && sourceDocs.length > normalized.limit) {
            sourceDocs = sourceDocs.slice(0, normalized.limit);
        }
        const items = sourceDocs
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

        if (includeOrderNotices) {
            const orderItems = await this._buildOrderStatusNotifications({
                uid,
                role,
                limit: queryLimit,
                query,
            });
            const mergedItems = [...items, ...orderItems].sort(
                (a, b) => toMillis(b.createdAt) - toMillis(a.createdAt),
            );
            const paged = paginateArray(mergedItems, pagination);
            return { data: paged.items, pagination: paged.pagination };
        }

        if (canUseCursor) {
            const hasNextPage = normalized.cursor
                ? snap.docs.length > normalized.limit
                : snap.docs.length >= normalized.limit;
            return {
                data: items,
                pagination: {
                    page: normalized.page,
                    limit: normalized.limit,
                    totalItems: items.length + (hasNextPage ? 1 : 0),
                    totalPages: hasNextPage ? normalized.page + 1 : normalized.page,
                    hasPrevPage: Boolean(normalized.cursor) || normalized.page > 1,
                    hasNextPage,
                    nextCursor:
                        hasNextPage && sourceDocs.length > 0
                            ? sourceDocs[sourceDocs.length - 1].id
                            : "",
                },
            };
        }
        const paged = paginateArray(items, pagination);
        return { data: paged.items, pagination: paged.pagination };
    }

    static async _buildOrderStatusNotifications({ uid, role, limit, query }) {
        const ownerField = role === "provider" ? "providerUid" : "finderUid";
        const snap = await db
            .collection("orders")
            .where(ownerField, "==", uid)
            .limit(limit)
            .get();
        const loweredQuery = safeString(query).toLowerCase();
        return snap.docs
            .map((doc) => {
                const row = doc.data() || {};
                const status = normalizeOrderStatus(row.status);
                const eventMillis = orderStatusEventMillis(row, status);
                if (eventMillis <= 0) return null;
                const item = {
                    id: `order_status_${doc.id}_${status}_${eventMillis}`,
                    type: "system",
                    source: "order_status",
                    orderId: doc.id,
                    orderStatus: status,
                    title: orderStatusTitle(status),
                    message: orderStatusMessage(row, status, role),
                    promoCode: "",
                    promoCodeId: "",
                    targetRoles: [role],
                    lifecycle: "active",
                    active: true,
                    createdAt: new Date(eventMillis).toISOString(),
                    updatedAt: toIso(row.updatedAt),
                    startAt: null,
                    endAt: null,
                };
                if (!loweredQuery) return item;
                const haystack = [
                    item.id,
                    item.title,
                    item.message,
                    item.orderId,
                    item.orderStatus,
                    safeString(row.serviceName),
                ]
                    .map((value) => safeString(value).toLowerCase())
                    .join(" ");
                return haystack.includes(loweredQuery) ? item : null;
            })
            .filter(Boolean)
            .sort((a, b) => toMillis(b.createdAt) - toMillis(a.createdAt));
    }

    static async updateSettings(uid, payload) {
        const settingsRef = db.collection("users").doc(uid).collection("app").doc("settings");
        const current = (await this.getSettings(uid)).data;
        const updated = {
            paymentMethod: normalizePaymentMethod(
                payload.paymentMethod ?? current.paymentMethod ?? "credit_card",
            ),
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
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        if (payload.name !== undefined) {
            const name = (payload.name ?? '').toString().trim();
            if (name) updatePayload.name = name;
        }
        if (payload.email !== undefined) {
            const email = (payload.email ?? '').toString().trim();
            if (email) updatePayload.email = email;
        }
        if (payload.photoUrl !== undefined) {
            const photoUrl = (payload.photoUrl ?? '').toString().trim();
            updatePayload.photoUrl = photoUrl
                ? photoUrl
                : admin.firestore.FieldValue.delete();
        }
        if (Object.keys(updatePayload).length > 0) {
            await userRef.update(updatePayload);
        }
        const updated = await userRef.get();
        return { data: updated.data() };
    }

    static async getHelpTickets(uid, pagination) {
        const ticketsRef = db.collection("users").doc(uid).collection("helpTickets");
        const normalized = normalizePagination(pagination, MAX_TICKET_SCAN);
        const canUseCursor = normalized.page === 1 || Boolean(normalized.cursor);
        if (canUseCursor) {
            let queryRef = ticketsRef.orderBy("createdAt", "desc");
            queryRef = await applyCollectionCursor(queryRef, ticketsRef, normalized.cursor);
            const fetchLimit = normalized.cursor ? normalized.limit + 1 : normalized.limit;
            const snap = await queryRef.limit(fetchLimit).get();
            let docs = snap.docs;
            const hasNextPage = normalized.cursor
                ? docs.length > normalized.limit
                : docs.length >= normalized.limit;
            if (normalized.cursor && docs.length > normalized.limit) {
                docs = docs.slice(0, normalized.limit);
            }
            const items = docs.map((doc) => ({ id: doc.id, ...doc.data() }));
            return {
                data: items,
                pagination: {
                    page: normalized.page,
                    limit: normalized.limit,
                    totalItems: items.length + (hasNextPage ? 1 : 0),
                    totalPages: hasNextPage ? normalized.page + 1 : normalized.page,
                    hasPrevPage: Boolean(normalized.cursor) || normalized.page > 1,
                    hasNextPage,
                    nextCursor: hasNextPage && docs.length > 0 ? docs[docs.length - 1].id : "",
                },
            };
        }
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
        const normalized = normalizePagination(pagination, MAX_TICKET_MESSAGES_SCAN);
        const canUseCursor = normalized.page === 1 || Boolean(normalized.cursor);
        if (canUseCursor) {
            const messagesRef = ticketRef.collection("messages");
            let queryRef = messagesRef.orderBy("createdAt", "desc");
            queryRef = await applyCollectionCursor(queryRef, messagesRef, normalized.cursor);
            const fetchLimit = normalized.cursor ? normalized.limit + 1 : normalized.limit;
            const snap = await queryRef.limit(fetchLimit).get();
            let docs = snap.docs;
            const hasNextPage = normalized.cursor
                ? docs.length > normalized.limit
                : docs.length >= normalized.limit;
            if (normalized.cursor && docs.length > normalized.limit) {
                docs = docs.slice(0, normalized.limit);
            }
            const items = docs.map((doc) => {
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
            const ordered = [...items].sort(
                (a, b) => toMillis(a.createdAt) - toMillis(b.createdAt),
            );
            return {
                data: ordered,
                pagination: {
                    page: normalized.page,
                    limit: normalized.limit,
                    totalItems: ordered.length + (hasNextPage ? 1 : 0),
                    totalPages: hasNextPage ? normalized.page + 1 : normalized.page,
                    hasPrevPage: Boolean(normalized.cursor) || normalized.page > 1,
                    hasNextPage,
                    nextCursor: hasNextPage && docs.length > 0 ? docs[docs.length - 1].id : "",
                },
            };
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
