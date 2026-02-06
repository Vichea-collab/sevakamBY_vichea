import {Router} from "express";
import {requireAuth} from "../middlewares/auth.middleware.js";
import ProviderController from "../controllers/provider.controller.js";
import { requireRole } from "../middlewares/role.middleware.js";

const router = Router();

router.get("/provider-profile", requireAuth, requireRole(["providers"]), ProviderController.getProviderData);
router.put("/update-service", requireAuth, requireRole(["providers"]), ProviderController.updateProviderService);

export default router;