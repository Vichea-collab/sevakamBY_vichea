import {forbidden, internalServerError} from '../utils/response.util.js';

export function requireRole(allowedRoles = []) {
    return async (req, res, next) => {
        try {
        const role = (req.user?.role || "").toString().toLowerCase();
        const normalized = normalizeRole(role);
        const allowedNormalized = allowedRoles.map((value) =>
            normalizeRole((value || "").toString().toLowerCase())
        );
        if (!allowedNormalized.includes(normalized)) {
            return forbidden(res, "Forbidden (role)");
        }
        return next();
        } catch (err) {
        return internalServerError(res, "Role check failed");
        }
    };
}

function normalizeRole(role) {
    if (role === "finders") return "finder";
    if (role === "providers") return "provider";
    return role;
}
