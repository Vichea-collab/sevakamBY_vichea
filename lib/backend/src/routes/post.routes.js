import { Router } from "express";
import { requireAuth } from "../middlewares/auth.middleware.js";
import { requireRole } from "../middlewares/role.middleware.js";
import {
  validateFinderPostCreate,
} from "../middlewares/validation.middleware.js";
import PostController from "../controllers/post.controller.js";

const router = Router();

router.get(
  "/finder-requests",
  requireAuth,
  requireRole(["provider", "finder"]),
  PostController.getFinderRequests,
);

router.post(
  "/finder-requests",
  requireAuth,
  requireRole(["finder"]),
  validateFinderPostCreate,
  PostController.createFinderRequest,
);

export default router;
