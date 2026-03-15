import { db } from "../config/firebase.js";
import admin from "firebase-admin";

function normalizeProviderType(value, fallback = "individual") {
    const normalized = (value ?? "").toString().trim().toLowerCase();
    if (normalized === "company") return "company";
    if (normalized === "individual") return "individual";
    return fallback;
}

function normalizePositiveInt(value, fallback = 1) {
    const parsed = Number.parseInt((value ?? "").toString(), 10);
    if (Number.isFinite(parsed) && parsed > 0) return parsed;
    const fallbackParsed = Number.parseInt((fallback ?? "").toString(), 10);
    if (Number.isFinite(fallbackParsed) && fallbackParsed > 0) return fallbackParsed;
    return 1;
}

function normalizeProviderKycStatus(value, fallback = "unverified") {
    const normalized = (value ?? "").toString().trim().toLowerCase();
    if (["pending", "approved", "rejected", "unverified"].includes(normalized)) {
        return normalized;
    }
    return fallback;
}

class ProviderService{
    static async getProviderData(uid){
        const providerSnap = await db.collection('providers').doc(uid).get();
        return {data : providerSnap.exists ? providerSnap.data() : null};
    }

    static async updateProviderData(uid, payload){
        const providerRef = db.collection('providers').doc(uid);
        const providerSnap = await providerRef.get();
        if(!providerSnap.exists){
            const e = new Error('provider not found');
            e.status = 404;
            throw e;
        }

        const current = providerSnap.data() || {};
        const currentType = normalizeProviderType(current.providerType, "individual");
        const currentKycStatus = normalizeProviderKycStatus(current.kycStatus, current.verified === true ? "approved" : "unverified");
        const nextType = payload.providerType === undefined
            ? currentType
            : normalizeProviderType(payload.providerType, currentType);
        const nextMaxWorkers = nextType === "company"
            ? normalizePositiveInt(payload.maxWorkers, current.maxWorkers)
            : 1;
        const nextCompanyName = nextType === "company"
            ? (payload.companyName ?? current.companyName ?? "").toString().trim()
            : "";
        const requestedKycStatus = payload.kycStatus === undefined
            ? currentKycStatus
            : normalizeProviderKycStatus(payload.kycStatus, currentKycStatus);
        const nextKycIdFrontUrl = (payload.kycIdFrontUrl ?? current.kycIdFrontUrl ?? "").toString().trim();
        const nextKycIdBackUrl = (payload.kycIdBackUrl ?? current.kycIdBackUrl ?? "").toString().trim();

        const updatePayload = {
            city: (payload.city ?? '').toString(),
            phoneNumber: (payload.phoneNumber ?? '').toString(),
            birthday: (payload.birthday ?? '').toString(),
            bio: (payload.bio ?? '').toString(),
            serviceName: (payload.serviceName ?? '').toString(),
            expertIn: (payload.expertIn ?? '').toString(),
            availableFrom: (payload.availableFrom ?? '').toString(),
            availableTo: (payload.availableTo ?? '').toString(),
            experienceYears: (payload.experienceYears ?? '').toString(),
            serviceArea: (payload.serviceArea ?? '').toString(),
            providerType: nextType,
            companyName: nextCompanyName,
            maxWorkers: nextMaxWorkers,
            blockedDates: Array.isArray(payload.blockedDates) ? payload.blockedDates : [],
        };
        if (payload.kycStatus !== undefined) {
            updatePayload.kycStatus = requestedKycStatus === "approved" || requestedKycStatus === "rejected"
                ? currentKycStatus
                : requestedKycStatus;
            updatePayload.verified = false;
            if (requestedKycStatus === "pending") {
                updatePayload.kycSubmittedAt = admin.firestore.FieldValue.serverTimestamp();
            }
        }
        if (payload.kycIdFrontUrl !== undefined) {
            updatePayload.kycIdFrontUrl = nextKycIdFrontUrl;
        }
        if (payload.kycIdBackUrl !== undefined) {
            updatePayload.kycIdBackUrl = nextKycIdBackUrl;
        }
        Object.keys(updatePayload).forEach((key) => {
            if(updatePayload[key] === '' && key !== 'companyName'){
                delete updatePayload[key];
            }
        });

        if(Object.keys(updatePayload).length > 0){
            await providerRef.update(updatePayload);
            await ProviderService._syncProviderBusinessProfileToPosts(uid, {
                providerType: nextType,
                providerCompanyName: nextCompanyName,
                providerMaxWorkers: nextMaxWorkers,
                blockedDates: updatePayload.blockedDates || [],
                providerBio: updatePayload.bio || "",
            });
        }
        const updated = await providerRef.get();
        return {data: updated.data()};
    }

    static async updateProviderService(uid, service){
        const providerRef =  db.collection('providers').doc(uid);
        const providerSnap = await providerRef.get();
        if(!providerSnap.exists){
            const e = new Error('provider not found'); 
            e.status = 404;
            throw e;
        }
        const safeService = service || {};
        await providerRef.update({
            serviceName : (safeService.serviceName ?? '').toString(),
            serviceId : (safeService.serviceId ?? '').toString(),
            serviceImageUrl : (safeService.serviceImageUrl ?? '').toString()
        });
        return {success : true};
    }

    static async _syncProviderBusinessProfileToPosts(uid, businessProfile){
        const snap = await db
            .collection("providerPosts")
            .where("providerUid", "==", uid)
            .where("status", "==", "open")
            .get();
        if (snap.empty) return;
        const batch = db.batch();
        snap.docs.forEach((doc) => {
            batch.update(doc.ref, businessProfile);
        });
        await batch.commit();
    }
}

export default ProviderService;
