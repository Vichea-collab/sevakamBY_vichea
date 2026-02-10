import UserService  from "../services/user.services.js";    
import { created, internalServerError, badRequest, ok, notFound} from "../utils/response.util.js";

class UserController {
    static async initUser(req, res) {
        try{
            const result = await UserService.initUser(req.user, req.body.role);
            return created(res, result.data, "User initialized successfully");
        }catch(err){
            if(err.status === 400){
                return badRequest(res, err.message);
            }
            return internalServerError(res, "User initialization failed",);
        }
    }

    static async getSettings(req, res) {
        try {
            const result = await UserService.getSettings(req.user.uid);
            return ok(res, result.data, "User settings retrieved successfully");
        } catch (err) {
            return internalServerError(res, "Failed to retrieve user settings");
        }
    }

    static async updateSettings(req, res) {
        try {
            const result = await UserService.updateSettings(req.user.uid, req.body || {});
            return ok(res, result.data, "User settings updated successfully");
        } catch (err) {
            return internalServerError(res, "Failed to update user settings");
        }
    }

    static async updateProfile(req, res) {
        try {
            const result = await UserService.updateUserProfile(req.user.uid, req.body || {});
            return ok(res, result.data, "User profile updated successfully");
        } catch (err) {
            if (err.status === 404) {
                return notFound(res, err.message);
            }
            return internalServerError(res, "Failed to update user profile");
        }
    }

    static async getHelpTickets(req, res) {
        try {
            const result = await UserService.getHelpTickets(req.user.uid);
            return ok(res, result.data, "Help tickets retrieved successfully");
        } catch (err) {
            return internalServerError(res, "Failed to retrieve help tickets");
        }
    }

    static async createHelpTicket(req, res) {
        try {
            const { title, message } = req.body || {};
            if (!title || !message) {
                return badRequest(res, "title and message are required");
            }
            const result = await UserService.createHelpTicket(req.user.uid, { title, message });
            return created(res, result.data, "Help ticket created successfully");
        } catch (err) {
            return internalServerError(res, "Failed to create help ticket");
        }
    }
}

export default UserController;
