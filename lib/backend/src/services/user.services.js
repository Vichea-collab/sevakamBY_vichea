import admin from "firebase-admin";
import { db } from "../config/firebase.js";
import { paginateArray } from "../utils/pagination.util.js";
import PushService from "./push.services.js";

const MAX_TICKET_SCAN = 120;
const MAX_TICKET_MESSAGES_SCAN = 200;
const MAX_ADDRESS_SCAN = 100;
const MAX_NOTIFICATION_SCAN = 200;
const MAX_NOTIFICATION_STATE_KEYS = 2000;
const MAX_PROMOTION_SCAN = 40;
const SUPPORT_TICKET_CATEGORY_OPTIONS = {
    payment_charge: {
        requestType: "support",
        allowedRoles: ["finder", "provider"],
        defaultSubcategory: "wrong_charge",
        subcategories: {
            wrong_charge: {
                priority: "high",
                autoReply:
                    "Thanks for reporting a billing issue. Please share your booking or payment ID, the charged amount, the correct amount, and a screenshot of the receipt so our admin team can review it quickly.",
            },
            double_charge: {
                priority: "high",
                autoReply:
                    "We can help check a duplicate payment. Please send both charge screenshots, payment date and time, and the related booking or subscription ID.",
            },
            paid_not_activated: {
                priority: "high",
                autoReply:
                    "Please send the payment screenshot, the plan name, your account email, and the time you completed payment. We will verify the activation status.",
            },
            refund_request: {
                priority: "normal",
                autoReply:
                    "Please explain why you are requesting a refund and include the booking or payment ID, amount paid, and any screenshots that support your request.",
            },
        },
    },
    provider_issue: {
        requestType: "support",
        allowedRoles: ["finder"],
        defaultSubcategory: "no_show",
        subcategories: {
            no_show: {
                priority: "high",
                autoReply:
                    "Please share the booking ID, provider name, scheduled time, and whether the provider contacted you before missing the booking.",
            },
            poor_service: {
                priority: "normal",
                autoReply:
                    "Please tell us what service was completed, what went wrong, and include any photos or screenshots if available.",
            },
            wrong_price: {
                priority: "high",
                autoReply:
                    "Please share the quoted price, the amount requested by the provider, the booking ID, and any chat or invoice screenshots.",
            },
            behavior_issue: {
                priority: "high",
                autoReply:
                    "Please describe what happened, when it happened, and include the provider name and booking ID so admin can review the case safely.",
            },
        },
    },
    finder_issue: {
        requestType: "support",
        allowedRoles: ["provider"],
        defaultSubcategory: "fake_booking",
        subcategories: {
            fake_booking: {
                priority: "high",
                autoReply:
                    "Please share the booking ID, the finder name, and what made the booking invalid or suspicious.",
            },
            communication_issue: {
                priority: "normal",
                autoReply:
                    "Please explain the communication problem and include the finder name, booking ID, and any screenshots if available.",
            },
            abusive_behavior: {
                priority: "high",
                autoReply:
                    "Please describe the behavior, when it happened, and attach screenshots if possible so the admin team can investigate.",
            },
            pricing_dispute: {
                priority: "normal",
                autoReply:
                    "Please share the booking ID, agreed amount, disputed amount, and any supporting screenshots from chat or quotation.",
            },
        },
    },
    booking_problem: {
        requestType: "support",
        allowedRoles: ["finder", "provider"],
        defaultSubcategory: "cannot_book",
        subcategories: {
            cannot_book: {
                priority: "high",
                autoReply:
                    "Please tell us which provider or service you were booking, what step failed, and include a screenshot of the error if possible.",
            },
            wrong_status: {
                priority: "normal",
                autoReply:
                    "Please share the booking ID and the status you expected versus the status currently shown in the app.",
            },
            schedule_issue: {
                priority: "normal",
                autoReply:
                    "Please share the booking ID, expected date and time, shown date and time, and any related screenshots.",
            },
            cancel_issue: {
                priority: "normal",
                autoReply:
                    "Please explain what happened when you tried to cancel and include the booking ID and current booking status.",
            },
        },
    },
    subscription_upgrade: {
        requestType: "support",
        allowedRoles: ["provider"],
        defaultSubcategory: "upgrade_not_active",
        subcategories: {
            upgrade_not_active: {
                priority: "high",
                autoReply:
                    "Please share the subscription plan, payment screenshot, account email, and the time you completed checkout.",
            },
            renewal_issue: {
                priority: "normal",
                autoReply:
                    "Please tell us the plan name, when renewal should have happened, and what the app is currently showing.",
            },
            payment_failed: {
                priority: "normal",
                autoReply:
                    "Please describe the payment failure, the method you used, and attach any error screenshot shown during checkout.",
            },
            billing_question: {
                priority: "low",
                autoReply:
                    "Please send your question together with the plan name and account email so admin can review the billing history.",
            },
        },
    },
    account_verification: {
        requestType: "help",
        allowedRoles: ["finder", "provider"],
        defaultSubcategory: "login_problem",
        subcategories: {
            login_problem: {
                priority: "high",
                autoReply:
                    "Please tell us how you sign in, what error appears, and include a screenshot if the app shows one.",
            },
            verification_pending: {
                priority: "normal",
                autoReply:
                    "Please share when you submitted verification and what status the app is currently showing.",
            },
            document_issue: {
                priority: "normal",
                autoReply:
                    "Please describe which document failed to upload and include a screenshot of the issue if possible.",
            },
            account_access: {
                priority: "high",
                autoReply:
                    "Please explain what account problem you are facing and include your email plus any error message shown in the app.",
            },
        },
    },
    app_bug: {
        requestType: "support",
        allowedRoles: ["finder", "provider"],
        defaultSubcategory: "crash",
        subcategories: {
            crash: {
                priority: "high",
                autoReply:
                    "Please tell us which screen crashed, what action you took before the crash, and include a screenshot or screen recording if available.",
            },
            ui_bug: {
                priority: "normal",
                autoReply:
                    "Please share the screen name, what looks wrong, and a screenshot so our team can reproduce the layout issue.",
            },
            map_location_issue: {
                priority: "normal",
                autoReply:
                    "Please describe the location problem, your device type, and include a screenshot of the map screen if possible.",
            },
            chat_issue: {
                priority: "normal",
                autoReply:
                    "Please describe what is not working in chat and include the related booking or ticket ID if relevant.",
            },
        },
    },
    other: {
        requestType: "help",
        allowedRoles: ["finder", "provider"],
        defaultSubcategory: "other_issue",
        subcategories: {
            general_question: {
                priority: "low",
                autoReply:
                    "Please describe your question clearly and include any related booking, payment, or account details if relevant.",
            },
            feature_request: {
                priority: "low",
                autoReply:
                    "Thanks for the suggestion. Please tell us what you want to improve and why it would help your workflow.",
            },
            other_issue: {
                priority: "normal",
                autoReply:
                    "Please describe the issue in as much detail as possible and include screenshots or IDs that can help us investigate.",
            },
        },
    },
};

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

