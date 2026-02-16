import AdminService from "../services/admin.services.js";
import {
  forbidden,
  internalServerError,
  ok,
  okPaginated,
} from "../utils/response.util.js";
import { parsePaginationQuery } from "../utils/pagination.util.js";

function handleError(res, error, fallbackMessage) {
  if (error?.status === 403) {
    return forbidden(res, error.message || "admin access required");
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
}

export default AdminController;
