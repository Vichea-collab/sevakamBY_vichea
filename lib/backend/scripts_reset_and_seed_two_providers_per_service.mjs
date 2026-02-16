import { auth, db } from "./src/config/firebase.js";

const defaultPassword = process.env.SEED_DEFAULT_PASSWORD || "Sevakam123!";
const seedTag = "seed_two_providers_per_service_v1";

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

const providerNamePool = [
  "Dara",
  "Sok",
  "Nita",
  "Kanha",
  "Rith",
  "Mey",
  "Malis",
  "Vanna",
  "Chan",
  "Sreypov",
  "Piseth",
  "Ravy",
  "Dany",
  "Tola",
  "Rina",
  "Nary",
  "Sovann",
  "Nisay",
  "Sophea",
  "Kosal",
  "Seyha",
  "Vichea",
  "Mony",
  "Sina",
  "Neth",
  "Borey",
  "Kimly",
  "Dalin",
  "Seyla",
  "Sophal",
];

const finderSeeds = [
  { name: "Fisher Bb", email: "seed.finder.1@sevakam.app", city: "Phnom Penh" },
  { name: "Kimheng Finder", email: "seed.finder.2@sevakam.app", city: "Phnom Penh" },
  { name: "Sokha Client", email: "seed.finder.3@sevakam.app", city: "Phnom Penh" },
];

function slug(text) {
  return text
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");
}

function chunk(items, size) {
  const output = [];
  for (let i = 0; i < items.length; i += size) {
    output.push(items.slice(i, i + size));
  }
  return output;
}

function serviceDocId(categoryId, serviceName) {
  return `${categoryId}_${slug(serviceName)}`;
}

function serviceImagePath() {
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
    await auth.updateUser(existing.uid, {
      displayName,
      password: defaultPassword,
      emailVerified: true,
      disabled: false,
    });
    return await auth.getUser(existing.uid);
  }

  return await auth.createUser({
    email,
    password: defaultPassword,
    displayName,
    emailVerified: true,
    disabled: false,
  });
}

async function deleteCollectionDocs(collectionName, batchSize = 300) {
  const collectionRef = db.collection(collectionName);
  let totalDeleted = 0;

  while (true) {
    const snapshot = await collectionRef.limit(batchSize).get();
    if (snapshot.empty) break;
    const docs = snapshot.docs;
    for (const part of chunk(docs, 400)) {
      const batch = db.batch();
      for (const doc of part) {
        batch.delete(doc.ref);
      }
      await batch.commit();
      totalDeleted += part.length;
    }
  }

  return totalDeleted;
}

async function deleteChatsRecursively() {
  const chatsSnapshot = await db.collection("chats").get();
  if (chatsSnapshot.empty) return 0;

  let deleted = 0;
  for (const chatDoc of chatsSnapshot.docs) {
    if (typeof db.recursiveDelete === "function") {
      await db.recursiveDelete(chatDoc.ref);
      deleted += 1;
      continue;
    }

    const messagesSnapshot = await chatDoc.ref.collection("messages").get();
    for (const part of chunk(messagesSnapshot.docs, 400)) {
      const batch = db.batch();
      for (const messageDoc of part) batch.delete(messageDoc.ref);
      await batch.commit();
    }
    await chatDoc.ref.delete();
    deleted += 1;
  }
  return deleted;
}

async function cleanupOldSeedUsers() {
  let pageToken = undefined;
  let deletedAuthUsers = 0;
  let deletedUserDocs = 0;
  let deletedProviderDocs = 0;
  let deletedFinderDocs = 0;

  do {
    const result = await auth.listUsers(1000, pageToken);
    const usersToDelete = result.users.filter((user) => {
      const email = (user.email || "").toLowerCase();
      return email.startsWith("seed.provider.") || email.startsWith("seed.finder.");
    });

    for (const user of usersToDelete) {
      const uid = user.uid;
      const userRef = db.collection("users").doc(uid);
      const providerRef = db.collection("providers").doc(uid);
      const finderRef = db.collection("finders").doc(uid);

      const [userSnap, providerSnap, finderSnap] = await Promise.all([
        userRef.get(),
        providerRef.get(),
        finderRef.get(),
      ]);

      if (userSnap.exists) {
        if (typeof db.recursiveDelete === "function") {
          await db.recursiveDelete(userRef);
        } else {
          await userRef.delete();
        }
        deletedUserDocs += 1;
      }
      if (providerSnap.exists) {
        await providerRef.delete();
        deletedProviderDocs += 1;
      }
      if (finderSnap.exists) {
        await finderRef.delete();
        deletedFinderDocs += 1;
      }

      await auth.deleteUser(uid);
      deletedAuthUsers += 1;
    }

    pageToken = result.pageToken;
  } while (pageToken);

  return {
    deletedAuthUsers,
    deletedUserDocs,
    deletedProviderDocs,
    deletedFinderDocs,
  };
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
        seedTag,
      },
      { merge: true },
    );
  }
  await categoryBatch.commit();

  const servicesBatch = db.batch();
  for (const category of categories) {
    const items = servicesByCategory[category.id] || [];
    for (const item of items) {
      const id = serviceDocId(category.id, item.name);
      servicesBatch.set(
        db.collection("services").doc(id),
        {
          id,
          name: item.name,
          categoryId: category.id,
          categoryName: category.name,
          pricePerHour: item.pricePerHour,
          completedCount: item.completed,
          rating: item.rating,
          imageUrl: serviceImagePath(),
          active: true,
          updatedAt: now,
          seedTag,
        },
        { merge: true },
      );
    }
  }
  await servicesBatch.commit();
}

