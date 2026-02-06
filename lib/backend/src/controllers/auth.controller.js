import AuthService  from "../services/auth.services.js";
import {notFound, ok, internalServerError} from '../utils/response.util.js';

class AuthController {
    static async me(req, res) {
        try {
            const userDoc = await AuthService.me(req.user.uid);
            if(!userDoc.data){
                return notFound(res, "User not found");
            }
            return ok(res, userDoc.data, "User data retrieved successfully");
        } catch (error) {
            return internalServerError(res, "Failed to retrieve user data");
        }
    }
}
export default AuthController;

