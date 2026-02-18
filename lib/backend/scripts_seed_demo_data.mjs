import admin from "firebase-admin";
import { auth, db } from "./src/config/firebase.js";

const CATEGORY_SEEDS = [
  { id: "seed_cat_cleaner", name: "Cleaner", icon: "cleaner" },
  { id: "seed_cat_plumber", name: "Plumber", icon: "plumber" },
  { id: "seed_cat_electrician", name: "Electrician", icon: "electrician" },
  { id: "seed_cat_appliance", name: "Home Appliance", icon: "appliance" },
  { id: "seed_cat_maintenance", name: "Home Maintenance", icon: "maintenance" },
];

const SERVICE_SEEDS = [
  {
    id: "seed_srv_pipe_repair",
    name: "Pipe Leak Repair",
    categoryId: "seed_cat_plumber",
    categoryName: "Plumber",
    pricePerHour: 18,
    completedCount: 89,
    rating: 4.8,
  },
  {
    id: "seed_srv_drain_cleaning",
    name: "Drain Cleaning",
    categoryId: "seed_cat_plumber",
    categoryName: "Plumber",
    pricePerHour: 16,
    completedCount: 58,
    rating: 4.6,
  },
  {
    id: "seed_srv_toilet_repair",
    name: "Toilet Repair",
    categoryId: "seed_cat_plumber",
    categoryName: "Plumber",
    pricePerHour: 11,
    completedCount: 51,
    rating: 4.6,
  },
  {
    id: "seed_srv_water_installation",
    name: "Water Installation",
    categoryId: "seed_cat_plumber",
    categoryName: "Plumber",
    pricePerHour: 14,
    completedCount: 43,
    rating: 4.5,
  },
  {
    id: "seed_srv_wiring_repair",
    name: "Wiring Repair",
    categoryId: "seed_cat_electrician",
    categoryName: "Electrician",
    pricePerHour: 20,
    completedCount: 93,
    rating: 4.8,
  },
  {
    id: "seed_srv_light_fan_installation",
    name: "Light / Fan Installation",
    categoryId: "seed_cat_electrician",
    categoryName: "Electrician",
    pricePerHour: 14,
    completedCount: 47,
    rating: 4.5,
  },
  {
    id: "seed_srv_power_outage_fixes",
    name: "Power Outage Fixes",
    categoryId: "seed_cat_electrician",
    categoryName: "Electrician",
    pricePerHour: 15,
    completedCount: 40,
    rating: 4.5,
  },
  {
    id: "seed_srv_house_cleaning",
    name: "House Cleaning",
    categoryId: "seed_cat_cleaner",
    categoryName: "Cleaner",
    pricePerHour: 10,
    completedCount: 132,
    rating: 4.9,
  },
  {
    id: "seed_srv_deep_cleaning",
    name: "Deep Cleaning",
    categoryId: "seed_cat_cleaner",
    categoryName: "Cleaner",
    pricePerHour: 12,
    completedCount: 124,
    rating: 4.9,
  },
  {
    id: "seed_srv_office_cleaning",
    name: "Office Cleaning",
    categoryId: "seed_cat_cleaner",
    categoryName: "Cleaner",
    pricePerHour: 13,
    completedCount: 72,
    rating: 4.7,
  },
  {
    id: "seed_srv_move_in_out_cleaning",
    name: "Move-in / Move-out Cleaning",
    categoryId: "seed_cat_cleaner",
    categoryName: "Cleaner",
    pricePerHour: 15,
    completedCount: 55,
    rating: 4.7,
  },
  {
    id: "seed_srv_ac_repair",
    name: "Air Conditioner Repair",
    categoryId: "seed_cat_appliance",
    categoryName: "Home Appliance",
    pricePerHour: 20,
    completedCount: 67,
    rating: 4.8,
  },
  {
    id: "seed_srv_washing_machine_repair",
    name: "Washing Machine Repair",
    categoryId: "seed_cat_appliance",
    categoryName: "Home Appliance",
    pricePerHour: 19,
    completedCount: 44,
    rating: 4.6,
  },
  {
    id: "seed_srv_refrigerator_repair",
    name: "Refrigerator Repair",
    categoryId: "seed_cat_appliance",
    categoryName: "Home Appliance",
    pricePerHour: 18,
    completedCount: 38,
    rating: 4.6,
  },
  {
    id: "seed_srv_door_repair",
    name: "Door & Window Repair",
    categoryId: "seed_cat_maintenance",
    categoryName: "Home Maintenance",
    pricePerHour: 17,
    completedCount: 54,
    rating: 4.6,
  },
  {
    id: "seed_srv_furniture_fixing",
    name: "Furniture Fixing",
    categoryId: "seed_cat_maintenance",
    categoryName: "Home Maintenance",
    pricePerHour: 18,
    completedCount: 46,
    rating: 4.6,
  },
  {
    id: "seed_srv_shelf_curtain_installation",
    name: "Shelf / Curtain Installation",
    categoryId: "seed_cat_maintenance",
    categoryName: "Home Maintenance",
    pricePerHour: 16,
    completedCount: 35,
    rating: 4.5,
  },
  {
    id: "seed_srv_wall_paint_touchup",
    name: "Wall Paint Touch-up",
    categoryId: "seed_cat_maintenance",
    categoryName: "Home Maintenance",
    pricePerHour: 16,
    completedCount: 31,
    rating: 4.4,
  },
];

