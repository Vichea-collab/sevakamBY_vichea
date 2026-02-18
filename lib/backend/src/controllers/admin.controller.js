import AdminService from "../services/admin.services.js";
import {
  badRequest,
  forbidden,
  internalServerError,
  notFound,
  ok,
  okPaginated,
} from "../utils/response.util.js";
import { parsePaginationQuery } from "../utils/pagination.util.js";

function handleError(res, error, fallbackMessage) {
  if (error?.status === 400) {
    return badRequest(res, error.message || "bad request");
  }
  if (error?.status === 403) {
    return forbidden(res, error.message || "admin access required");
  }
  if (error?.status === 404) {
    return notFound(res, error.message || "not found");
  }
  return internalServerError(res, error?.message || fallbackMessage);
}

class AdminController {
  static async getOverview(req, res) {
    try {
      const result = await AdminService.getOverview(req.user.uid, req.user);
      return ok(res, result.data, "Admin overview retrieved successfully");
    } catch (error) {
      return handleError(res, error, "Failed to retrieve admin overview");
    }
  }

  static async getUsers(req, res) {
    try {
      const pagination = parsePaginationQuery(req.query);
      const result = await AdminService.getUsers(
        req.user.uid,
        req.user,
        pagination,
        req.query || {},
      );
      return okPaginated(
        res,
        result.data,
        result.pagination,
        "Admin users retrieved successfully",
      );
    } catch (error) {
      return handleError(res, error, "Failed to retrieve admin users");
    }
  }

  static async getOrders(req, res) {
    try {
      const pagination = parsePaginationQuery(req.query);
      const result = await AdminService.getOrders(
        req.user.uid,
        req.user,
        pagination,
        req.query || {},
      );
      return okPaginated(
        res,
        result.data,
        result.pagination,
        "Admin orders retrieved successfully",
      );
    } catch (error) {
      return handleError(res, error, "Failed to retrieve admin orders");
    }
  }

  static async getPosts(req, res) {
    try {
      const pagination = parsePaginationQuery(req.query);
      const result = await AdminService.getPosts(
        req.user.uid,
        req.user,
        pagination,
        req.query || {},
      );
      return okPaginated(
        res,
        result.data,
        result.pagination,
        "Admin posts retrieved successfully",
      );
    } catch (error) {
      return handleError(res, error, "Failed to retrieve admin posts");
    }
  }

  static async getTickets(req, res) {
    try {
      const pagination = parsePaginationQuery(req.query);
      const result = await AdminService.getTickets(
        req.user.uid,
        req.user,
        pagination,
        req.query || {},
      );
      return okPaginated(
        res,
        result.data,
        result.pagination,
        "Admin help tickets retrieved successfully",
      );
    } catch (error) {
      return handleError(res, error, "Failed to retrieve admin help tickets");
    }
  }

  static async getServices(req, res) {
    try {
      const pagination = parsePaginationQuery(req.query);
      const result = await AdminService.getServices(
        req.user.uid,
        req.user,
        pagination,
        req.query || {},
      );
      return okPaginated(
        res,
        result.data,
        result.pagination,
        "Admin services retrieved successfully",
      );
    } catch (error) {
      return handleError(res, error, "Failed to retrieve admin services");
    }
  }

  static async getBroadcasts(req, res) {
    try {
      const pagination = parsePaginationQuery(req.query);
      const result = await AdminService.getBroadcasts(
        req.user.uid,
        req.user,
        pagination,
        req.query || {},
      );
      return okPaginated(
        res,
        result.data,
        result.pagination,
        "Admin broadcasts retrieved successfully",
      );
    } catch (error) {
      return handleError(res, error, "Failed to retrieve admin broadcasts");
    }
  }

  static async createBroadcast(req, res) {
    try {
      const result = await AdminService.createBroadcast(
        req.user.uid,
        req.user,
        req.body || {},
      );
      return ok(res, result.data, "Broadcast created successfully");
    } catch (error) {
      return handleError(res, error, "Failed to create broadcast");
    }
  }

  static async updateBroadcastActive(req, res) {
    try {
      const result = await AdminService.updateBroadcastActive(
        req.user.uid,
        req.user,
        req.params.id,
        req.body || {},
      );
      return ok(res, result.data, "Broadcast state updated successfully");
    } catch (error) {
      return handleError(res, error, "Failed to update broadcast state");
    }
  }

