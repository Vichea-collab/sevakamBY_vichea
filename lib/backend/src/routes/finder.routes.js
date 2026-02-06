import {Router} from "express";
import {requireAuth} from "../middlewares/auth.middleware.js";
import FinderController from "../controllers/finder.controller.js";
import { requireRole } from "../middlewares/role.middleware.js";

const router = Router();

router.get("/finder-profile",requireAuth, requireRole(["finders"]), FinderController.getFinderData);

export default router;