const FINDER_SEEDS = [
  {
    key: "finder_a",
    email: "finder.demo1@sevakam.app",
    name: "Sok Dara",
    phoneNumber: "+85512345001",
    city: "Phnom Penh",
    location: "Toul Kork, Phnom Penh",
  },
  {
    key: "finder_b",
    email: "finder.demo2@sevakam.app",
    name: "Kim Sreypov",
    phoneNumber: "+85512345002",
    city: "Siem Reap",
    location: "Svay Dangkum, Siem Reap",
  },
  {
    key: "finder_c",
    email: "finder.demo3@sevakam.app",
    name: "Chan Vibol",
    phoneNumber: "+85512345003",
    city: "Battambang",
    location: "Battambang City",
  },
];

const PROVIDER_SEEDS = [
  {
    key: "provider_a",
    email: "provider.demo1@sevakam.app",
    name: "Nuth Chenda",
    phoneNumber: "+85517666001",
    city: "Phnom Penh",
    location: "Sen Sok, Phnom Penh",
    bio: "Residential and office cleaning with same-day service.",
    serviceName: "Cleaner",
    expertIn: "Deep cleaning, office cleaning",
    availableFrom: "08:00",
    availableTo: "20:00",
    experienceYears: "5",
    serviceArea: "Phnom Penh",
    ratePerHour: 12,
    providerType: "individual",
    companyName: "",
    maxWorkers: 1,
  },
  {
    key: "provider_b",
    email: "provider.demo2@sevakam.app",
    name: "Seang Rith",
    phoneNumber: "+85517666002",
    city: "Phnom Penh",
    location: "Russey Keo, Phnom Penh",
    bio: "Plumbing and emergency leak repair specialist.",
    serviceName: "Plumber",
    expertIn: "Pipe leak repair, drain cleaning",
    availableFrom: "09:00",
    availableTo: "21:00",
    experienceYears: "7",
    serviceArea: "Phnom Penh",
    ratePerHour: 18,
    providerType: "individual",
    companyName: "",
    maxWorkers: 1,
  },
  {
    key: "provider_c",
    email: "provider.demo3@sevakam.app",
    name: "Vichea Maintenance Team",
    phoneNumber: "+85517666003",
    city: "Phnom Penh",
    location: "Chamkar Mon, Phnom Penh",
    bio: "Home maintenance team for electrical and appliance jobs.",
    serviceName: "Home Maintenance",
    expertIn: "Wiring repair, AC repair, door/window fixes",
    availableFrom: "07:30",
    availableTo: "22:00",
    experienceYears: "9",
    serviceArea: "Phnom Penh & Kandal",
    ratePerHour: 20,
    providerType: "company",
    companyName: "Vichea Fix Co., Ltd.",
    maxWorkers: 4,
  },
];

