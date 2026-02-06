import {notFound, forbidden, internalServerError} from '../utils/response.util.js';

export function requireRole(allowedRoles = []) {
    return async (req, res, next) => {
        try {
        const role = req.user?.role;
        if (!allowedRoles.includes(role)) {
            return forbidden(res, "Forbidden (role)");
        }
        return next();
        } catch (err) {
        return internalServerError(res, "Role check failed");
        }
    };
}
