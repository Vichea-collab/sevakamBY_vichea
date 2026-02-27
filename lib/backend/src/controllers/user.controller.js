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

    static async getNotifications(req, res) {
        try {
            const pagination = parsePaginationQuery(req.query);
            const result = await UserService.getNotifications(
                req.user.uid,
                pagination,
                req.query || {},
            );
            return okPaginated(
                res,
                result.data,
                result.pagination,
                "Notifications retrieved successfully",
            );
        } catch (err) {
            return internalServerError(res, "Failed to retrieve notifications");
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
            if (err.status === 400) {
                return badRequest(res, err.message);
            }
            return internalServerError(res, "Failed to create help ticket");
        }
    }

    static async getHelpTicketMessages(req, res) {
        try {
            const ticketId = (req.params.id || "").toString().trim();
            if (!ticketId) {
                return badRequest(res, "ticket id is required");
            }
            const pagination = parsePaginationQuery(req.query);
            const result = await UserService.getHelpTicketMessages(
                req.user.uid,
                ticketId,
                pagination,
            );
            return okPaginated(
                res,
                result.data,
                result.pagination,
                "Help ticket messages retrieved successfully",
            );
        } catch (err) {
            if (err.status === 400) {
                return badRequest(res, err.message);
            }
            if (err.status === 404) {
                return notFound(res, err.message);
            }
            return internalServerError(res, "Failed to retrieve help ticket messages");
        }
    }

    static async sendHelpTicketMessage(req, res) {
        try {
            const ticketId = (req.params.id || "").toString().trim();
            if (!ticketId) {
                return badRequest(res, "ticket id is required");
            }
            const result = await UserService.sendHelpTicketMessage(
                req.user.uid,
                ticketId,
                req.body || {},
            );
            return ok(res, result.data, "Help ticket message sent successfully");
        } catch (err) {
            if (err.status === 400) {
                return badRequest(res, err.message);
            }
            if (err.status === 404) {
                return notFound(res, err.message);
            }
            return internalServerError(res, "Failed to send help ticket message");
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

    static async updateAddress(req, res) {
        try {
            const addressId = (req.params.id || "").toString().trim();
            if (!addressId) {
                return badRequest(res, "address id is required");
            }
            const result = await UserService.updateAddress(
                req.user.uid,
                addressId,
                req.body || {},
            );
            return ok(res, result.data, "Address updated successfully");
        } catch (err) {
            if (err.status === 400) {
                return badRequest(res, err.message);
            }
            if (err.status === 404) {
                return notFound(res, err.message);
            }
            return internalServerError(res, "Failed to update address");
        }
    }

    static async deleteAddress(req, res) {
        try {
            const addressId = (req.params.id || "").toString().trim();
            if (!addressId) {
                return badRequest(res, "address id is required");
            }
            const result = await UserService.deleteAddress(req.user.uid, addressId);
            return ok(res, result.data, "Address deleted successfully");
        } catch (err) {
            if (err.status === 404) {
                return notFound(res, err.message);
            }
            return internalServerError(res, "Failed to delete address");
        }
    }
}

export default UserController;
