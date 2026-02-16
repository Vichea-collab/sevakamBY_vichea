import { Router } from "express";
import healthRoutes from "./health.routes.js";
import authRoutes from "./auth.routes.js";
import userInitRoutes from "./userInit.routes.js";
import providerRoutes from "./provider.routes.js";
import finderRoutes from "./finder.routes.js";
import categoryRoute from './category.routes.js';
import serviceRoutes from './service.routes.js';
import postRoutes from "./post.routes.js";
import orderRoutes from "./order.routes.js";
import chatRoutes from "./chat.routes.js";
import paymentRoutes from "./payment.routes.js";
import adminRoutes from "./admin.routes.js";

const router = Router();

router.use("/health", healthRoutes);
router.use("/auth", authRoutes);
router.use("/providers", providerRoutes);
router.use("/users", userInitRoutes);
router.use("/finders", finderRoutes);
router.use("/categories",categoryRoute);
router.use("/services",serviceRoutes);
router.use("/posts", postRoutes);
router.use("/orders", orderRoutes);
router.use("/chats", chatRoutes);
router.use("/payments", paymentRoutes);
router.use("/admin", adminRoutes);

export default router;
