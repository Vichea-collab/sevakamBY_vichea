import { Router } from "express";
import { requireAuth } from "../middlewares/auth.middleware.js";
import { requireRole } from "../middlewares/role.middleware.js";
import {
  validateOrderCreate,
  validateOrderQuote,
  validateOrderStatusUpdate,
} from "../middlewares/validation.middleware.js";
import OrderController from "../controllers/order.controller.js";

const router = Router();

router.post(
  "/quote",
  requireAuth,
  requireRole(["finder"]),
  validateOrderQuote,
  OrderController.quoteFinderOrder,
);

router.post(
  "/",
  requireAuth,
  requireRole(["finder"]),
  validateOrderCreate,
  OrderController.createFinderOrder,
);

router.get(
  "/finder",
  requireAuth,
  requireRole(["finder"]),
  OrderController.getFinderOrders,
);

router.get(
  "/provider",
  requireAuth,
  requireRole(["provider"]),
  OrderController.getProviderOrders,
);

router.put(
  "/:id/status",
  requireAuth,
  requireRole(["finder", "provider"]),
  validateOrderStatusUpdate,
  OrderController.updateOrderStatus,
);

export default router;
