import dotenv from "dotenv";

dotenv.config();

export const env = {
    PORT: process.env.PORT || 5000,
    NODE_ENV: process.env.NODE_ENV || "development",
    FIREBASE_SERVICE_ACCOUNT_PATH: process.env.FIREBASE_SERVICE_ACCOUNT_PATH,
    FIREBASE_STORAGE_BUCKET: process.env.FIREBASE_STORAGE_BUCKET,
};

if (!env.FIREBASE_SERVICE_ACCOUNT_PATH) {
    console.warn(" FIREBASE_SERVICE_ACCOUNT_JSON is missing in .env");
}
