import { Router } from "express";
import { requireAuth } from "../middlewares/auth.middleware.js";
import UserController from "../controllers/user.controller.js";

const router = Router();

router.post("/init", requireAuth, UserController.initUser);

export default router;
