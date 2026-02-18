import { Router } from "express";
import { requireAuth } from "../middlewares/auth.middleware.js";
import UserController from "../controllers/user.controller.js";
import {
  validateUserAddressCreate,
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

export default router;
