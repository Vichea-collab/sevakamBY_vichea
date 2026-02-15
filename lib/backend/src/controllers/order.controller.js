import OrderService from "../services/order.services.js";
import {
  badRequest,
  created,
  internalServerError,
  notFound,
  ok,
} from "../utils/response.util.js";

class OrderController {
  static async createFinderOrder(req, res) {
    try {
      const result = await OrderService.createFinderOrder(
        req.user.uid,
        req.user,
        req.body || {},
      );
      return created(res, result.data, "Order created successfully");
    } catch (error) {
      return internalServerError(
        res,
        error?.message || "Failed to create order",
      );
    }
  }

  static async getFinderOrders(req, res) {
    try {
      const result = await OrderService.getFinderOrders(req.user.uid);
      return ok(res, result.data, "Finder orders retrieved successfully");
    } catch (error) {
      return internalServerError(
        res,
        error?.message || "Failed to retrieve finder orders",
      );
    }
  }

  static async getProviderOrders(req, res) {
    try {
      const result = await OrderService.getProviderOrders(req.user.uid);
      return ok(res, result.data, "Provider orders retrieved successfully");
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
