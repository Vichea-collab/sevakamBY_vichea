import { db, auth } from "./src/config/firebase.js";

const finderEmail =
  process.env.SEED_FINDER_EMAIL || "fisherbb308@gmail.com";
const finderDisplayName = "Fisher Bb";

const seedTag = "luch_vichea_seed_v3";
const defaultPassword = process.env.SEED_DEFAULT_PASSWORD || "Sevakam123!";

const categories = [
  { id: "plumber", name: "Plumber", icon: "plumber" },
  { id: "electrician", name: "Electrician", icon: "electrician" },
  { id: "cleaner", name: "Cleaner", icon: "cleaner" },
  { id: "home_appliance", name: "Home Appliance", icon: "appliance" },
  { id: "home_maintenance", name: "Home Maintenance", icon: "maintenance" },
];

const servicesByCategory = {
  plumber: [
    { name: "Pipe Leak Repair", pricePerHour: 12, rating: 4.8, completed: 120 },
    { name: "Toilet Repair", pricePerHour: 11, rating: 4.6, completed: 84 },
    {
      name: "Water Installation",
      pricePerHour: 14,
      rating: 4.5,
      completed: 67,
    },
  ],
  electrician: [
    { name: "Wiring Repair", pricePerHour: 16, rating: 4.7, completed: 102 },
    {
      name: "Light / Fan Installation",
      pricePerHour: 14,
      rating: 4.5,
      completed: 76,
    },
    {
      name: "Power Outage Fixes",
      pricePerHour: 15,
      rating: 4.6,
      completed: 88,
    },
  ],
  cleaner: [
    {
      name: "House Cleaning",
      pricePerHour: 10,
      rating: 4.9,
      completed: 141,
    },
    {
      name: "Office Cleaning",
      pricePerHour: 13,
      rating: 4.4,
      completed: 65,
    },
    {
      name: "Move-in / Move-out Cleaning",
      pricePerHour: 15,
      rating: 4.7,
      completed: 73,
    },
  ],
  home_appliance: [
    {
      name: "Air Conditioner Repair",
      pricePerHour: 20,
      rating: 4.8,
      completed: 96,
    },
    {
      name: "Washing Machine Repair",
      pricePerHour: 19,
      rating: 4.5,
      completed: 72,
    },
    {
      name: "Refrigerator Repair",
      pricePerHour: 18,
      rating: 4.6,
      completed: 69,
    },
  ],
  home_maintenance: [
    {
      name: "Door & Window Repair",
      pricePerHour: 17,
      rating: 4.4,
      completed: 81,
    },
    {
      name: "Furniture Fixing",
      pricePerHour: 18,
      rating: 4.6,
      completed: 74,
    },
    {
      name: "Shelf / Curtain Installation",
      pricePerHour: 16,
      rating: 4.5,
      completed: 62,
    },
  ],
};

