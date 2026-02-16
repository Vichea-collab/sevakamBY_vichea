import { auth } from "../config/firebase.js";
import {unauthorized} from '../utils/response.util.js';
export async function requireAuth(req, res, next) {
    try {
    const header = req.headers.authorization || "";
    const token = header.startsWith("Bearer ") ? header.slice(7) : null;

    if (!token) {
        return unauthorized(res, "No token provided");
    }

    const decoded = await auth.verifyIdToken(token);

    const claimRoles = Array.isArray(decoded?.roles)
      ? decoded.roles
      : [];

    req.user = {
        uid: decoded.uid,
        role: decoded.role,
        roles: claimRoles,
        email: decoded.email || null,
        name: decoded.name || null,
        picture: decoded.picture || null,
    };

    return next();
    } catch (err) {
        return unauthorized(res, "Authentication failed");
    }
}
