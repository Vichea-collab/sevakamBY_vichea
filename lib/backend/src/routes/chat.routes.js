import { Router } from "express";
import { requireAuth } from "../middlewares/auth.middleware.js";
import { requireRole } from "../middlewares/role.middleware.js";
import ChatController from "../controllers/chat.controller.js";

const router = Router();

router.get(
  "/",
  requireAuth,
  requireRole(["finder", "provider"]),
  ChatController.listThreads,
);

router.post(
  "/direct",
  requireAuth,
  requireRole(["finder", "provider"]),
  ChatController.openDirectThread,
);

router.get(
  "/:id/messages",
  requireAuth,
  requireRole(["finder", "provider"]),
  ChatController.listMessages,
);

router.post(
  "/:id/messages",
  requireAuth,
  requireRole(["finder", "provider"]),
  ChatController.sendMessage,
);

router.put(
  "/:id/read",
  requireAuth,
  requireRole(["finder", "provider"]),
  ChatController.markAsRead,
);

export default router;