  static async getReadBudget(req, res) {
    try {
      const result = await AdminService.getReadBudget(req.user.uid, req.user);
      return ok(res, result.data, "Admin read budget retrieved successfully");
    } catch (error) {
      return handleError(res, error, "Failed to retrieve read budget");
    }
  }

  static async globalSearch(req, res) {
    try {
      const result = await AdminService.globalSearch(req.user.uid, req.user, {
        q: req.query?.q,
        limit: req.query?.limit,
      });
      return ok(res, result.data, "Admin search completed successfully");
    } catch (error) {
      return handleError(res, error, "Failed to complete global search");
    }
  }

  static async getAnalytics(req, res) {
    try {
      const result = await AdminService.getAnalytics(req.user.uid, req.user, {
        days: req.query?.days,
        compareDays: req.query?.compareDays,
      });
      return ok(res, result.data, "Admin analytics retrieved successfully");
    } catch (error) {
      return handleError(res, error, "Failed to retrieve analytics");
    }
  }

  static async updateUserStatus(req, res) {
    try {
      const result = await AdminService.updateUserStatus(
        req.user.uid,
        req.user,
        req.params.id,
        req.body || {},
      );
      return ok(res, result.data, "User status updated successfully");
    } catch (error) {
      return handleError(res, error, "Failed to update user status");
    }
  }

  static async updateOrderStatus(req, res) {
    try {
      const result = await AdminService.updateOrderStatus(
        req.user.uid,
        req.user,
        req.params.id,
        req.body || {},
      );
      return ok(res, result.data, "Order status updated successfully");
    } catch (error) {
      return handleError(res, error, "Failed to update order status");
    }
  }

  static async updatePostStatus(req, res) {
    try {
      const result = await AdminService.updatePostStatus(
        req.user.uid,
        req.user,
        req.params.source,
        req.params.id,
        req.body || {},
      );
      return ok(res, result.data, "Post status updated successfully");
    } catch (error) {
      return handleError(res, error, "Failed to update post status");
    }
  }

  static async updateTicketStatus(req, res) {
    try {
      const result = await AdminService.updateTicketStatus(
        req.user.uid,
        req.user,
        req.params.userUid,
        req.params.id,
        req.body || {},
      );
      return ok(res, result.data, "Ticket status updated successfully");
    } catch (error) {
      return handleError(res, error, "Failed to update ticket status");
    }
  }

  static async getTicketMessages(req, res) {
    try {
      const pagination = parsePaginationQuery(req.query);
      const result = await AdminService.getTicketMessages(
        req.user.uid,
        req.user,
        req.params.userUid,
        req.params.id,
        pagination,
      );
      return okPaginated(
        res,
        result.data,
        result.pagination,
        "Ticket messages retrieved successfully",
      );
    } catch (error) {
      return handleError(res, error, "Failed to retrieve ticket messages");
    }
  }

  static async sendTicketMessage(req, res) {
    try {
      const result = await AdminService.sendTicketMessage(
        req.user.uid,
        req.user,
        req.params.userUid,
        req.params.id,
        req.body || {},
      );
      return ok(res, result.data, "Ticket message sent successfully");
    } catch (error) {
      return handleError(res, error, "Failed to send ticket message");
    }
  }

  static async updateServiceActive(req, res) {
    try {
      const result = await AdminService.updateServiceActive(
        req.user.uid,
        req.user,
        req.params.id,
        req.body || {},
      );
      return ok(res, result.data, "Service state updated successfully");
    } catch (error) {
      return handleError(res, error, "Failed to update service state");
    }
  }

  static async getUndoHistory(req, res) {
    try {
      const pagination = parsePaginationQuery(req.query);
      const result = await AdminService.getUndoHistory(
        req.user.uid,
        req.user,
        pagination,
        req.query || {},
      );
      return okPaginated(
        res,
        result.data,
        result.pagination,
        "Undo history retrieved successfully",
      );
    } catch (error) {
      return handleError(res, error, "Failed to retrieve undo history");
    }
  }

  static async undoAction(req, res) {
    try {
      const result = await AdminService.undoAction(
        req.user.uid,
        req.user,
        req.body || {},
      );
      return ok(res, result.data, "Action successfully reverted");
    } catch (error) {
      return handleError(res, error, "Failed to undo action");
    }
  }
}

export default AdminController;