const providerSeeds = [
  {
    email: process.env.SEED_PROVIDER_EMAIL || "vichea@gmail.com",
    displayName: "Luch Vichea",
    city: "Phnom Penh",
    phoneNumber: "+855 12 345 678",
    bio: "Reliable cleaning and home services provider.",
    categoryId: "cleaner",
    serviceName: "House Cleaning",
    offeredServices: [
      "House Cleaning",
      "Office Cleaning",
      "Move-in / Move-out Cleaning",
    ],
  },
  {
    email: "plumber.demo@sevakam.app",
    displayName: "Dara Plumber",
    city: "Phnom Penh",
    phoneNumber: "+855 10 111 222",
    bio: "Fast and clean plumbing repairs.",
    categoryId: "plumber",
    serviceName: "Pipe Leak Repair",
    offeredServices: ["Pipe Leak Repair", "Toilet Repair"],
  },
  {
    email: "plumber.install.demo@sevakam.app",
    displayName: "Vanna Install",
    city: "Phnom Penh",
    phoneNumber: "+855 11 121 212",
    bio: "Water point and tank installation specialist.",
    categoryId: "plumber",
    serviceName: "Water Installation",
  },
  {
    email: "electrician.demo@sevakam.app",
    displayName: "Sok Electric",
    city: "Phnom Penh",
    phoneNumber: "+855 10 333 444",
    bio: "Professional electrician for home issues.",
    categoryId: "electrician",
    serviceName: "Wiring Repair",
    offeredServices: [
      "Wiring Repair",
      "Light / Fan Installation",
      "Power Outage Fixes",
    ],
  },
  {
    email: "electrician.power.demo@sevakam.app",
    displayName: "Nita Power",
    city: "Phnom Penh",
    phoneNumber: "+855 11 313 131",
    bio: "Fast troubleshooting for home power outages.",
    categoryId: "electrician",
    serviceName: "Power Outage Fixes",
  },
  {
    email: "appliance.demo@sevakam.app",
    displayName: "Kanha Appliance",
    city: "Phnom Penh",
    phoneNumber: "+855 10 555 666",
    bio: "Appliance technician for AC and washer.",
    categoryId: "home_appliance",
    serviceName: "Air Conditioner Repair",
    offeredServices: ["Air Conditioner Repair", "Washing Machine Repair"],
  },
  {
    email: "appliance.fridge.demo@sevakam.app",
    displayName: "Chan Fridge",
    city: "Phnom Penh",
    phoneNumber: "+855 11 515 151",
    bio: "Refrigerator and cooling repair service.",
    categoryId: "home_appliance",
    serviceName: "Refrigerator Repair",
  },
  {
    email: "maintenance.demo@sevakam.app",
    displayName: "Rith Maintenance",
    city: "Phnom Penh",
    phoneNumber: "+855 10 777 888",
    bio: "General maintenance and repair specialist.",
    categoryId: "home_maintenance",
    serviceName: "Door & Window Repair",
    offeredServices: ["Door & Window Repair", "Furniture Fixing"],
  },
  {
    email: "maintenance.shelf.demo@sevakam.app",
    displayName: "Mey Install",
    city: "Phnom Penh",
    phoneNumber: "+855 11 717 171",
    bio: "Curtain rod and shelf installation support.",
    categoryId: "home_maintenance",
    serviceName: "Shelf / Curtain Installation",
  },
  {
    email: "cleaner.office.demo@sevakam.app",
    displayName: "Malis Cleaner",
    city: "Phnom Penh",
    phoneNumber: "+855 10 999 000",
    bio: "Office and move-out deep cleaning specialist.",
    categoryId: "cleaner",
    serviceName: "Office Cleaning",
  },
  {
    email: "cleaner.moveout.demo@sevakam.app",
    displayName: "Sreyneang Moveout",
    city: "Phnom Penh",
    phoneNumber: "+855 11 919 191",
    bio: "Move-in and move-out deep cleaning specialist.",
    categoryId: "cleaner",
    serviceName: "Move-in / Move-out Cleaning",
  },
];

function slug(text) {
  return text
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");
}

function categoryById(id) {
  return categories.find((item) => item.id === id) || null;
}

function serviceBy(categoryId, serviceName) {
  const services = servicesByCategory[categoryId] || [];
  return services.find((item) => item.name === serviceName) || null;
}

function serviceDocId(categoryId, serviceName) {
  return `${categoryId}_${slug(serviceName)}`;
}

function pickServiceImage(_categoryId) {
  return "assets/images/profile.jpg";
}

async function getUserByEmailSafe(email) {
  try {
    return await auth.getUserByEmail(email);
  } catch (_) {
    return null;
  }
}

async function ensureAuthUser({ email, displayName }) {
  const existing = await getUserByEmailSafe(email);
  if (existing) {
    if ((existing.displayName || "") !== displayName) {
      await auth.updateUser(existing.uid, { displayName });
      return await auth.getUser(existing.uid);
    }
    return existing;
  }

  return await auth.createUser({
    email,
    password: defaultPassword,
    displayName,
    emailVerified: true,
    disabled: false,
  });
}