function normalizePromotionTargetType(value) {
    const normalized = safeString(value).toLowerCase();
    if (["provider", "service", "category", "search", "post", "page"].includes(normalized)) {
        return normalized;
    }
    return "search";
}

function normalizePromotionPlacement(value) {
    const normalized = safeString(value).toLowerCase();
    if (normalized === "finder_home") return normalized;
    return "finder_home";
}

function normalizeSupportTicketType(value) {
    return safeString(value).toLowerCase() === "support" ? "support" : "help";
}

function normalizeUserRoleForTicket(value) {
    return safeString(value).toLowerCase() === "provider" ? "provider" : "finder";
}

function firstTicketCategoryFor({ requestType, role }) {
    return Object.entries(SUPPORT_TICKET_CATEGORY_OPTIONS).find(([, row]) => {
        const typeMatches = safeString(row.requestType).toLowerCase() === requestType;
        const allowedRoles = Array.isArray(row.allowedRoles) ? row.allowedRoles : [];
        return typeMatches && allowedRoles.includes(role);
    });
}

function resolveSupportTicketMeta(categoryValue, subcategoryValue, ticketTypeValue, roleValue) {
    const ticketType = normalizeSupportTicketType(ticketTypeValue);
    const role = normalizeUserRoleForTicket(roleValue);
    const category = safeString(categoryValue).toLowerCase();
    const categoryRowRaw = SUPPORT_TICKET_CATEGORY_OPTIONS[category];
    const categoryAllowed =
        categoryRowRaw &&
        safeString(categoryRowRaw.requestType).toLowerCase() === ticketType &&
        (Array.isArray(categoryRowRaw.allowedRoles)
            ? categoryRowRaw.allowedRoles.includes(role)
            : false);
    const fallbackEntry = firstTicketCategoryFor({ requestType: ticketType, role });
    const normalizedCategory = categoryAllowed
        ? category
        : (fallbackEntry?.[0] || "other");
    const categoryRow = SUPPORT_TICKET_CATEGORY_OPTIONS[normalizedCategory];
    const subcategory = safeString(subcategoryValue).toLowerCase();
    const normalizedSubcategory = categoryRow.subcategories[subcategory]
        ? subcategory
        : categoryRow.defaultSubcategory;
    const subcategoryRow = categoryRow.subcategories[normalizedSubcategory];
    return {
        ticketType,
        category: normalizedCategory,
        subcategory: normalizedSubcategory,
        priority: safeString(subcategoryRow.priority) || "normal",
        autoReply:
            safeString(subcategoryRow.autoReply) ||
            "Thanks for contacting support. Please share as much detail as possible so our admin team can help.",
    };
}

