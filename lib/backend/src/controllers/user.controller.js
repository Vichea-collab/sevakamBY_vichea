import UserService  from "../services/user.services.js";    
import {
    created,
    internalServerError,
    badRequest,
    ok,
    notFound,
    okPaginated,
} from "../utils/response.util.js";
import { parsePaginationQuery } from "../utils/pagination.util.js";

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
            const pagination = parsePaginationQuery(req.query);
            const result = await UserService.getHelpTickets(req.user.uid, pagination);
            return okPaginated(
                res,
                result.data,
                result.pagination,
                "Help tickets retrieved successfully",
            );
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

    static async getAddresses(req, res) {
        try {
            const result = await UserService.getAddresses(req.user.uid);
            return ok(res, result.data, "Addresses retrieved successfully");
        } catch (err) {
            return internalServerError(res, "Failed to retrieve addresses");
        }
    }

    static async createAddress(req, res) {
        try {
            const result = await UserService.createAddress(req.user.uid, req.body || {});
            return created(res, result.data, "Address saved successfully");
        } catch (err) {
            return internalServerError(res, "Failed to save address");
        }
    }
}

export default UserController;