async function seedCategoriesAndServices() {
  const now = new Date().toISOString();

  const categoryBatch = db.batch();
  for (const category of categories) {
    categoryBatch.set(
      db.collection("categories").doc(category.id),
      {
        id: category.id,
        name: category.name,
        icon: category.icon,
        isActive: true,
        updatedAt: now,
      },
      { merge: true },
    );
  }
  await categoryBatch.commit();

  const activeServices = await db
    .collection("services")
    .where("active", "==", true)
    .get();
  if (!activeServices.empty) {
    const deactivateBatch = db.batch();
    for (const doc of activeServices.docs) {
      deactivateBatch.set(
        doc.ref,
        {
          active: false,
          updatedAt: now,
        },
        { merge: true },
      );
    }
    await deactivateBatch.commit();
  }

  const serviceBatch = db.batch();
  for (const category of categories) {
    const items = servicesByCategory[category.id] || [];
    for (const item of items) {
      const id = serviceDocId(category.id, item.name);
      serviceBatch.set(
        db.collection("services").doc(id),
        {
          id,
          name: item.name,
          categoryId: category.id,
          categoryName: category.name,
          pricePerHour: item.pricePerHour,
          completedCount: item.completed,
          rating: item.rating,
          imageUrl: pickServiceImage(category.id),
          active: true,
          updatedAt: now,
        },
        { merge: true },
      );
    }
  }
  await serviceBatch.commit();
}

async function ensureProviderRole({
  userRecord,
  displayName,
  city,
  phoneNumber,
  bio,
  categoryId,
  serviceName,
}) {
  const category = categoryById(categoryId);
  const service = serviceBy(categoryId, serviceName);
  if (!category || !service) {
    throw new Error(`Invalid provider seed mapping: ${categoryId}/${serviceName}`);
  }

  const uid = userRecord.uid;
  const userRef = db.collection("users").doc(uid);
  const userSnap = await userRef.get();
  const current = userSnap.exists ? userSnap.data() : {};

  const roleSet = new Set();
  if (current?.role) roleSet.add(String(current.role).toLowerCase());
  if (Array.isArray(current?.roles)) {
    for (const value of current.roles) {
      if (value) roleSet.add(String(value).toLowerCase());
    }
  }
  roleSet.add("provider");
  const roles = Array.from(roleSet).filter((value) =>
    ["provider", "finder"].includes(value),
  );

  await userRef.set(
    {
      name: displayName,
      email: userRecord.email || "",
      role: "provider",
      roles,
      photoUrl: userRecord.photoURL || "",
      updatedAt: new Date().toISOString(),
      seedTag,
    },
    { merge: true },
  );

  await db
    .collection("providers")
    .doc(uid)
    .set(
      {
        bio,
        phoneNumber,
        PhotoUrl: userRecord.photoURL || "",
        ratePerHour: service.pricePerHour,
        city,
        location: null,
        serviceId: serviceDocId(categoryId, serviceName),
        serviceName,
        serviceImageUrl: pickServiceImage(categoryId),
        birthday: "28/11/2005",
        ratingCount: 20,
        ratingSum: Math.round((service.rating || 4.6) * 20),
        activeOrder: 0,
        completedOrder: service.completed,
        updatedAt: new Date().toISOString(),
        seedTag,
      },
      { merge: true },
    );
}

async function ensureFinderRole({ userRecord }) {
  const uid = userRecord.uid;
  const userRef = db.collection("users").doc(uid);
  const userSnap = await userRef.get();
  const current = userSnap.exists ? userSnap.data() : {};

  const roleSet = new Set();
  if (current?.role) roleSet.add(String(current.role).toLowerCase());
  if (Array.isArray(current?.roles)) {
    for (const value of current.roles) {
      if (value) roleSet.add(String(value).toLowerCase());
    }
  }
  roleSet.add("finder");
  const roles = Array.from(roleSet).filter((value) =>
    ["provider", "finder"].includes(value),
  );

  await userRef.set(
    {
      name: finderDisplayName,
      email: userRecord.email || "",
      role: "finder",
      roles,
      photoUrl: userRecord.photoURL || "",
      updatedAt: new Date().toISOString(),
      seedTag,
    },
    { merge: true },
  );

  await db
    .collection("finders")
    .doc(uid)
    .set(
      {
        city: "Phnom Penh",
        PhotoUrl: userRecord.photoURL || "",
        phoneNumber: "+855 98 765 432",
        birthday: "28/11/2005",
        location: null,
        updatedAt: new Date().toISOString(),
        seedTag,
      },
      { merge: true },
    );
}

