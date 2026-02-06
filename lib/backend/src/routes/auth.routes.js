import { Router } from "express";
import { requireAuth } from "../middlewares/auth.middleware.js";
import AuthController from "../controllers/auth.controller.js";

const router = Router();

router.get("/me", requireAuth, AuthController.me);

export default router;
