import PaymentService from "../services/payment.services.js";
import {
  badRequest,
  forbidden,
  internalServerError,
  notFound,
  ok,
} from "../utils/response.util.js";

class PaymentController {
  static async createKhqrSession(req, res) {
    try {
      const result = await PaymentService.createKhqrSession(
        req.user.uid,
        req.body || {},
      );
      return ok(res, result.data, "KHQR session created successfully");
    } catch (error) {
      if (error.status === 403) return forbidden(res, error.message);
      if (error.status === 404) return notFound(res, error.message);
      if (error.status === 400) return badRequest(res, error.message);
      return internalServerError(res, "Failed to create KHQR session");
    }
  }

  static async verifyKhqrPayment(req, res) {
    try {
      const result = await PaymentService.verifyKhqrPayment(
        req.user.uid,
        req.body || {},
      );
      return ok(res, result.data, "KHQR payment verification completed");
    } catch (error) {
      if (error.status === 403) return forbidden(res, error.message);
      if (error.status === 404) return notFound(res, error.message);
      if (error.status === 400) return badRequest(res, error.message);
      return internalServerError(res, "Failed to verify KHQR payment");
    }
  }

  static async khqrWebhook(req, res) {
    try {
      const result = await PaymentService.webhookKhqr(
        req.body || {},
        req.headers || {},
      );
      return ok(res, result.data, "Webhook processed");
    } catch (error) {
      if (error.status === 403) return forbidden(res, error.message);
      if (error.status === 404) return notFound(res, error.message);
      if (error.status === 400) return badRequest(res, error.message);
      return internalServerError(res, "Failed to process webhook");
    }
  }
}

export default PaymentController;
