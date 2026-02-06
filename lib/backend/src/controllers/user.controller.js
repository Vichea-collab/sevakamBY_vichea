import UserService  from "../services/user.services.js";    
import { created, internalServerError, badRequest} from "../utils/response.util.js";

class UserController {
    static async initUser(req, res) {
        try{
            const result = await UserService.initUser(req.user, req.body.role);
            return created(res, result.data, "User initialized successfully");
        }catch(err){
            if(err.status === 400){
                return badRequest(res, err.message);
            }
            return internalServerError(res, "User initialization failed",);
        }
    }
}

export default UserController;

