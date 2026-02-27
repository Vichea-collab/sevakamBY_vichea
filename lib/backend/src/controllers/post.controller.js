import PostService from "../services/post.services.js";
import {
  badRequest,
  created,
  forbidden,
  internalServerError,
  notFound,
  ok,
  okPaginated,
} from "../utils/response.util.js";
import { parsePaginationQuery } from "../utils/pagination.util.js";

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
      const pagination = parsePaginationQuery(req.query);
      const result = await PostService.getFinderRequests(pagination);
      return okPaginated(
        res,
        result.data,
        result.pagination,
        "Finder requests retrieved successfully",
      );
    } catch (_) {
      return internalServerError(res, "Failed to retrieve finder requests");
    }
  }

  static async updateFinderRequest(req, res) {
    try {
      const postId = (req.params.id || "").toString().trim();
      if (!postId) {
        return badRequest(res, "post id is required");
      }
      const result = await PostService.updateFinderRequest(
        req.user.uid,
        req.user,
        postId,
        req.body || {},
      );
      return ok(res, result.data, "Finder request updated successfully");
    } catch (error) {
      if (error?.status === 400) {
        return badRequest(res, error.message);
      }
      if (error?.status === 403) {
        return forbidden(res, error.message);
      }
      if (error?.status === 404) {
        return notFound(res, error.message);
      }
      return internalServerError(res, "Failed to update finder request");
    }
  }

  static async deleteFinderRequest(req, res) {
    try {
      const postId = (req.params.id || "").toString().trim();
      if (!postId) {
        return badRequest(res, "post id is required");
      }
      const result = await PostService.deleteFinderRequest(
        req.user.uid,
        req.user,
        postId,
      );
      return ok(res, result.data, "Finder request deleted successfully");
    } catch (error) {
      if (error?.status === 403) {
        return forbidden(res, error.message);
      }
      if (error?.status === 404) {
        return notFound(res, error.message);
      }
      return internalServerError(res, "Failed to delete finder request");
    }
  }

  static async createProviderOffer(req, res) {
    try {
      const result = await PostService.createProviderOffer(
        req.user.uid,
        req.user,
        req.body || {},
      );
      return created(res, result.data, "Provider offer posted successfully");
    } catch (_) {
      return internalServerError(res, "Failed to create provider offer");
    }
  }

  static async getProviderOffers(req, res) {
    try {
      const pagination = parsePaginationQuery(req.query);
      const result = await PostService.getProviderOffers(pagination);
      return okPaginated(
        res,
        result.data,
        result.pagination,
        "Provider offers retrieved successfully",
      );
    } catch (_) {
      return internalServerError(res, "Failed to retrieve provider offers");
    }
  }

  static async updateProviderOffer(req, res) {
    try {
      const postId = (req.params.id || "").toString().trim();
      if (!postId) {
        return badRequest(res, "post id is required");
      }
      const result = await PostService.updateProviderOffer(
        req.user.uid,
        req.user,
        postId,
        req.body || {},
      );
      return ok(res, result.data, "Provider offer updated successfully");
    } catch (error) {
      if (error?.status === 400) {
        return badRequest(res, error.message);
      }
      if (error?.status === 403) {
        return forbidden(res, error.message);
      }
      if (error?.status === 404) {
        return notFound(res, error.message);
      }
      return internalServerError(res, "Failed to update provider offer");
    }
  }

  static async deleteProviderOffer(req, res) {
    try {
      const postId = (req.params.id || "").toString().trim();
      if (!postId) {
        return badRequest(res, "post id is required");
      }
      const result = await PostService.deleteProviderOffer(
        req.user.uid,
        req.user,
        postId,
      );
      return ok(res, result.data, "Provider offer deleted successfully");
    } catch (error) {
      if (error?.status === 403) {
        return forbidden(res, error.message);
      }
      if (error?.status === 404) {
        return notFound(res, error.message);
      }
      return internalServerError(res, "Failed to delete provider offer");
    }
  }
}

export default PostController;