function buildProviderSpecs() {
  const specs = [];
  let idx = 0;

  for (const category of categories) {
    const services = servicesByCategory[category.id] || [];
    for (const service of services) {
      for (let slot = 1; slot <= 2; slot += 1) {
        const providerName = providerNamePool[idx % providerNamePool.length];
        const displayName = `${providerName} ${service.name}`;
        const email = `seed.provider.${slug(category.id)}.${slug(service.name)}.${slot}@sevakam.app`;
        const years = 2 + (idx % 9);
        specs.push({
          email,
          displayName,
          city: "Phnom Penh",
          phoneNumber: `+855 1${idx % 10} ${100 + idx} ${200 + idx}`,
          bio: `Trusted ${service.name.toLowerCase()} provider.`,
          categoryId: category.id,
          categoryName: category.name,
          serviceName: service.name,
          servicePricePerHour: service.pricePerHour,
          serviceRating: service.rating,
          completedOrder: service.completed + slot * 3,
          experienceYears: `${years}`,
          serviceArea: "Phnom Penh, Cambodia",
          availableFrom: "08:00 AM",
          availableTo: "08:00 PM",
        });
        idx += 1;
      }
    }
  }
  return specs;
}

async function seedProvidersWithPosts() {
  const specs = buildProviderSpecs();
  let postIndex = 0;

  for (const spec of specs) {
    const userRecord = await ensureAuthUser({
      email: spec.email,
      displayName: spec.displayName,
    });

    await db
      .collection("users")
      .doc(userRecord.uid)
      .set(
        {
          name: spec.displayName,
          email: spec.email,
          role: "provider",
          roles: ["provider"],
          photoUrl: userRecord.photoURL || "",
          updatedAt: new Date().toISOString(),
          seedTag,
        },
        { merge: true },
      );

    await db
      .collection("providers")
      .doc(userRecord.uid)
      .set(
        {
          bio: spec.bio,
          phoneNumber: spec.phoneNumber,
          PhotoUrl: userRecord.photoURL || "",
          ratePerHour: spec.servicePricePerHour,
          city: spec.city,
          location: null,
          serviceId: serviceDocId(spec.categoryId, spec.serviceName),
          serviceName: spec.serviceName,
          serviceImageUrl: serviceImagePath(),
          expertIn: spec.serviceName,
          availableFrom: spec.availableFrom,
          availableTo: spec.availableTo,
          experienceYears: spec.experienceYears,
          serviceArea: spec.serviceArea,
          birthday: "1996-01-01",
          ratingCount: 20,
          ratingSum: Math.round(spec.serviceRating * 20),
          activeOrder: 0,
          completedOrder: spec.completedOrder,
          updatedAt: new Date().toISOString(),
          seedTag,
        },
        { merge: true },
      );

    postIndex += 1;
    const postId = `seed_provider_post_${slug(spec.categoryId)}_${slug(spec.serviceName)}_${postIndex}`;
    const createdAt = new Date(Date.now() - postIndex * 60 * 1000).toISOString();

    await db
      .collection("providerPosts")
      .doc(postId)
      .set(
        {
          id: postId,
          providerUid: userRecord.uid,
          providerName: spec.displayName,
          providerAvatarUrl: "",
          category: spec.categoryName,
          service: spec.serviceName,
          area: "Phnom Penh, Cambodia",
          details: `Hi, I am available today for ${spec.serviceName.toLowerCase()}.`,
          ratePerHour: spec.servicePricePerHour,
          availableNow: true,
          status: "open",
          createdAt,
          updatedAt: createdAt,
          seedTag,
        },
        { merge: true },
      );
  }

  return specs;
}

