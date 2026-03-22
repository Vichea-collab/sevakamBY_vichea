import { Router } from "express";
import { requireAuth } from "../middlewares/auth.middleware.js";
import UserController from "../controllers/user.controller.js";
import {
  validateUserAddressCreate,
  validateUserAddressUpdate,
  validateHelpTicketCreate,
  validateUserInit,
  validateUserProfileUpdate,
  validateUserSettingsUpdate,
} from "../middlewares/validation.middleware.js";

const router = Router();

router.post("/init", requireAuth, validateUserInit, UserController.initUser);
router.put(
  "/profile",
  requireAuth,
  validateUserProfileUpdate,
  UserController.updateProfile,
);
router.get("/settings", requireAuth, UserController.getSettings);
router.get("/notifications", requireAuth, UserController.getNotifications);
router.get("/promotions", requireAuth, UserController.getPromotions);
router.get(
  "/notifications/read-state",
  requireAuth,
  UserController.getNotificationReadState,
);
router.put(
  "/notifications/read-state",
  requireAuth,
  UserController.updateNotificationReadState,
);
router.put("/push-token", requireAuth, UserController.registerPushToken);
router.post("/push-token/remove", requireAuth, UserController.unregisterPushToken);
router.put(
  "/settings",
  requireAuth,
  validateUserSettingsUpdate,
  UserController.updateSettings,
);
router.get("/help-tickets", requireAuth, UserController.getHelpTickets);
router.post(
  "/help-tickets",
  requireAuth,
  validateHelpTicketCreate,
  UserController.createHelpTicket,
);
router.get(
  "/help-tickets/:id/messages",
  requireAuth,
  UserController.getHelpTicketMessages,
);
router.post(
  "/help-tickets/:id/messages",
  requireAuth,
  UserController.sendHelpTicketMessage,
);
router.get("/addresses", requireAuth, UserController.getAddresses);
router.post(
  "/addresses",
  requireAuth,
  validateUserAddressCreate,
  UserController.createAddress,
);
router.put(
  "/addresses/:id",
  requireAuth,
  validateUserAddressUpdate,
  UserController.updateAddress,
);
router.delete("/addresses/:id", requireAuth, UserController.deleteAddress);

export default router;
