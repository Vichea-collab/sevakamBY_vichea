import FinderService from "../services/finder.services.js";
import { notFound, ok, internalServerError} from "../utils/response.util.js";
class FinderController {
    static async getFinderData(req, res){
        try {
            const finderDoc = await FinderService.getFinderData(req.user.uid);
            if(!finderDoc.data){
                return notFound(res, "Finder data not found");
            }
            return ok(res, finderDoc.data, "Finder data retrieved successfully");
        } catch (error) {
            return internalServerError(res, "Failed to retrieve finder data");
        }
    }

    static async updateFinderData(req, res) {
        try {
            const result = await FinderService.updateFinderData(req.user.uid, req.body || {});
            return ok(res, result.data, "Finder profile updated successfully");
        } catch (error) {
            if (error.status === 404) {
                return notFound(res, error.message);
            }
            return internalServerError(res, "Failed to update finder profile");
        }
    }
}

export default FinderController;
