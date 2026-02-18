import OrderService from "../services/order.services.js";
import {
  badRequest,
  created,
  forbidden,
  internalServerError,
  notFound,
  ok,
  okPaginated,
} from "../utils/response.util.js";
import { parsePaginationQuery } from "../utils/pagination.util.js";

class OrderController {
  static async quoteFinderOrder(req, res) {
    try {
      const result = await OrderService.quoteFinderOrder(
        req.user.uid,
        req.user,
        req.body || {},
      );
      return ok(res, result.data, "Order quote generated successfully");
    } catch (error) {
      if (error.status === 400) {
        return badRequest(res, error.message || "invalid quote payload");
      }
      return internalServerError(
        res,
        error?.message || "Failed to generate order quote",
      );
    }
  }

  static async createFinderOrder(req, res) {
    try {
      const result = await OrderService.createFinderOrder(
        req.user.uid,
        req.user,
        req.body || {},
      );
      return created(res, result.data, "Order created successfully");
    } catch (error) {
      if (error.status === 400) {
        return badRequest(res, error.message || "invalid order payload");
      }
      return internalServerError(
        res,
        error?.message || "Failed to create order",
      );
    }
  }

  static async getFinderOrders(req, res) {
    try {
      const pagination = parsePaginationQuery(req.query);
      const result = await OrderService.getFinderOrders(req.user.uid, pagination);
      return okPaginated(
        res,
        result.data,
        result.pagination,
        "Finder orders retrieved successfully",
      );
    } catch (error) {
      return internalServerError(
        res,
        error?.message || "Failed to retrieve finder orders",
      );
    }
  }

  static async getProviderOrders(req, res) {
    try {
      const pagination = parsePaginationQuery(req.query);
      const result = await OrderService.getProviderOrders(
        req.user.uid,
        pagination,
      );
      return okPaginated(
        res,
        result.data,
        result.pagination,
        "Provider orders retrieved successfully",
      );
    } catch (error) {
      return internalServerError(
        res,
        error?.message || "Failed to retrieve provider orders",
      );
    }
  }

  static async updateOrderStatus(req, res) {
    try {
      const orderId = (req.params.id || "").toString().trim();
      if (!orderId) return badRequest(res, "order id is required");
      const targetStatus = (req.body?.status || "").toString();
      const actorRole = (req.body?.actorRole || req.user?.role || "").toString();
      const result = await OrderService.updateOrderStatus(
        req.user.uid,
        req.user,
        orderId,
        targetStatus,
        actorRole,
      );
      return ok(res, result.data, "Order status updated successfully");
    } catch (error) {
      if (error.status === 404) {
        return notFound(res, error.message);
      }
      if (error.status === 403) {
        return forbidden(res, error.message || "forbidden");
      }
      if (error.status === 400) {
        return badRequest(res, error.message);
      }
      return internalServerError(
        res,
        error?.message || "Failed to update order status",
      );
    }
  }
}

export default OrderController;
