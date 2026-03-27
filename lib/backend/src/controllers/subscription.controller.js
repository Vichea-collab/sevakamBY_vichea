import SubscriptionService from "../services/subscription.services.js";
import {
  badRequest,
  forbidden,
  internalServerError,
  notFound,
  ok,
} from "../utils/response.util.js";

class SubscriptionController {
  static async getStatus(req, res) {
    try {
      const result = await SubscriptionService.getStatus(req.user.uid);
      return ok(res, result.data, "Subscription status retrieved");
    } catch (error) {
      if (error.status === 404) return notFound(res, error.message);
      return internalServerError(res, "Failed to get subscription status");
    }
  }

  static async createCheckout(req, res) {
    try {
      const result = await SubscriptionService.createCheckoutSession(
        req.user.uid,
        req.body || {},
      );
      return ok(res, result.data, "Checkout session created");
    } catch (error) {
      if (error.status === 400) return badRequest(res, error.message);
      if (error.status === 404) return notFound(res, error.message);
      console.error("[SubscriptionController] createCheckout error:", error);
      return internalServerError(res, "Failed to create checkout session");
    }
  }

  static async cancel(req, res) {
    try {
      const result = await SubscriptionService.cancelSubscription(req.user.uid);
      return ok(res, result.data, "Subscription cancelled and downgraded to Basic");
    } catch (error) {
      if (error.status === 400) return badRequest(res, error.message);
      if (error.status === 404) return notFound(res, error.message);
      return internalServerError(res, "Failed to cancel subscription");
    }
  }

  static async verifyCheckout(req, res) {
    try {
      const result = await SubscriptionService.verifyCheckoutSession(
        req.user.uid,
        req.body || {},
      );
      return ok(res, result.data, "Checkout verified");
    } catch (error) {
      if (error.status === 400) return badRequest(res, error.message);
      if (error.status === 403) return forbidden(res, error.message);
      if (error.status === 404) return notFound(res, error.message);
      console.error("[SubscriptionController] verifyCheckout error:", error);
      if (error.stack) console.error(error.stack);
      return internalServerError(res, "Failed to verify checkout");
    }
  }

  static async webhook(req, res) {
    try {
      const signature = req.headers["stripe-signature"] || "";
      const result = await SubscriptionService.handleWebhook(req.body, signature);
      return ok(res, result.data, "Webhook processed");
    } catch (error) {
      if (error.status === 400) return badRequest(res, error.message);
      console.error("[SubscriptionController] webhook error:", error);
      return internalServerError(res, "Failed to process webhook");
    }
  }
}

export default SubscriptionController;