const FINDER_POST_SEEDS = [
  {
    id: "seed_finder_post_1",
    finderKey: "finder_a",
    category: "Plumber",
    service: "Pipe Leak Repair",
    location: "Toul Kork, Phnom Penh",
    message: "Kitchen sink pipe is leaking and needs urgent repair tonight.",
    preferredDateOffsetDays: 1,
    createdHoursAgo: 2,
  },
  {
    id: "seed_finder_post_2",
    finderKey: "finder_b",
    category: "Cleaner",
    service: "Deep Cleaning",
    location: "Svay Dangkum, Siem Reap",
    message: "Need deep cleaning for a two-bedroom apartment this weekend.",
    preferredDateOffsetDays: 2,
    createdHoursAgo: 5,
  },
  {
    id: "seed_finder_post_3",
    finderKey: "finder_c",
    category: "Home Appliance",
    service: "Air Conditioner Repair",
    location: "Battambang City",
    message: "AC is not cooling and making noise. Looking for inspection.",
    preferredDateOffsetDays: 1,
    createdHoursAgo: 9,
  },
  {
    id: "seed_finder_post_4",
    finderKey: "finder_a",
    category: "Electrician",
    service: "Wiring Repair",
    location: "Boeng Keng Kang, Phnom Penh",
    message: "Power outlet sparks sometimes. Need safe rewiring.",
    preferredDateOffsetDays: 3,
    createdHoursAgo: 14,
  },
];

const PROVIDER_POST_SEEDS = [
  {
    id: "seed_provider_post_1",
    providerKey: "provider_a",
    category: "Cleaner",
    service: "Deep Cleaning",
    area: "Phnom Penh",
    details: "Supplies included, same-day support for condo and villa cleaning.",
    ratePerHour: 12,
    availableNow: true,
    createdHoursAgo: 1,
  },
  {
    id: "seed_provider_post_2",
    providerKey: "provider_a",
    category: "Cleaner",
    service: "Office Cleaning",
    area: "Phnom Penh",
    details: "Night shift office cleaning with flexible recurring schedule.",
    ratePerHour: 14,
    availableNow: true,
    createdHoursAgo: 8,
  },
  {
    id: "seed_provider_post_3",
    providerKey: "provider_b",
    category: "Plumber",
    service: "Pipe Leak Repair",
    area: "Phnom Penh",
    details: "Emergency plumbing with spare parts for common pipe issues.",
    ratePerHour: 18,
    availableNow: true,
    createdHoursAgo: 3,
  },
  {
    id: "seed_provider_post_4",
    providerKey: "provider_b",
    category: "Plumber",
    service: "Drain Cleaning",
    area: "Phnom Penh & Takhmao",
    details: "Drain unclogging and flow restoration with clean work process.",
    ratePerHour: 16,
    availableNow: false,
    createdHoursAgo: 12,
  },
  {
    id: "seed_provider_post_5",
    providerKey: "provider_c",
    category: "Electrician",
    service: "Wiring Repair",
    area: "Phnom Penh",
    details: "Team-based electrical troubleshooting and safe rewiring service.",
    ratePerHour: 20,
    availableNow: true,
    createdHoursAgo: 4,
  },
  {
    id: "seed_provider_post_6",
    providerKey: "provider_c",
    category: "Home Appliance",
    service: "Air Conditioner Repair",
    area: "Phnom Penh",
    details: "Diagnosis, gas refill, and AC part replacement support.",
    ratePerHour: 22,
    availableNow: true,
    createdHoursAgo: 7,
  },
];

