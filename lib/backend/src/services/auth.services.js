import { db } from "../config/firebase.js";

class AuthService {
    static async me(uid){
        const userSnap = await db.collection("users").doc(uid).get();
        return { data: userSnap.exists ? userSnap.data() : null };
    }
}

export default AuthService;