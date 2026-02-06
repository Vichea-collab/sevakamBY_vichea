import CategoryController from "../controllers/category.controller.js";
import {Router} from "express";

const router = Router();

router.get("/allCategories",CategoryController.getAllCategories);
router.get("/:id",CategoryController.getCategoryById);

export default router;
