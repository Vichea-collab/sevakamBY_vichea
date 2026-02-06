import CategoryService from "../services/category.services.js";
import {ok, notFound, internalServerError, badRequest} from "../utils/response.util.js";

class CategoryController {
    static async getAllCategories(req, res){
        try {
            const result = await CategoryService.getAllCategories(); 
            if(result.data.length == 0){
                return notFound(res,"no categories found");
            }
            return ok(res,result.data,"Retrieved categories successfully");
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