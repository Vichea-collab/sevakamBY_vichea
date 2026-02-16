import admin from "firebase-admin";
import { auth, db } from "./src/config/firebase.js";

const email = "admin@gmail.com";
const password = "admin123";
const displayName = "Sevakam Admin";

function log(message) {
  process.stdout.write(`${message}\n`);
}

function normalizeRole(value) {
  const raw = (value || "").toString().trim().toLowerCase();
  if (raw === "admins") return "admin";
  if (raw === "providers") return "provider";
  if (raw === "finders") return "finder";
  return raw;
}

async function ensureAdminAuthUser() {
  try {
    const existing = await auth.getUserByEmail(email);
    await auth.updateUser(existing.uid, {
      password,
      displayName: existing.displayName || displayName,
      disabled: false,
      emailVerified: true,
    });
    log(`Updated existing Firebase Auth user: ${existing.uid}`);
    return existing.uid;
  } catch (error) {
    if (error?.code !== "auth/user-not-found") throw error;
    const created = await auth.createUser({
      email,
      password,
      displayName,
      disabled: false,
      emailVerified: true,
    });
    log(`Created Firebase Auth user: ${created.uid}`);
    return created.uid;
  }
}

async function ensureAdminFirestore(uid) {
  const userRef = db.collection("users").doc(uid);
  const adminRef = db.collection("admins").doc(uid);

  const userSnap = await userRef.get();
  const existing = userSnap.exists ? userSnap.data() || {} : {};

  const roles = new Set();
  if (existing.role) roles.add(normalizeRole(existing.role));
  if (Array.isArray(existing.roles)) {
    existing.roles.forEach((value) => roles.add(normalizeRole(value)));
  }
  roles.add("admin");
  const rolesList = Array.from(roles).filter(Boolean);

  const now = admin.firestore.FieldValue.serverTimestamp();
  const payload = {
    name: (existing.name || "").toString().trim() || displayName,
    email,
    role: "admin",
    roles: rolesList,
    photoUrl: (existing.photoUrl || "").toString(),
    updatedAt: now,
  };
  if (!userSnap.exists) {
    payload.createdAt = now;
  }

  await userRef.set(payload, { merge: true });
  await adminRef.set(
    {
      uid,
      email,
      name: payload.name,
      active: true,
      updatedAt: now,
      createdAt: userSnap.exists ? existing.createdAt || now : now,
    },
    { merge: true },
  );

  await auth.setCustomUserClaims(uid, {
    role: "admin",
    roles: rolesList,
  });
}

async function main() {
  try {
    const uid = await ensureAdminAuthUser();
    await ensureAdminFirestore(uid);
    log("Admin account is ready.");
    log(`Email: ${email}`);
    log(`Password: ${password}`);
    process.exit(0);
  } catch (error) {
    console.error("Failed to ensure admin account:", error);
    process.exit(1);
  }
}

await main();
