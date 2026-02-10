import { Router } from "express";
import { requireAuth } from "../middlewares/auth.middleware.js";
import UserController from "../controllers/user.controller.js";
import {
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

export default router;