async function seedFindersAndRequests() {
  const users = [];
  for (const finder of finderSeeds) {
    const userRecord = await ensureAuthUser({
      email: finder.email,
      displayName: finder.name,
    });
    users.push({ ...finder, uid: userRecord.uid });
    await db
      .collection("users")
      .doc(userRecord.uid)
      .set(
        {
          name: finder.name,
          email: finder.email,
          role: "finder",
          roles: ["finder"],
          photoUrl: userRecord.photoURL || "",
          updatedAt: new Date().toISOString(),
          seedTag,
        },
        { merge: true },
      );
    await db
      .collection("finders")
      .doc(userRecord.uid)
      .set(
        {
          city: finder.city,
          PhotoUrl: userRecord.photoURL || "",
          phoneNumber: "+855 12 000 111",
          birthday: "1999-01-01",
          location: null,
          updatedAt: new Date().toISOString(),
          seedTag,
        },
        { merge: true },
      );
  }

  let requestIndex = 0;
  for (const category of categories) {
    const services = servicesByCategory[category.id] || [];
    for (const service of services) {
      requestIndex += 1;
      const finder = users[requestIndex % users.length];
      const requestId = `seed_finder_request_${slug(category.id)}_${slug(service.name)}_${requestIndex}`;
      const createdAt = new Date(
        Date.now() - requestIndex * 90 * 1000,
      ).toISOString();

      await db
        .collection("finderPosts")
        .doc(requestId)
        .set(
          {
            id: requestId,
            finderUid: finder.uid,
            clientName: finder.name,
            clientAvatarUrl: "",
            category: category.name,
            service: service.name,
            location: "Phnom Penh, Cambodia",
            message: `Need help with ${service.name.toLowerCase()} soon.`,
            preferredDate: new Date(
              Date.now() + 24 * 60 * 60 * 1000,
            ).toISOString(),
            status: "open",
            createdAt,
            updatedAt: createdAt,
            seedTag,
          },
          { merge: true },
        );
    }
  }

  return users;
}

async function verifyTwoProvidersPerService() {
  const snapshot = await db
    .collection("providerPosts")
    .where("status", "==", "open")
    .get();

  const map = new Map();
  for (const doc of snapshot.docs) {
    const row = doc.data() || {};
    const key = `${(row.category || "").toString().trim()}::${(row.service || "")
      .toString()
      .trim()}`;
    if (!key || key === "::") continue;
    const set = map.get(key) || new Set();
    set.add((row.providerUid || "").toString().trim());
    map.set(key, set);
  }

  const missing = [];
  for (const category of categories) {
    const services = servicesByCategory[category.id] || [];
    for (const service of services) {
      const key = `${category.name}::${service.name}`;
      const providers = map.get(key) || new Set();
      if (providers.size < 2) {
        missing.push({ key, count: providers.size });
      }
    }
  }

  if (missing.length > 0) {
    throw new Error(
      `Verification failed: some services have <2 providers: ${missing
        .map((item) => `${item.key}(${item.count})`)
        .join(", ")}`,
    );
  }
}

async function main() {
  console.log("Cleaning old seed users...");
  const seedCleanup = await cleanupOldSeedUsers();
  console.log(
    `Removed auth/users/providers/finders: ${seedCleanup.deletedAuthUsers}/${seedCleanup.deletedUserDocs}/${seedCleanup.deletedProviderDocs}/${seedCleanup.deletedFinderDocs}`,
  );

  console.log("Cleaning messy transactional collections...");
  const [deletedProviderPosts, deletedFinderPosts, deletedOrders, deletedChats] =
    await Promise.all([
      deleteCollectionDocs("providerPosts"),
      deleteCollectionDocs("finderPosts"),
      deleteCollectionDocs("orders"),
      deleteChatsRecursively(),
    ]);
  console.log(
    `Deleted docs -> providerPosts:${deletedProviderPosts}, finderPosts:${deletedFinderPosts}, orders:${deletedOrders}, chats:${deletedChats}`,
  );

  console.log("Seeding categories and services...");
  await seedCategoriesAndServices();

  console.log("Seeding providers and provider posts (2 per service)...");
  const providers = await seedProvidersWithPosts();

  console.log("Seeding finder accounts and finder requests...");
  const finders = await seedFindersAndRequests();

  console.log("Verifying two providers per service...");
  await verifyTwoProvidersPerService();

  console.log("Seed reset completed successfully.");
  console.log(`Provider accounts created/updated: ${providers.length}`);
  console.log(`Finder accounts created/updated: ${finders.length}`);
  console.log(`Default password: ${defaultPassword}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Reset/seed failed:", error?.message || error);
    process.exit(1);
  });

