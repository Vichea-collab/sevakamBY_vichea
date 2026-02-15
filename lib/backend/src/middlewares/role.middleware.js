import { db } from "../config/firebase.js";
import { forbidden, internalServerError } from "../utils/response.util.js";

export function requireRole(allowedRoles = []) {
  return async (req, res, next) => {
    try {
      const role = (req.user?.role || "").toString().toLowerCase();
      const normalized = normalizeRole(role);
      const allowedNormalized = allowedRoles
        .map((value) => normalizeRole((value || "").toString().toLowerCase()))
        .filter(Boolean);

      if (allowedNormalized.includes(normalized)) {
        return next();
      }

      const uid = req.user?.uid;
      if (!uid) {
        return forbidden(res, "Forbidden (role)");
      }

      const checks = [];
      if (allowedNormalized.includes("finder")) {
        checks.push(db.collection("finders").doc(uid).get());
      }
      if (allowedNormalized.includes("provider")) {
        checks.push(db.collection("providers").doc(uid).get());
      }
      if (checks.length === 0) {
        return forbidden(res, "Forbidden (role)");
      }

      const snapshots = await Promise.all(checks);
      const hasAllowedRole = snapshots.some((snapshot) => snapshot.exists);
      if (!hasAllowedRole) {
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
