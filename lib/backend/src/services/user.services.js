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
    
        //  Prevent re-initialization
        if (userSnap.exists) {
            return {
                data: {
                    user: userSnap.data(),
                }
            };
        }
    
        //  Common user doc
        const userPayload = {
            name: user.name || "",
            email: user.email || "",
            role,
            photoUrl: user.picture || "",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        };
    
        //  Role-specific doc
        let roleRef;
        let rolePayload;
    
        if (role === "provider") {
            roleRef = db.collection("providers").doc(user.uid);
            rolePayload = {
            bio: "",
            phoneNumber: "",
            PhotoUrl: user.picture ?? '',
            ratePerHour: 0,
            city: "",
            location: null,
            serviceId: "",
            serviceName: "",
            serviceImageUrl: "",
            birthday: null,
            ratingCount:0,
            ratingSum:0,
            activeOrder : 0,
            completedOrder:0,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            };
        } else {
            roleRef = db.collection("finders").doc(user.uid);
            rolePayload = {
            city: "",
            PhotoUrl: user.picture ?? '',
            phoneNumber: "",
            birthday: null,
            location: null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            };
        }
    
        const batch = db.batch();
        batch.set(userRef, userPayload);
        batch.set(roleRef, rolePayload);
        await batch.commit();
        await admin.auth().setCustomUserClaims(user.uid, { role });

        return { 
            data: { 
                user: userPayload, 
                roleData: rolePayload 
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
