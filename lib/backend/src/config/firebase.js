import admin from 'firebase-admin';
import {env} from './env.js';
import fs from 'fs';

const serviceAccount = JSON.parse(
    fs.readFileSync(env.FIREBASE_SERVICE_ACCOUNT_PATH, "utf8")
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

