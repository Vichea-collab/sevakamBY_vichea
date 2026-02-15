import dotenv from "dotenv";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const backendRoot = path.resolve(__dirname, "../../");

dotenv.config({ path: path.join(backendRoot, ".env") });

export const env = {
    PORT: process.env.PORT || 5000,
    NODE_ENV: process.env.NODE_ENV || "development",
    FIREBASE_SERVICE_ACCOUNT_PATH: process.env.FIREBASE_SERVICE_ACCOUNT_PATH,
    FIREBASE_STORAGE_BUCKET: process.env.FIREBASE_STORAGE_BUCKET,
    BAKONG_BASE_URL: process.env.BAKONG_BASE_URL || "",
    BAKONG_KHQR_CHECK_PATH:
        process.env.BAKONG_KHQR_CHECK_PATH ||
        process.env.BAKONG_KHQR_VERIFY_PATH ||
        "/khqr/check_transaction_by_md5",
    BAKONG_KHQR_CHECK_METHOD: process.env.BAKONG_KHQR_CHECK_METHOD || "POST",
    BAKONG_PARTNER_TOKEN: process.env.BAKONG_PARTNER_TOKEN || "",
    BAKONG_MERCHANT_ID: process.env.BAKONG_MERCHANT_ID || "",
    BAKONG_TERMINAL_ID: process.env.BAKONG_TERMINAL_ID || "",
    BAKONG_KHQR_ACCOUNT:
        process.env.BAKONG_KHQR_ACCOUNT || process.env.BAKONG_MERCHANT_ID || "",
    BAKONG_KHQR_MERCHANT_NAME: process.env.BAKONG_KHQR_MERCHANT_NAME || "Service Provider",
    BAKONG_KHQR_MERCHANT_CITY: process.env.BAKONG_KHQR_MERCHANT_CITY || "Phnom Penh",
    BAKONG_KHQR_MERCHANT_CATEGORY: process.env.BAKONG_KHQR_MERCHANT_CATEGORY || "5999",
    BAKONG_KHQR_EXP_MINUTES: Number(process.env.BAKONG_KHQR_EXP_MINUTES || 30),
    BAKONG_CURRENCY: process.env.BAKONG_CURRENCY || "USD",
    BAKONG_RETURN_URL: process.env.BAKONG_RETURN_URL || "",
    BAKONG_WEBHOOK_URL: process.env.BAKONG_WEBHOOK_URL || "",
    BAKONG_WEBHOOK_SECRET: process.env.BAKONG_WEBHOOK_SECRET || "",
    BAKONG_ALLOW_MOCK: (process.env.BAKONG_ALLOW_MOCK || "false").toLowerCase() === "true",
    CHAT_IMAGE_MAX_BYTES: Number(process.env.CHAT_IMAGE_MAX_BYTES || 10485760),
    CHAT_IMAGE_INLINE_FALLBACK:
        (process.env.CHAT_IMAGE_INLINE_FALLBACK || "true").toLowerCase() === "true",
    CHAT_IMAGE_INLINE_MAX_BYTES: Number(process.env.CHAT_IMAGE_INLINE_MAX_BYTES || 716800),
};

if (!env.FIREBASE_SERVICE_ACCOUNT_PATH) {
    console.warn("FIREBASE_SERVICE_ACCOUNT_PATH is missing in .env");
}