function parseArgs(argv) {
  const args = {
    project: "",
    password: "Demo@123456",
    execute: false,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (token === "--project") {
      args.project = (argv[index + 1] || "").trim();
      index += 1;
      continue;
    }
    if (token === "--password") {
      args.password = (argv[index + 1] || "").trim() || args.password;
      index += 1;
      continue;
    }
    if (token === "--execute") {
      args.execute = true;
      continue;
    }
    if (token === "--help" || token === "-h") {
      printUsage();
      process.exit(0);
    }
  }

  return args;
}

function printUsage() {
  console.log("Usage:");
  console.log(
    "  node scripts_seed_demo_data.mjs --project <project-id> --password <password> --execute",
  );
  console.log("");
  console.log("Options:");
  console.log("  --project   Optional safety check for Firebase project id.");
  console.log("  --password  Password for demo auth users. Default: Demo@123456");
  console.log("  --execute   Required to write data.");
}

function toTimestampFromHoursAgo(hoursAgo) {
  const date = new Date(Date.now() - Math.max(0, hoursAgo) * 60 * 60 * 1000);
  return admin.firestore.Timestamp.fromDate(date);
}

function toIsoFromDaysAhead(daysAhead) {
  const date = new Date(Date.now() + Math.max(0, daysAhead) * 24 * 60 * 60 * 1000);
  return date.toISOString();
}

function createAvatarUrl(label) {
  const encoded = encodeURIComponent(label);
  return `https://ui-avatars.com/api/?name=${encoded}&background=E8F0FF&color=0F5CD7`;
}

async function ensureAuthUser({ email, displayName, password, role }) {
  const claims = { role, roles: [role] };
  try {
    const existing = await auth.getUserByEmail(email);
    await auth.updateUser(existing.uid, {
      displayName,
      password,
      emailVerified: true,
      disabled: false,
    });
    await auth.setCustomUserClaims(existing.uid, claims);
    return { uid: existing.uid, created: false };
  } catch (error) {
    if (error?.code !== "auth/user-not-found") throw error;
    const created = await auth.createUser({
      email,
      password,
      displayName,
      emailVerified: true,
      disabled: false,
    });
    await auth.setCustomUserClaims(created.uid, claims);
    return { uid: created.uid, created: true };
  }
}

async function upsertUserDoc(uid, profile, role) {
  const ref = db.collection("users").doc(uid);
  const snap = await ref.get();
  const existing = snap.exists ? snap.data() || {} : {};

  const roleSet = new Set();
  if (existing.role) roleSet.add(existing.role.toString().toLowerCase());
  if (Array.isArray(existing.roles)) {
    existing.roles.forEach((value) => roleSet.add((value || "").toString().toLowerCase()));
  }
  roleSet.add(role);
  const roles = Array.from(roleSet).filter((value) => value === "finder" || value === "provider");

  const now = admin.firestore.FieldValue.serverTimestamp();
  const payload = {
    name: profile.name,
    email: profile.email,
    role,
    roles,
    photoUrl: createAvatarUrl(profile.name),
    updatedAt: now,
  };
  if (!snap.exists) {
    payload.createdAt = now;
  }

  await ref.set(payload, { merge: true });
}

async function upsertFinderProfile(uid, seed) {
  const ref = db.collection("finders").doc(uid);
  const snap = await ref.get();
  const now = admin.firestore.FieldValue.serverTimestamp();
  const payload = {
    city: seed.city,
    location: seed.location,
    phoneNumber: seed.phoneNumber,
    birthday: "1998-01-12",
    PhotoUrl: createAvatarUrl(seed.name),
    updatedAt: now,
  };
  if (!snap.exists) {
    payload.createdAt = now;
  }
  await ref.set(payload, { merge: true });
}

