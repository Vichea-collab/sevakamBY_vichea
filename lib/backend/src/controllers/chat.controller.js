import ChatService from "../services/chat.services.js";
import {
  badRequest,
  internalServerError,
  notFound,
  ok,
  okPaginated,
  forbidden,
} from "../utils/response.util.js";
import { parsePaginationQuery } from "../utils/pagination.util.js";

class ChatController {
  static async getUnreadCount(req, res) {
    try {
      const result = await ChatService.getUnreadCount(req.user.uid);
      return ok(res, result.data, "Unread count retrieved successfully");
    } catch (_) {
      return internalServerError(res, "Failed to retrieve unread count");
    }
  }

  static async listThreads(req, res) {
    try {
      const pagination = parsePaginationQuery(req.query);
      const result = await ChatService.listThreads(req.user.uid, pagination);
      return okPaginated(
        res,
        result.data,
        result.pagination,
        "Chats retrieved successfully",
      );
    } catch (_) {
      return internalServerError(res, "Failed to retrieve chats");
    }
  }

  static async openDirectThread(req, res) {
    try {
      const result = await ChatService.openDirectThread(
        req.user.uid,
        req.user,
        req.body || {},
      );
      return ok(res, result.data, "Chat opened successfully");
    } catch (error) {
      if (error.status === 400) return badRequest(res, error.message);
      return internalServerError(res, "Failed to open chat");
    }
  }

  static async listMessages(req, res) {
    try {
      const threadId = (req.params.id || "").toString().trim();
      if (!threadId) return badRequest(res, "chat id is required");
      const pagination = parsePaginationQuery(req.query);
      const result = await ChatService.listMessages(
        req.user.uid,
        threadId,
        pagination,
      );
      return okPaginated(
        res,
        result.data,
        result.pagination,
        "Messages retrieved successfully",
      );
    } catch (error) {
      if (error.status === 403) return forbidden(res, error.message);
      if (error.status === 404) return notFound(res, error.message);
      return internalServerError(res, "Failed to retrieve messages");
    }
  }

  static async getThreadById(req, res) {
    try {
      const threadId = (req.params.id || "").toString().trim();
      if (!threadId) return badRequest(res, "chat id is required");
      const result = await ChatService.getThreadById(req.user.uid, threadId);
      return ok(res, result.data, "Chat retrieved successfully");
    } catch (error) {
      if (error.status === 403) return forbidden(res, error.message);
      if (error.status === 404) return notFound(res, error.message);
      return internalServerError(res, "Failed to retrieve chat");
    }
  }

  static async sendMessage(req, res) {
    try {
      const threadId = (req.params.id || "").toString().trim();
      if (!threadId) return badRequest(res, "chat id is required");
      const result = await ChatService.sendMessage(
        req.user.uid,
        req.user,
        threadId,
        req.body || {},
      );
      return ok(res, result.data, "Message sent successfully");
    } catch (error) {
      if (error.status === 400) return badRequest(res, error.message);
      if (error.status === 403) return forbidden(res, error.message);
      if (error.status === 404) return notFound(res, error.message);
      const reason = (error?.message || "").toString().trim();
      return internalServerError(
        res,
        reason.length === 0
          ? "Failed to send message"
          : `Failed to send message: ${reason}`,
      );
    }
  }

  static async markAsRead(req, res) {
    try {
      const threadId = (req.params.id || "").toString().trim();
      if (!threadId) return badRequest(res, "chat id is required");
      const result = await ChatService.markAsRead(req.user.uid, threadId);
      return ok(res, result.data, "Chat marked as read");
    } catch (error) {
      if (error.status === 403) return forbidden(res, error.message);
      if (error.status === 404) return notFound(res, error.message);
      return internalServerError(res, "Failed to update chat state");
    }
  }

  static async acknowledgeDelivered(req, res) {
    try {
      const threadId = (req.params.id || "").toString().trim();
      if (!threadId) return badRequest(res, "chat id is required");
      const result = await ChatService.acknowledgeDelivered(
        req.user.uid,
        threadId,
        req.body || {},
      );
      return ok(res, result.data, "Delivery acknowledged");
    } catch (error) {
      if (error.status === 403) return forbidden(res, error.message);
      if (error.status === 404) return notFound(res, error.message);
      return internalServerError(res, "Failed to acknowledge delivery");
    }
  }
}

export default ChatController;
