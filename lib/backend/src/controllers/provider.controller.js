import ProviderService from "../services/provider.services.js";
import { notFound, ok,internalServerError,noContent} from '../utils/response.util.js';

class ProviderController {
    static async getProviderData(req, res){
        try {
            const providerDoc = await ProviderService.getProviderData(req.user.uid);
            if(!providerDoc.data){
                return notFound(res, "Provider data not found");
            }
            return ok(res, providerDoc.data, "Provider data retrieved successfully");
        } catch (error) {
            return internalServerError(res, "Failed to retrieve provider data");
        }
    }

    static async updateProviderService(req, res){
        try {
            const {service} = req.body;
            const result = await ProviderService.updateProviderService(req.user.uid, service);
            return noContent(res, "Provider service updated successfully");
        } catch (error) {
            if(error.status === 400){
                return notFound(res, error.message);
            }
            return internalServerError(res, "Failed to update provider service");
        }
    }
}
export default ProviderController;