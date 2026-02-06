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
}

export default UserService;