function startCaseFromKey(value) {
    return safeString(value)
        .split("_")
        .filter(Boolean)
        .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
        .join(" ");
}

function supportTicketCategoryLabel(category) {
    const labels = {
        payment_charge: "Wrong charge / payment",
        provider_issue: "Provider issue",
        finder_issue: "Finder issue",
        booking_problem: "Booking problem",
        subscription_upgrade: "Subscription / upgrade",
        account_verification: "Account / verification",
        app_bug: "App bug / technical issue",
        other: "Other",
    };
    return labels[category] || startCaseFromKey(category) || "Support request";
}

function supportTicketSubcategoryLabel(subcategory) {
    return startCaseFromKey(subcategory) || "Support request";
}

function buildSupportTicketContent(ticketType, category, subcategory) {
    const typeLabel = normalizeSupportTicketType(ticketType) === "support" ? "Support" : "Help";
    const categoryLabel = supportTicketCategoryLabel(category);
    const subcategoryLabel = supportTicketSubcategoryLabel(subcategory);
    return {
        title: subcategoryLabel,
        message: `${typeLabel} request created for ${categoryLabel} / ${subcategoryLabel}.`,
    };
}

function lifecycleForWindow({
    active = true,
    startAt = null,
    endAt = null,
    now = Date.now(),
}) {
    if (!active) return "inactive";
    const startMillis = toMillis(startAt);
    const endMillis = toMillis(endAt);
    if (startMillis > 0 && now < startMillis) return "scheduled";
    if (endMillis > 0 && now > endMillis) return "expired";
    return "active";
}

function normalizeLifecycle(value) {
    const normalized = (value || "").toString().trim().toLowerCase();
    if (["active", "scheduled", "expired", "inactive"].includes(normalized)) {
        return normalized;
    }
    return "active";
}

