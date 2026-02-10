import PostService from "../services/post.services.js";
import { created, internalServerError, ok } from "../utils/response.util.js";

class PostController {
  static async createFinderRequest(req, res) {
    try {
      const result = await PostService.createFinderRequest(
        req.user.uid,
        req.user,
        req.body || {},
      );
      return created(res, result.data, "Finder request posted successfully");
    } catch (_) {
      return internalServerError(res, "Failed to create finder request");
    }
  }

  static async getFinderRequests(req, res) {
    try {
      const result = await PostService.getFinderRequests();
      return ok(res, result.data, "Finder requests retrieved successfully");
    } catch (_) {
      return internalServerError(res, "Failed to retrieve finder requests");
    }
  }
}

export default PostController;
