import { badRequest } from "../utils/response.util.js";

const EMAIL_REGEX = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

function isObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function isNonEmptyString(value) {
  return typeof value === "string" && value.trim().length > 0;
}

function hasAnyField(body, keys) {
  return keys.some((key) => body[key] !== undefined);
}

function toPositiveInt(value) {
  const parsed = Number.parseInt((value ?? "").toString(), 10);
  if (!Number.isFinite(parsed) || parsed < 1) return null;
  return parsed;
}

function withValidation(validator) {
  return (req, res, next) => {
    try {
      const error = validator(req);
      if (error) return badRequest(res, error);
      return next();
    } catch (_) {
      return badRequest(res, "Invalid request body");
    }
  };
}

export const validateUserInit = withValidation((req) => {
  const role = (req.body?.role ?? "").toString().trim().toLowerCase();
  if (!["finder", "provider"].includes(role)) {
    return "role must be finder or provider";
  }
  return null;
});

export const validateUserProfileUpdate = withValidation((req) => {
  const body = req.body || {};
  if (!isObject(body)) return "Invalid body";
  if (!hasAnyField(body, ["name", "email", "photoUrl"])) {
    return "At least one profile field is required";
  }
  if (body.name !== undefined && !isNonEmptyString(body.name)) {
    return "name must be a non-empty string";
  }
  if (body.email !== undefined) {
    if (!isNonEmptyString(body.email)) return "email must be a non-empty string";
    if (!EMAIL_REGEX.test(body.email)) return "email format is invalid";
  }
  if (body.photoUrl !== undefined && !isNonEmptyString(body.photoUrl)) {
    return "photoUrl must be a non-empty string";
  }
  return null;
});

export const validateUserSettingsUpdate = withValidation((req) => {
  const body = req.body || {};
  if (!isObject(body)) return "Invalid body";
  if (!hasAnyField(body, ["paymentMethod", "notifications"])) {
    return "paymentMethod or notifications is required";
  }

  if (body.paymentMethod !== undefined) {
    const payment = body.paymentMethod.toString().trim().toLowerCase();
    const allowed = ["credit_card", "cash", "khqr"];
    if (!allowed.includes(payment)) {
      return "paymentMethod must be credit_card, cash, or khqr";
    }
  }
  if (body.notifications !== undefined && !isObject(body.notifications)) {
    return "notifications must be an object";
  }
  return null;
});

export const validateHelpTicketCreate = withValidation((req) => {
  const body = req.body || {};
  if (!isObject(body)) return "Invalid body";
  if (!isNonEmptyString(body.title)) return "title is required";
  if (!isNonEmptyString(body.message)) return "message is required";
  return null;
});

export const validateUserAddressCreate = withValidation((req) => {
  const body = req.body || {};
  if (!isObject(body)) return "Invalid body";
  if (!isNonEmptyString(body.label)) return "label is required";
  if (!isNonEmptyString(body.street)) return "street is required";
  if (!isNonEmptyString(body.city)) return "city is required";
  if (body.mapLink !== undefined && !isNonEmptyString(body.mapLink)) {
    return "mapLink must be a non-empty string";
  }
  if (body.isDefault !== undefined && typeof body.isDefault !== "boolean") {
    return "isDefault must be a boolean";
  }
  return null;
});

export const validateFinderProfileUpdate = withValidation((req) => {
  const body = req.body || {};
  if (!isObject(body)) return "Invalid body";
  if (!hasAnyField(body, ["city", "location", "phoneNumber", "birthday"])) {
    return "At least one finder profile field is required";
  }
  if (body.city !== undefined && !isNonEmptyString(body.city)) {
    return "city must be a non-empty string";
  }
  if (body.location !== undefined && !isNonEmptyString(body.location)) {
    return "location must be a non-empty string";
  }
  if (body.phoneNumber !== undefined && !isNonEmptyString(body.phoneNumber)) {
    return "phoneNumber must be a non-empty string";
  }
  if (body.birthday !== undefined && !isNonEmptyString(body.birthday)) {
    return "birthday must be a non-empty string";
  }
  return null;
});

