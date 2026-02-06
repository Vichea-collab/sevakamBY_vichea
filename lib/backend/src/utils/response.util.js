export function ok(res, data = null, message = "OK") {
    sendResponse(res, 200, true, message, data);
}

export function created(res, data = null, message = "Created") {
    sendResponse(res, 201, true, message, data);
}

export function badRequest(res, message = "Bad Request", data = null) {
    sendResponse(res, 400, false, message, data);
}

export function unauthorized(res, message = "Unauthorized", data = null) {
    sendResponse(res, 401, false, message, data);
}

export function forbidden(res, message = "Forbidden", data = null) {
    sendResponse(res, 403, false, message, data);
}

export function notFound(res, message = "Not Found", data = null) {
    sendResponse(res, 404, false, message, data);
}

export function internalServerError(res, message = "Internal Server Error", data = null) {
    sendResponse(res, 500, false, message, data);
}

export function noContent(res,message = "No Content") {
    return sendResponse(res, 204, true, message);
}

export function sendResponse(res, status, success, message, data = null) {
    return res.status(status).json({
        success,
        message,
        data
    });
}