async function cleanupSeededDocs(collectionName, idPrefix) {
  const snapshot = await db.collection(collectionName).get();
  if (snapshot.empty) return;
  const docsToDelete = snapshot.docs.filter((doc) => {
    const row = doc.data() || {};
    const tag = (row.seedTag || "").toString();
    return doc.id.startsWith(idPrefix) || tag.startsWith("luch_vichea_seed_");
  });
  if (!docsToDelete.length) return;
  const cleanupBatch = db.batch();
  for (const doc of docsToDelete) {
    cleanupBatch.delete(doc.ref);
  }
  await cleanupBatch.commit();
}

async function seedProviderPosts(providerUsers) {
  await cleanupSeededDocs("providerPosts", "seed_provider_");

  let index = 0;
  for (const provider of providerUsers) {
    const category = categoryById(provider.categoryId);
    const services = Array.isArray(provider.offeredServices) &&
      provider.offeredServices.length
      ? provider.offeredServices
      : [provider.serviceName];
    if (!category || !services.length) continue;

    for (const offeredServiceName of services) {
      const service = serviceBy(provider.categoryId, offeredServiceName);
      if (!service) continue;
      index += 1;
      const docId = `seed_provider_${slug(provider.displayName)}_${slug(offeredServiceName)}`;
      const createdAt = new Date(Date.now() - index * 60 * 1000).toISOString();
      await db
        .collection("providerPosts")
        .doc(docId)
        .set(
          {
            id: docId,
            providerUid: provider.uid,
            providerName: provider.displayName,
            providerAvatarUrl: "",
            category: category.name,
            service: offeredServiceName,
            area: `${provider.city}, Cambodia`,
            details: `Hi, I am available today for ${offeredServiceName.toLowerCase()}.`,
            ratePerHour: service.pricePerHour,
            availableNow: true,
            status: "open",
            createdAt,
            updatedAt: createdAt,
            seedTag,
          },
          { merge: true },
        );
    }
  }
}

async function seedFinderRequests(finderUid) {
  await cleanupSeededDocs("finderPosts", "seed_finder_");

  const requests = [
    {
      id: "seed_finder_house_cleaning",
      category: "Cleaner",
      service: "House Cleaning",
      location: "Phnom Penh, Cambodia",
      message: "Need house cleaning tomorrow morning.",
    },
    {
      id: "seed_finder_pipe_leak",
      category: "Plumber",
      service: "Pipe Leak Repair",
      location: "Phnom Penh, Cambodia",
      message: "Pipe leak under kitchen sink, urgent help needed.",
    },
  ];

  let index = 0;
  for (const request of requests) {
    index += 1;
    const createdAt = new Date(Date.now() - index * 90 * 1000).toISOString();
    await db
      .collection("finderPosts")
      .doc(request.id)
      .set(
        {
          ...request,
          finderUid,
          clientName: finderDisplayName,
          clientAvatarUrl: "",
          preferredDate: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
          status: "open",
          createdAt,
          updatedAt: createdAt,
          seedTag,
        },
        { merge: true },
      );
  }
}

async function main() {
  console.log("Seeding categories and services...");
  await seedCategoriesAndServices();

  const providerUsers = [];
  for (const providerSeed of providerSeeds) {
    const userRecord = await ensureAuthUser({
      email: providerSeed.email,
      displayName: providerSeed.displayName,
    });
    await ensureProviderRole({
      userRecord,
      displayName: providerSeed.displayName,
      city: providerSeed.city,
      phoneNumber: providerSeed.phoneNumber,
      bio: providerSeed.bio,
      categoryId: providerSeed.categoryId,
      serviceName: providerSeed.serviceName,
    });
    providerUsers.push({ ...providerSeed, uid: userRecord.uid });
  }

  const finderUser = await ensureAuthUser({
    email: finderEmail,
    displayName: finderDisplayName,
  });
  await ensureFinderRole({ userRecord: finderUser });

  console.log("Seeding provider posts for all provider users...");
  await seedProviderPosts(providerUsers);

  console.log("Seeding finder requests...");
  await seedFinderRequests(finderUser.uid);

  console.log("Seed completed.");
  console.log("Provider demo users (email / default password):");
  for (const provider of providerSeeds) {
    console.log(`- ${provider.email} / ${defaultPassword}`);
  }
  console.log(`Finder user: ${finderEmail} / ${defaultPassword}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Seed failed:", error?.message || error);
    process.exit(1);
  });
