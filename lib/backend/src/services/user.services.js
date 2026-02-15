import admin from "firebase-admin";
import { db } from "../config/firebase.js";

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

    static async getHelpTickets(uid) {
        const ticketsRef = db.collection("users").doc(uid).collection("helpTickets");
        const snap = await ticketsRef.orderBy("createdAt", "desc").limit(30).get();
        if (snap.empty) return { data: [] };
        const items = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
        return { data: items };
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
}

export default UserService;
