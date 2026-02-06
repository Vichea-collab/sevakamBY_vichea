import Service from '../services/service.services.js';
import {ok, notFound, internalServerError, badRequest} from "../utils/response.util.js";
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
            const categorySnap = await Service.getServiceByCategoryId(categoryId);
            if(categorySnap.data.length === 0){
                return notFound(res, "No services found for this category");
            }
            return ok (res, categorySnap.data, "Services retrieved successfully");
        } catch (error) {
            return internalServerError(res, error.message);
        }
    }

    static async getPopularServices(req, res){
        try {
            const popularServicesSnap = await Service.getPopularServices();
            if(popularServicesSnap.data.length === 0){
                return notFound(res, "No popular services found");
            }
            return ok (res, popularServicesSnap.data, "Popular services retrieved successfully");
        } catch (error) {
            return internalServerError(res, error.message);
        }
    }

    static async getAllServices(req, res){
        try {
            const allServicesSnap = await Service.getAllServices();
            if(allServicesSnap.data.length === 0){
                return notFound(res, "No services found");
            }
            return ok (res, allServicesSnap.data, "All services retrieved successfully");
        } catch (error) {
            return internalServerError(res, error.message);
        }
    }
}

export default ServiceController;