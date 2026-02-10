import {Router} from "express";
import {requireAuth} from "../middlewares/auth.middleware.js";
import ProviderController from "../controllers/provider.controller.js";
import { requireRole } from "../middlewares/role.middleware.js";
import {
  validateProviderProfileUpdate,
  validateProviderServiceUpdate,
} from "../middlewares/validation.middleware.js";

const router = Router();

router.get("/provider-profile", requireAuth, requireRole(["provider"]), ProviderController.getProviderData);
router.put(
  "/provider-profile",
  requireAuth,
  requireRole(["provider"]),
  validateProviderProfileUpdate,
  ProviderController.updateProviderData,
);
router.put(
  "/update-service",
  requireAuth,
  requireRole(["provider"]),
  validateProviderServiceUpdate,
  ProviderController.updateProviderService,
);

export default router;