function normalizeKeyList(value, maxItems = MAX_NOTIFICATION_STATE_KEYS) {
    if (!Array.isArray(value)) return [];
    const deduped = Array.from(
        new Set(
            value
                .map((entry) => safeString(entry))
                .filter((entry) => entry.length > 0),
        ),
    );
    if (deduped.length <= maxItems) return deduped;
    return deduped.slice(0, maxItems);
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

function orderStatusTitle(status, role = "finder") {
    switch (status) {
        case "on_the_way":
            return "Order Confirmed";
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
            return role === "provider" ? "Upcoming Booking" : "Order Booked";
    }
}

function orderStatusMessage(row, status, role) {
    const serviceName = safeString(row?.serviceName) || "service";
    const providerName = safeString(row?.providerName) || "Provider";
    if (role === "provider") {
        switch (status) {
            case "booked":
                return `New upcoming booking received for ${serviceName}.`;
            case "on_the_way":
                return `Booking confirmed for ${serviceName}.`;
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
            return `${providerName} confirmed your booking for ${serviceName}.`;
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
            notifications: {
                general: true,
                sound: true,
                vibrate: true,
                newService: false,
            },
        };
        if (!snap.exists) return { data: defaults };
        const merged = { ...defaults, ...snap.data() };
        return {
            data: merged,
        };
    }

    static async getNotifications(uid, pagination, filters = {}) {
        const requestedRole = normalizeRole(filters.role);
        const typeFilter = (filters.type || "").toString().trim().toLowerCase();
        const query = safeString(filters.q || filters.query).toLowerCase();
        const normalized = normalizePagination(pagination, MAX_NOTIFICATION_SCAN);
        const queryLimit = readWindow(pagination, MAX_NOTIFICATION_SCAN);
        const includeOrderNotices = true;

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
                   if (typeFilter === "system") {
                        if (item.type !== "system") return false;
                    }
                }
                if (!query) return true;
                return [item.id, item.title, item.message, item.type]
                    .map((value) => safeString(value).toLowerCase())
                    .join(" ")
                    .includes(query);
            })
            .sort((a, b) => toMillis(b.createdAt) - toMillis(a.createdAt));

        if (includeOrderNotices) {
            const [orderItems, chatItems, supportItems] = await Promise.all([
                this._buildOrderStatusNotifications({
                    uid,
                    role,
                    limit: queryLimit,
                    query,
                }),
                this._buildChatNotifications({
                    uid,
                    role,
                    limit: queryLimit,
                    query,
                }),
                this._buildSupportReplyNotifications({
                    uid,
                    role,
                    limit: queryLimit,
                    query,
                }),
            ]);
            const mergedItems = [...items, ...orderItems, ...chatItems, ...supportItems].sort(
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

    static async getPromotions(uid, filters = {}) {
        const placement = normalizePromotionPlacement(filters.placement);
        const cityFilter = safeString(filters.city).toLowerCase();
        const [userSnap, promotionsSnap] = await Promise.all([
            db.collection("users").doc(uid).get(),
            db.collection("adminPromotions").limit(MAX_PROMOTION_SCAN).get(),
        ]);
        const userRow = userSnap.exists ? (userSnap.data() || {}) : {};
        const roles = Array.from(
            new Set(
                [
                    normalizeRole(userRow.role),
                    ...normalizeRoleList(userRow.roles, []),
                ].filter((value) => ["finder", "provider"].includes(value)),
            ),
        );
        if (roles.length === 0) {
            roles.push("finder");
        }
        const now = Date.now();
        const items = promotionsSnap.docs
            .map((doc) => {
                const row = doc.data() || {};
                const active = row.active !== false;
                const lifecycle = lifecycleForWindow({
                    active,
                    startAt: row.startAt,
                    endAt: row.endAt,
                    now,
                });
                return {
                    id: doc.id,
                    placement: normalizePromotionPlacement(row.placement),
                    badgeLabel: safeString(row.badgeLabel) || "Featured",
                    title: safeString(row.title) || "Promotion",
                    description: safeString(row.description),
                    imageUrl: safeString(row.imageUrl),
                    ctaLabel: safeString(row.ctaLabel) || "Explore",
                    targetType: normalizePromotionTargetType(row.targetType),
                    targetValue: safeString(row.targetValue),
                    query: safeString(row.query),
                    category: safeString(row.category),
                    city: safeString(row.city),
                    targetRoles: normalizeRoleList(row.targetRoles, ["finder"]),
                    sortOrder: Math.max(0, Math.floor(Number(row.sortOrder || 0) || 0)),
                    active,
                    lifecycle,
                    startAt: toIso(row.startAt),
                    endAt: toIso(row.endAt),
                    createdAt: toIso(row.createdAt),
                    updatedAt: toIso(row.updatedAt),
                };
            })
            .filter((row) => {
                if (row.placement !== placement) return false;
                if (row.lifecycle !== "active") return false;
                if (!row.targetRoles.some((role) => roles.includes(role))) return false;
                if (!cityFilter) return true;
                if (!row.city) return true;
                return row.city.toLowerCase() === cityFilter;
            })
            .sort((a, b) => {
                if (a.sortOrder === b.sortOrder) {
                    return toMillis(b.createdAt) - toMillis(a.createdAt);
                }
                return a.sortOrder - b.sortOrder;
            });

        return { data: items };
    }

    static async getNotificationReadState(uid) {
        const readStateRef = db
            .collection("users")
            .doc(uid)
            .collection("app")
            .doc("notificationReadState");
        const snap = await readStateRef.get();
        if (!snap.exists) {
            return {
                data: {
                    readKeys: [],
                    clearedKeys: [],
                    updatedAt: null,
                },
            };
        }
        const row = snap.data() || {};
        return {
            data: {
                readKeys: normalizeKeyList(row.readKeys),
                clearedKeys: normalizeKeyList(row.clearedKeys),
                updatedAt: toIso(row.updatedAt),
            },
        };
    }

    static async updateNotificationReadState(uid, payload = {}) {
        const replace = payload.replace === true;
        const incomingRead = normalizeKeyList(payload.readKeys);
        const incomingCleared = normalizeKeyList(payload.clearedKeys);
        const readStateRef = db
            .collection("users")
            .doc(uid)
            .collection("app")
            .doc("notificationReadState");

        if (replace) {
            await readStateRef.set(
                {
                    readKeys: incomingRead,
                    clearedKeys: incomingCleared,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                },
                { merge: true },
            );
        } else {
            await db.runTransaction(async (transaction) => {
                const snap = await transaction.get(readStateRef);
                const row = snap.exists ? (snap.data() || {}) : {};
                const nextRead = normalizeKeyList([
                    ...normalizeKeyList(row.readKeys),
                    ...incomingRead,
                ]);
                const nextCleared = normalizeKeyList([
                    ...normalizeKeyList(row.clearedKeys),
                    ...incomingCleared,
                ]);
                transaction.set(
                    readStateRef,
                    {
                        readKeys: nextRead,
                        clearedKeys: nextCleared,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    },
                    { merge: true },
                );
            });
        }

        const stored = await readStateRef.get();
        const row = stored.exists ? (stored.data() || {}) : {};
        return {
            data: {
                readKeys: normalizeKeyList(row.readKeys),
                clearedKeys: normalizeKeyList(row.clearedKeys),
                updatedAt: toIso(row.updatedAt),
            },
        };
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
                    title: orderStatusTitle(status, role),
                    message: orderStatusMessage(row, status, role),
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

    static async _buildChatNotifications({ uid, role, limit, query }) {
        let snap;
        try {
            snap = await db
                .collection("chats")
                .where("participants", "array-contains", uid)
                .orderBy("lastMessageAt", "desc")
                .limit(limit)
                .get();
        } catch (_) {
            snap = await db
                .collection("chats")
                .where("participants", "array-contains", uid)
                .limit(limit)
                .get();
        }

        const loweredQuery = safeString(query).toLowerCase();
        return snap.docs
            .map((doc) => {
                const row = doc.data() || {};
                const lastSenderUid = safeString(row.lastSenderUid);
                if (!lastSenderUid || lastSenderUid === uid) return null;
                const unreadCounts =
                    row.unreadCounts && typeof row.unreadCounts === "object"
                        ? row.unreadCounts
                        : {};
                const unreadForCurrentUser = Number(unreadCounts[uid] || 0);
                if (!Number.isFinite(unreadForCurrentUser) || unreadForCurrentUser <= 0) {
                    return null;
                }

                const eventMillis =
                    toMillis(row.lastMessageAt) ||
                    toMillis(row.updatedAt) ||
                    toMillis(row.createdAt);
                if (eventMillis <= 0) return null;

                const participants = Array.isArray(row.participants)
                    ? row.participants.map((entry) => safeString(entry)).filter(Boolean)
                    : [];
                const peerUid = participants.find((entry) => entry !== uid) || "";
                const participantMeta =
                    row.participantMeta && typeof row.participantMeta === "object"
                        ? row.participantMeta
                        : {};
                const peerMeta =
                    peerUid &&
                    participantMeta[peerUid] &&
                    typeof participantMeta[peerUid] === "object"
                        ? participantMeta[peerUid]
                        : {};
                const peerName =
                    safeString(peerMeta.name) ||
                    safeString(peerMeta.displayName) ||
                    safeString(peerMeta.fullName) ||
                    "User";
                const message = safeString(row.lastMessageText) || "You have a new message.";
                const item = {
                    id: `chat_${doc.id}_${eventMillis}`,
                    type: "system",
                    source: "chat_message",
                    threadId: doc.id,
                    title: `New message from ${peerName}`,
                    message,
                    targetRoles: [role],
                    lifecycle: "active",
                    active: true,
                    createdAt: new Date(eventMillis).toISOString(),
                    updatedAt: toIso(row.updatedAt),
                    startAt: null,
                    endAt: null,
                };
                if (!loweredQuery) return item;
                const haystack = [item.id, item.title, item.message, peerName, peerUid]
                    .map((value) => safeString(value).toLowerCase())
                    .join(" ");
                return haystack.includes(loweredQuery) ? item : null;
            })
            .filter(Boolean)
            .sort((a, b) => toMillis(b.createdAt) - toMillis(a.createdAt));
    }

    static async _buildSupportReplyNotifications({ uid, role, limit, query }) {
        const ticketsRef = db.collection("users").doc(uid).collection("helpTickets");
        let snap;
        try {
            snap = await ticketsRef.orderBy("lastMessageAt", "desc").limit(limit).get();
        } catch (_) {
            snap = await ticketsRef.limit(limit).get();
        }

        const loweredQuery = safeString(query).toLowerCase();
        return snap.docs
            .map((doc) => {
                const row = doc.data() || {};
                if (safeString(row.lastMessageSenderRole).toLowerCase() !== "admin") {
                    return null;
                }

                const eventMillis =
                    toMillis(row.lastMessageAt) ||
                    toMillis(row.updatedAt) ||
                    toMillis(row.createdAt);
                if (eventMillis <= 0) return null;

                const item = {
                    id: `support_${doc.id}_${eventMillis}`,
                    type: "system",
                    source: "support_message",
                    title: safeString(row.title) || "Support reply",
                    message:
                        safeString(row.lastMessageText) ||
                        safeString(row.message) ||
                        "Admin support replied to your ticket.",
                    targetRoles: [role],
                    lifecycle: "active",
                    active: true,
                    createdAt: new Date(eventMillis).toISOString(),
                    updatedAt: toIso(row.updatedAt),
                    startAt: null,
                    endAt: null,
                };
                if (!loweredQuery) return item;
                const haystack = [item.id, item.title, item.message, safeString(row.status)]
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
            notifications: {
                ...current.notifications,
                ...(payload.notifications || {}),
            },
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        await settingsRef.set(updated, { merge: true });
        return { data: updated };
    }

    static async registerPushToken(uid, payload = {}) {
        return PushService.registerToken(uid, payload);
    }

    static async unregisterPushToken(uid, payload = {}) {
        return PushService.unregisterToken(uid, payload);
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
        const userMeta = await this._resolveUserMeta(uid);
        const supportMeta = resolveSupportTicketMeta(
            payload.category,
            payload.subcategory,
            payload.ticketType,
            userMeta.role,
        );
        const ticketContent = buildSupportTicketContent(
            supportMeta.ticketType,
            supportMeta.category,
            supportMeta.subcategory,
        );
        const createdAt = admin.firestore.Timestamp.now();
        const updatedAt = createdAt;
        const item = {
            ticketType: supportMeta.ticketType,
            title: ticketContent.title,
            message: ticketContent.message,
            category: supportMeta.category,
            subcategory: supportMeta.subcategory,
            priority: supportMeta.priority,
            status: "waiting_on_admin",
            createdAt,
            updatedAt,
            lastMessageText: ticketContent.message,
            lastMessageAt: createdAt,
            lastMessageSenderRole: userMeta.role,
            lastMessageSenderName: userMeta.name,
            autoReplySent: true,
        };
        const firstMessageRef = docRef.collection("messages").doc();
        const autoReplyRef = docRef.collection("messages").doc();
        const autoReplyCreatedAt = admin.firestore.Timestamp.fromMillis(
            createdAt.toMillis() + 1,
        );
        await db.runTransaction(async (tx) => {
            tx.set(docRef, item);
            tx.set(firstMessageRef, {
                id: firstMessageRef.id,
                text: ticketContent.message,
                type: "text",
                senderUid: uid,
                senderRole: userMeta.role,
                senderName: userMeta.name,
                createdAt,
            });
            tx.set(autoReplyRef, {
                id: autoReplyRef.id,
                text: supportMeta.autoReply,
                type: "auto_reply",
                senderUid: "",
                senderRole: "admin",
                senderName: "Support assistant",
                createdAt: autoReplyCreatedAt,
            });
        });
        return {
            data: {
                id: docRef.id,
                title: item.title,
                message: item.message,
                category: item.category,
                subcategory: item.subcategory,
                priority: item.priority,
                status: item.status,
                createdAt: toIso(createdAt),
                updatedAt: toIso(updatedAt),
                lastMessageText: item.lastMessageText,
                lastMessageAt: toIso(createdAt),
            },
        };
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
                imageUrl: safeString(row.imageUrl),
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
        const imageUrl = safeString(payload.imageUrl);
        const messageType = imageUrl ? "image" : "text";
        if (!text && !imageUrl) {
            const error = new Error("message text or imageUrl is required");
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
        const nextStatus = "waiting_on_admin";
        const now = admin.firestore.Timestamp.now();
        const previewText = messageType === "image" ? "Photo" : text;
        await db.runTransaction(async (tx) => {
            tx.set(messageRef, {
                id: messageRef.id,
                text,
                type: messageType,
                imageUrl,
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
                    lastMessageText: previewText,
                    lastMessageAt: now,
                    lastMessageSenderRole: userMeta.role,
                    lastMessageSenderName: userMeta.name,
                },
                { merge: true },
            );
        });
        return {
            data: {
                id: messageRef.id,
                text,
                type: messageType,
                imageUrl,
                senderUid: uid,
                senderRole: userMeta.role,
                senderName: userMeta.name,
                createdAt: toIso(now),
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

    static async updateAddress(uid, addressId, payload) {
        const addressesRef = db.collection("users").doc(uid).collection("addresses");
        const docRef = addressesRef.doc(addressId);
        const snap = await docRef.get();
        if (!snap.exists) {
            const error = new Error("address not found");
            error.status = 404;
            throw error;
        }
        const now = admin.firestore.FieldValue.serverTimestamp();
        const updates = {
            updatedAt: now,
        };
        if (payload.label !== undefined) {
            updates.label = payload.label.toString().trim();
        }
        if (payload.mapLink !== undefined) {
            updates.mapLink = payload.mapLink.toString().trim();
        }
        if (payload.street !== undefined) {
            updates.street = payload.street.toString().trim();
        }
        if (payload.city !== undefined) {
            updates.city = payload.city.toString().trim();
        }
        if (payload.isDefault !== undefined) {
            updates.isDefault = payload.isDefault === true;
        }

        if (updates.isDefault === true) {
            const existing = await addressesRef.where("isDefault", "==", true).get();
            const batch = db.batch();
            existing.docs.forEach((doc) => {
                if (doc.id === addressId) return;
                batch.update(doc.ref, {
                    isDefault: false,
                    updatedAt: now,
                });
            });
            batch.set(docRef, updates, { merge: true });
            await batch.commit();
        } else {
            await docRef.set(updates, { merge: true });
        }

        const updated = await docRef.get();
        const row = updated.data() || {};
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

    static async deleteAddress(uid, addressId) {
        const addressesRef = db.collection("users").doc(uid).collection("addresses");
        const docRef = addressesRef.doc(addressId);
        const snap = await docRef.get();
        if (!snap.exists) {
            const error = new Error("address not found");
            error.status = 404;
            throw error;
        }
        const row = snap.data() || {};
        const wasDefault = row.isDefault === true;
        await docRef.delete();

        if (wasDefault) {
            const fallback = await addressesRef
                .orderBy("updatedAt", "desc")
                .limit(1)
                .get();
            if (!fallback.empty) {
                const replacement = fallback.docs[0];
                await replacement.ref.set(
                    {
                        isDefault: true,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    },
                    { merge: true },
                );
            }
        }

        return {
            data: {
                id: addressId,
                deleted: true,
            },
        };
    }
}

export default UserService;
