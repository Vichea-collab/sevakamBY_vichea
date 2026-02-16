import { Router } from "express";
import { requireAuth } from "../middlewares/auth.middleware.js";
import { requireRole } from "../middlewares/role.middleware.js";
import AdminController from "../controllers/admin.controller.js";

const router = Router();

router.get(
  "/overview",
  requireAuth,
  requireRole(["admin"]),
  AdminController.getOverview,
);
router.get(
  "/users",
  requireAuth,
  requireRole(["admin"]),
  AdminController.getUsers,
);
router.get(
  "/orders",
  requireAuth,
  requireRole(["admin"]),
  AdminController.getOrders,
);
router.get(
  "/posts",
  requireAuth,
  requireRole(["admin"]),
  AdminController.getPosts,
);
router.get(
  "/tickets",
  requireAuth,
  requireRole(["admin"]),
  AdminController.getTickets,
);
router.get(
  "/services",
  requireAuth,
  requireRole(["admin"]),
  AdminController.getServices,
);

export default router;
