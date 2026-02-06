import { ok } from "../utils/response.util.js";

export function healthCheck(req, res) {
    return ok(res, new Date().toISOString() , "Health check successful");
}
