import CategoryService from "../services/category.services.js";
import {
    ok,
    okPaginated,
    notFound,
    internalServerError,
    badRequest,
} from "../utils/response.util.js";
import { parsePaginationQuery } from "../utils/pagination.util.js";

class CategoryController {
    static async getAllCategories(req, res){
        try {
            const pagination = parsePaginationQuery(req.query);
            const result = await CategoryService.getAllCategories(pagination);
            return okPaginated(
                res,
                result.data || [],
                result.pagination,
                "Retrieved categories successfully",
            );
        } catch (error) {
            return internalServerError(res, "Failed to retrieve category");
        }
    }

    static async getCategoryById(req, res){
        try {
            const categoryId = req.params.id;
            if(!categoryId){
                return badRequest(res, "Category ID is required");
            }
            const result = await CategoryService.getCategoryById(categoryId);
            if(!result.data){
                return notFound(res, "Category not found");
            }
            return ok(res, result.data, "Category retrieved successfully");
        } catch (error) {
            return internalServerError(res, "Failed to retrieve category");
        }
    }
}

export default CategoryController;
