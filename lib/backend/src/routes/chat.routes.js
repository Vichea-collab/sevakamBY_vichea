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

router.get(
  "/unread-count",
  requireAuth,
  requireRole(["finder", "provider"]),
  ChatController.getUnreadCount,
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

router.get(
  "/:id",
  requireAuth,
  requireRole(["finder", "provider"]),
  ChatController.getThreadById,
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

router.put(
  "/:id/delivered",
  requireAuth,
  requireRole(["finder", "provider"]),
  ChatController.acknowledgeDelivered,
);

export default router;
