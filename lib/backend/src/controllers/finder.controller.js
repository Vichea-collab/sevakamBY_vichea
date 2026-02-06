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
}

export default FinderController;