import admin from "firebase-admin";
import { db } from "../config/firebase.js";
import { paginateArray } from "../utils/pagination.util.js";

const MAX_TICKET_SCAN = 120;
const MAX_ADDRESS_SCAN = 100;

function readWindow(pagination, maxLimit) {
    const page = Math.max(1, Number.parseInt((pagination?.page ?? 1).toString(), 10) || 1);
    const limit = Math.max(1, Number.parseInt((pagination?.limit ?? 10).toString(), 10) || 10);
    return Math.min(maxLimit, page * limit + limit);
}

class UserService {
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
        const item = {
            title: payload.title.toString(),
            message: payload.message.toString(),
            status: "open",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        await docRef.set(item);
        return { data: { id: docRef.id, ...item } };
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