async function upsertProviderProfile(uid, seed) {
  const ref = db.collection("providers").doc(uid);
  const snap = await ref.get();
  const now = admin.firestore.FieldValue.serverTimestamp();
  const payload = {
    city: seed.city,
    location: seed.location,
    phoneNumber: seed.phoneNumber,
    birthday: "1995-05-20",
    bio: seed.bio,
    PhotoUrl: createAvatarUrl(seed.name),
    ratePerHour: seed.ratePerHour,
    serviceName: seed.serviceName,
    serviceId: "",
    serviceImageUrl: "",
    expertIn: seed.expertIn,
    availableFrom: seed.availableFrom,
    availableTo: seed.availableTo,
    experienceYears: seed.experienceYears,
    serviceArea: seed.serviceArea,
    providerType: seed.providerType,
    companyName: seed.providerType === "company" ? seed.companyName : "",
    maxWorkers: seed.providerType === "company" ? seed.maxWorkers : 1,
    ratingCount: 0,
    ratingSum: 0,
    activeOrder: 0,
    completedOrder: 0,
    updatedAt: now,
  };
  if (!snap.exists) {
    payload.createdAt = now;
  }
  await ref.set(payload, { merge: true });
}

async function seedCategoriesAndServices() {
  const now = admin.firestore.FieldValue.serverTimestamp();
  const batch = db.batch();

  CATEGORY_SEEDS.forEach((category) => {
    const ref = db.collection("categories").doc(category.id);
    batch.set(
      ref,
      {
        id: category.id,
        name: category.name,
        icon: category.icon,
        isActive: true,
        updatedAt: now,
        createdAt: now,
      },
      { merge: true },
    );
  });

  SERVICE_SEEDS.forEach((service) => {
    const ref = db.collection("services").doc(service.id);
    batch.set(
      ref,
      {
        id: service.id,
        name: service.name,
        categoryId: service.categoryId,
        categoryName: service.categoryName,
        active: true,
        available: true,
        pricePerHour: service.pricePerHour,
        completedCount: service.completedCount,
        rating: service.rating,
        updatedAt: now,
        createdAt: now,
      },
      { merge: true },
    );
  });

  await batch.commit();
  await cleanupStaleSeedServices();
}

async function cleanupStaleSeedServices() {
  const keepIds = new Set(SERVICE_SEEDS.map((item) => item.id));
  const staleSnap = await db
    .collection("services")
    .where(
      admin.firestore.FieldPath.documentId(),
      ">=",
      "seed_srv_",
    )
    .where(
      admin.firestore.FieldPath.documentId(),
      "<",
      "seed_srv_\uf8ff",
    )
    .get();
  if (staleSnap.empty) return;
  const batch = db.batch();
  let deleteCount = 0;
  staleSnap.docs.forEach((doc) => {
    if (keepIds.has(doc.id)) return;
    batch.delete(doc.ref);
    deleteCount += 1;
  });
  if (deleteCount > 0) {
    await batch.commit();
    console.log(`Removed stale seeded services: ${deleteCount}`);
  }
}

async function seedFinderPosts(finderUidByKey, finderByKey) {
  const batch = db.batch();

  FINDER_POST_SEEDS.forEach((post) => {
    const finderUid = finderUidByKey.get(post.finderKey) || "";
    const finder = finderByKey.get(post.finderKey);
    if (!finderUid || !finder) return;
    const createdAt = toTimestampFromHoursAgo(post.createdHoursAgo);
    const ref = db.collection("finderPosts").doc(post.id);
    batch.set(
      ref,
      {
        id: post.id,
        finderUid,
        clientName: finder.name,
        clientAvatarUrl: createAvatarUrl(finder.name),
        category: post.category,
        service: post.service,
        location: post.location,
        message: post.message,
        preferredDate: toIsoFromDaysAhead(post.preferredDateOffsetDays),
        status: "open",
        createdAt,
        updatedAt: createdAt,
      },
      { merge: true },
    );
  });

  await batch.commit();
}

