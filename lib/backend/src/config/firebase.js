import admin from 'firebase-admin';
import {env} from './env.js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const backendRoot = path.resolve(__dirname, '../../');
const serviceAccountPath = env.FIREBASE_SERVICE_ACCOUNT_PATH
    ? path.resolve(backendRoot, env.FIREBASE_SERVICE_ACCOUNT_PATH)
    : '';

if (!serviceAccountPath || !fs.existsSync(serviceAccountPath)) {
    throw new Error(
        `FIREBASE_SERVICE_ACCOUNT_PATH is invalid: ${env.FIREBASE_SERVICE_ACCOUNT_PATH || '(missing)'}`,
    );
}

const serviceAccount = JSON.parse(
    fs.readFileSync(serviceAccountPath, "utf8")
);

if (!admin.apps.length) {
    admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    storageBucket: env.FIREBASE_STORAGE_BUCKET,
    });
}

export const firebaseAdmin = admin;
export const db = admin.firestore();
export const auth = admin.auth();
export const storage = admin.storage();
export const messaging = admin.messaging();
