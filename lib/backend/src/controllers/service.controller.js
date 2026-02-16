import Service from '../services/service.services.js';
import {
    ok,
    okPaginated,
    notFound,
    internalServerError,
    badRequest,
} from "../utils/response.util.js";
import { parsePaginationQuery } from "../utils/pagination.util.js";
class ServiceController {
    static async getServiceById(req, res){
        try {
            const serviceId = req.params.id;
            if(!serviceId){
                return badRequest(res, "Service ID is required");
            }
            const serviceSnap = await Service.getServiceById(serviceId);
            if(!serviceSnap.data){
                return notFound(res, "Service not found");
            }
            return ok (res, serviceSnap.data, "Service retrieved successfully");
        } catch (error) {
            return internalServerError(res, error.message);
        }
    }

    static async getServiceByCategoryId(req, res){
        try {
            const categoryId = req.params.categoryId;
            if(!categoryId){
                return badRequest(res, "Category ID is required");
            }
            const pagination = parsePaginationQuery(req.query);
            const categorySnap = await Service.getServiceByCategoryId(categoryId, pagination);
            return okPaginated(
                res,
                categorySnap.data || [],
                categorySnap.pagination,
                "Services retrieved successfully",
            );
        } catch (error) {
            return internalServerError(res, error.message);
        }
    }

    static async getPopularServices(req, res){
        try {
            const pagination = parsePaginationQuery(req.query);
            const popularServicesSnap = await Service.getPopularServices(pagination);
            return okPaginated(
                res,
                popularServicesSnap.data || [],
                popularServicesSnap.pagination,
                "Popular services retrieved successfully",
            );
        } catch (error) {
            return internalServerError(res, error.message);
        }
    }

    static async getAllServices(req, res){
        try {
            const pagination = parsePaginationQuery(req.query);
            const allServicesSnap = await Service.getAllServices(pagination);
            return okPaginated(
                res,
                allServicesSnap.data || [],
                allServicesSnap.pagination,
                "All services retrieved successfully",
            );
        } catch (error) {
            return internalServerError(res, error.message);
        }
    }
}

export default ServiceController;