async function seedProviderPosts(providerUidByKey, providerByKey) {
  const batch = db.batch();

  PROVIDER_POST_SEEDS.forEach((post) => {
    const providerUid = providerUidByKey.get(post.providerKey) || "";
    const provider = providerByKey.get(post.providerKey);
    if (!providerUid || !provider) return;
    const createdAt = toTimestampFromHoursAgo(post.createdHoursAgo);
    const ref = db.collection("providerPosts").doc(post.id);
    batch.set(
      ref,
      {
        id: post.id,
        providerUid,
        providerName: provider.name,
        providerAvatarUrl: createAvatarUrl(provider.name),
        category: post.category,
        service: post.service,
        area: post.area,
        details: post.details,
        ratePerHour: post.ratePerHour,
        availableNow: post.availableNow === true,
        providerType: provider.providerType,
        providerCompanyName: provider.providerType === "company" ? provider.companyName : "",
        providerMaxWorkers: provider.providerType === "company" ? provider.maxWorkers : 1,
        status: "open",
        createdAt,
        updatedAt: createdAt,
      },
      { merge: true },
    );
  });

  await batch.commit();
}

function assertProjectId(expectedProject) {
  const configuredProject = (auth.app.options.projectId || "").toString().trim();
  if (!expectedProject) {
    console.log(`Firebase project: ${configuredProject || "(unknown)"}`);
    return;
  }
  if (configuredProject && configuredProject !== expectedProject) {
    throw new Error(
      `Project mismatch. Expected "${expectedProject}", got "${configuredProject}".`,
    );
  }
  console.log(`Firebase project verified: ${expectedProject}`);
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (!args.execute) {
    printUsage();
    console.log("");
    console.log("Dry run only. Re-run with --execute to write seed data.");
    process.exit(1);
  }

  assertProjectId(args.project);

  const finderUidByKey = new Map();
  const providerUidByKey = new Map();
  const finderByKey = new Map(FINDER_SEEDS.map((item) => [item.key, item]));
  const providerByKey = new Map(PROVIDER_SEEDS.map((item) => [item.key, item]));

  let createdAuthUsers = 0;
  let updatedAuthUsers = 0;

  for (const finder of FINDER_SEEDS) {
    const authUser = await ensureAuthUser({
      email: finder.email,
      displayName: finder.name,
      password: args.password,
      role: "finder",
    });
    if (authUser.created) createdAuthUsers += 1;
    else updatedAuthUsers += 1;
    finderUidByKey.set(finder.key, authUser.uid);
    await upsertUserDoc(authUser.uid, finder, "finder");
    await upsertFinderProfile(authUser.uid, finder);
  }

  for (const provider of PROVIDER_SEEDS) {
    const authUser = await ensureAuthUser({
      email: provider.email,
      displayName: provider.name,
      password: args.password,
      role: "provider",
    });
    if (authUser.created) createdAuthUsers += 1;
    else updatedAuthUsers += 1;
    providerUidByKey.set(provider.key, authUser.uid);
    await upsertUserDoc(authUser.uid, provider, "provider");
    await upsertProviderProfile(authUser.uid, provider);
  }

  await seedCategoriesAndServices();
  await seedFinderPosts(finderUidByKey, finderByKey);
  await seedProviderPosts(providerUidByKey, providerByKey);

  console.log("Seed completed.");
  console.log(`Auth users created: ${createdAuthUsers}`);
  console.log(`Auth users updated: ${updatedAuthUsers}`);
  console.log(`Categories upserted: ${CATEGORY_SEEDS.length}`);
  console.log(`Services upserted: ${SERVICE_SEEDS.length}`);
  console.log(`Finder posts upserted: ${FINDER_POST_SEEDS.length}`);
  console.log(`Provider posts upserted: ${PROVIDER_POST_SEEDS.length}`);
  console.log(`Demo password: ${args.password}`);
}

await main();
