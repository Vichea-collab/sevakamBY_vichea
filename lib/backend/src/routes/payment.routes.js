import { Router } from "express";
import { requireAuth } from "../middlewares/auth.middleware.js";
import { requireRole } from "../middlewares/role.middleware.js";
import {
  validateKhqrCreate,
  validateKhqrVerify,
} from "../middlewares/validation.middleware.js";
import PaymentController from "../controllers/payment.controller.js";

const router = Router();

router.post(
  "/khqr/create",
  requireAuth,
  requireRole(["finder"]),
  validateKhqrCreate,
  PaymentController.createKhqrSession,
);

router.post(
  "/khqr/verify",
  requireAuth,
  requireRole(["finder"]),
  validateKhqrVerify,
  PaymentController.verifyKhqrPayment,
);

router.post("/khqr/webhook", PaymentController.khqrWebhook);

export default router;