export const validateProviderProfileUpdate = withValidation((req) => {
  const body = req.body || {};
  if (!isObject(body)) return "Invalid body";
  if (
    !hasAnyField(body, [
      "city",
      "phoneNumber",
      "birthday",
      "bio",
      "serviceName",
      "expertIn",
      "availableFrom",
      "availableTo",
      "experienceYears",
      "serviceArea",
      "providerType",
      "companyName",
      "maxWorkers",
    ])
  ) {
    return "At least one provider profile field is required";
  }
  if (body.city !== undefined && !isNonEmptyString(body.city)) {
    return "city must be a non-empty string";
  }
  if (body.phoneNumber !== undefined && !isNonEmptyString(body.phoneNumber)) {
    return "phoneNumber must be a non-empty string";
  }
  if (body.birthday !== undefined && !isNonEmptyString(body.birthday)) {
    return "birthday must be a non-empty string";
  }
  if (body.bio !== undefined && !isNonEmptyString(body.bio)) {
    return "bio must be a non-empty string";
  }
  if (body.serviceName !== undefined && !isNonEmptyString(body.serviceName)) {
    return "serviceName must be a non-empty string";
  }
  if (body.expertIn !== undefined && !isNonEmptyString(body.expertIn)) {
    return "expertIn must be a non-empty string";
  }
  if (
    body.availableFrom !== undefined &&
    !isNonEmptyString(body.availableFrom)
  ) {
    return "availableFrom must be a non-empty string";
  }
  if (body.availableTo !== undefined && !isNonEmptyString(body.availableTo)) {
    return "availableTo must be a non-empty string";
  }
  if (
    body.experienceYears !== undefined &&
    body.experienceYears.toString().trim().isEmpty
  ) {
    return "experienceYears must be a non-empty value";
  }
  if (
    body.serviceArea !== undefined &&
    !isNonEmptyString(body.serviceArea)
  ) {
    return "serviceArea must be a non-empty string";
  }
  if (body.providerType !== undefined) {
    const providerType = body.providerType.toString().trim().toLowerCase();
    if (!["individual", "company"].includes(providerType)) {
      return "providerType must be individual or company";
    }
    if (providerType === "company") {
      if (body.companyName !== undefined && !isNonEmptyString(body.companyName)) {
        return "companyName must be a non-empty string";
      }
      if (body.maxWorkers !== undefined && toPositiveInt(body.maxWorkers) === null) {
        return "maxWorkers must be greater than 0";
      }
    }
  }
  if (
    body.companyName !== undefined &&
    body.providerType === undefined &&
    !isNonEmptyString(body.companyName)
  ) {
    return "companyName must be a non-empty string";
  }
  if (
    body.maxWorkers !== undefined &&
    body.providerType === undefined &&
    toPositiveInt(body.maxWorkers) === null
  ) {
    return "maxWorkers must be greater than 0";
  }
  return null;
});

export const validateProviderServiceUpdate = withValidation((req) => {
  const body = req.body || {};
  if (!isObject(body) || !isObject(body.service)) return "service object is required";
  const service = body.service;
  if (!isNonEmptyString(service.serviceId)) return "service.serviceId is required";
  if (!isNonEmptyString(service.serviceName)) return "service.serviceName is required";
  if (!isNonEmptyString(service.serviceImageUrl)) {
    return "service.serviceImageUrl is required";
  }
  return null;
});

export const validateFinderPostCreate = withValidation((req) => {
  const body = req.body || {};
  if (!isObject(body)) return "Invalid body";
  if (!isNonEmptyString(body.category)) return "category is required";
  if (!isNonEmptyString(body.service)) return "service is required";
  if (body.location !== undefined && !isNonEmptyString(body.location)) {
    return "location must be a non-empty string";
  }
  if (!isNonEmptyString(body.message)) return "message is required";

  if (body.preferredDate !== undefined) {
    const date = new Date(body.preferredDate);
    if (Number.isNaN(date.getTime())) {
      return "preferredDate must be a valid date string";
    }
  }
  return null;
});

export const validateProviderPostCreate = withValidation((req) => {
  const body = req.body || {};
  if (!isObject(body)) return "Invalid body";
  if (!isNonEmptyString(body.category)) return "category is required";
  if (!isNonEmptyString(body.service)) return "service is required";
  if (!isNonEmptyString(body.area)) return "area is required";
  if (!isNonEmptyString(body.details)) return "details is required";

  const rate = Number(body.ratePerHour);
  if (!Number.isFinite(rate) || rate <= 0) {
    return "ratePerHour must be greater than 0";
  }
  if (body.availableNow !== undefined && typeof body.availableNow !== "boolean") {
    return "availableNow must be a boolean";
  }
  return null;
});

