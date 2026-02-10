import {Router} from "express";
import {requireAuth} from "../middlewares/auth.middleware.js";
import FinderController from "../controllers/finder.controller.js";
import { requireRole } from "../middlewares/role.middleware.js";
import { validateFinderProfileUpdate } from "../middlewares/validation.middleware.js";

const router = Router();

router.get("/finder-profile",requireAuth, requireRole(["finder"]), FinderController.getFinderData);
router.put(
  "/finder-profile",
  requireAuth,
  requireRole(["finder"]),
  validateFinderProfileUpdate,
  FinderController.updateFinderData,
);

export default router;
