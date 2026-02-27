import { Router } from "express";
import { requireAuth } from "../middlewares/auth.middleware.js";
import { requireRole } from "../middlewares/role.middleware.js";
import {
  validateFinderPostCreate,
  validateFinderPostUpdate,
  validateProviderPostCreate,
  validateProviderPostUpdate,
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
router.put(
  "/finder-requests/:id",
  requireAuth,
  requireRole(["finder"]),
  validateFinderPostUpdate,
  PostController.updateFinderRequest,
);
router.delete(
  "/finder-requests/:id",
  requireAuth,
  requireRole(["finder"]),
  PostController.deleteFinderRequest,
);

router.get(
  "/provider-offers",
  requireAuth,
  requireRole(["provider", "finder"]),
  PostController.getProviderOffers,
);

router.post(
  "/provider-offers",
  requireAuth,
  requireRole(["provider"]),
  validateProviderPostCreate,
  PostController.createProviderOffer,
);
router.put(
  "/provider-offers/:id",
  requireAuth,
  requireRole(["provider"]),
  validateProviderPostUpdate,
  PostController.updateProviderOffer,
);
router.delete(
  "/provider-offers/:id",
  requireAuth,
  requireRole(["provider"]),
  PostController.deleteProviderOffer,
);

export default router;