export const validateAdminBroadcastCreate = withValidation((req) => {
  const body = req.body || {};
  if (!isObject(body)) return "Invalid body";
  if (!isNonEmptyString(body.title)) return "title is required";
  if (!isNonEmptyString(body.message)) return "message is required";

  if (body.type !== undefined) {
    const type = body.type.toString().trim().toLowerCase();
    if (!["system", "promotion", "promo"].includes(type)) {
      return "type must be system or promotion";
    }
  }

  if (body.targetRoles !== undefined) {
    if (!Array.isArray(body.targetRoles)) {
      return "targetRoles must be an array";
    }
    const invalid = body.targetRoles.some((role) => {
      const normalized = (role || "").toString().trim().toLowerCase();
      return !["finder", "provider"].includes(normalized);
    });
    if (invalid) return "targetRoles accepts finder/provider only";
  }

  if (body.active !== undefined && typeof body.active !== "boolean") {
    return "active must be a boolean";
  }

  if (body.startAt !== undefined && !isNonEmptyString(body.startAt)) {
    return "startAt must be an ISO date string";
  }
  if (body.endAt !== undefined && !isNonEmptyString(body.endAt)) {
    return "endAt must be an ISO date string";
  }

  if (body.promoCode !== undefined && !isNonEmptyString(body.promoCode)) {
    return "promoCode must be a non-empty string";
  }
  if (body.discountType !== undefined) {
    const discountType = body.discountType.toString().trim().toLowerCase();
    if (!["percent", "fixed"].includes(discountType)) {
      return "discountType must be percent or fixed";
    }
  }
  if (
    body.discountValue !== undefined &&
    (!Number.isFinite(Number(body.discountValue)) || Number(body.discountValue) <= 0)
  ) {
    return "discountValue must be greater than 0";
  }
  if (
    body.minSubtotal !== undefined &&
    (!Number.isFinite(Number(body.minSubtotal)) || Number(body.minSubtotal) < 0)
  ) {
    return "minSubtotal must be >= 0";
  }
  if (
    body.maxDiscount !== undefined &&
    (!Number.isFinite(Number(body.maxDiscount)) || Number(body.maxDiscount) < 0)
  ) {
    return "maxDiscount must be >= 0";
  }
  if (
    body.usageLimit !== undefined &&
    (!Number.isFinite(Number(body.usageLimit)) || Number(body.usageLimit) < 0)
  ) {
    return "usageLimit must be >= 0";
  }

  if (
    body.promoCode !== undefined &&
    body.discountValue === undefined
  ) {
    return "discountValue is required when promoCode is provided";
  }

  return null;
});

export const validateAdminBroadcastActiveUpdate = withValidation((req) => {
  const body = req.body || {};
  if (!isObject(body)) return "Invalid body";
  if (typeof body.active !== "boolean") {
    return "active is required";
  }
  return null;
});

export const validateOrderCreate = withValidation((req) => {
  const body = req.body || {};
  if (!isObject(body)) return "Invalid body";
  if (!isNonEmptyString(body.categoryName ?? body.category)) {
    return "categoryName is required";
  }
  if (!isNonEmptyString(body.serviceName ?? body.service)) {
    return "serviceName is required";
  }
  if (!isNonEmptyString(body.addressStreet)) return "addressStreet is required";
  if (!isNonEmptyString(body.addressCity)) return "addressCity is required";
  if (!isNonEmptyString(body.preferredDate)) return "preferredDate is required";
  if (!isNonEmptyString(body.preferredTimeSlot)) {
    return "preferredTimeSlot is required";
  }
  if (!isNonEmptyString(body.paymentMethod)) return "paymentMethod is required";
  const paymentMethod = body.paymentMethod.toString().trim().toLowerCase();
  const allowedPaymentMethods = ["credit_card", "cash", "khqr"];
  if (!allowedPaymentMethods.includes(paymentMethod)) {
    return "paymentMethod must be credit_card, cash, or khqr";
  }
  if (body.providerUid !== undefined && typeof body.providerUid !== "string") {
    return "providerUid must be a string";
  }
  if (body.hours !== undefined && Number(body.hours) <= 0) {
    return "hours must be greater than 0";
  }
  if (body.workers !== undefined && Number(body.workers) <= 0) {
    return "workers must be greater than 0";
  }
  return null;
});

export const validateOrderQuote = withValidation((req) => {
  const body = req.body || {};
  if (!isObject(body)) return "Invalid body";
  if (!isNonEmptyString(body.categoryName ?? body.category)) {
    return "categoryName is required";
  }
  if (!isNonEmptyString(body.serviceName ?? body.service)) {
    return "serviceName is required";
  }
  if (body.hours !== undefined && Number(body.hours) <= 0) {
    return "hours must be greater than 0";
  }
  if (body.workers !== undefined && Number(body.workers) <= 0) {
    return "workers must be greater than 0";
  }
  if (
    body.promoCode !== undefined &&
    typeof body.promoCode !== "string"
  ) {
    return "promoCode must be a string";
  }
  return null;
});

export const validateOrderStatusUpdate = withValidation((req) => {
  const body = req.body || {};
  if (!isObject(body)) return "Invalid body";
  if (!isNonEmptyString(body.status)) return "status is required";
  const status = body.status.toString().trim().toLowerCase();
  const allowed = [
    "booked",
    "on_the_way",
    "started",
    "completed",
    "cancelled",
    "declined",
  ];
  if (!allowed.includes(status)) {
    return "invalid order status";
  }
  if (body.actorRole !== undefined) {
    const actorRole = body.actorRole.toString().trim().toLowerCase();
    if (!["finder", "provider"].includes(actorRole)) {
      return "actorRole must be finder or provider";
    }
  }
  return null;
});

export const validateKhqrCreate = withValidation((req) => {
  const body = req.body || {};
  if (!isObject(body)) return "Invalid body";
  if (!isNonEmptyString(body.orderId)) return "orderId is required";
  return null;
});

export const validateKhqrVerify = withValidation((req) => {
  const body = req.body || {};
  if (!isObject(body)) return "Invalid body";
  if (!isNonEmptyString(body.orderId)) return "orderId is required";
  if (body.transactionId !== undefined && !isNonEmptyString(body.transactionId)) {
    return "transactionId must be a non-empty string";
  }
  return null;
});
