import { db } from "../config/firebase.js";
import { paginateArray } from "../utils/pagination.util.js";

const ACTIVE_SERVICES_CACHE_TTL_MS = 6 * 60 * 60 * 1000;
let _activeServicesCache = {
    expiresAt: 0,
    items: [],
};

class ServiceService {
    static async _getActiveServices(force = false) {
        if (!force && _activeServicesCache.expiresAt > Date.now() && _activeServicesCache.items.length > 0) {
            return _activeServicesCache.items;
        }
        const servicesSnap = await db.collection("services").where("active", "==", true).get();
        const items = servicesSnap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
        _activeServicesCache = {
            expiresAt: Date.now() + ACTIVE_SERVICES_CACHE_TTL_MS,
            items,
        };
        return items;
    }

    static async getServiceById(id) {
        const serviceSnap = await db.collection("services").doc(id).get();
        if (!serviceSnap.exists || !serviceSnap.data().active) {
            return { data: null };
        }
        return { data: serviceSnap.data() };
    }

    static async getServiceByCategoryId(categoryId, pagination) {
        const services = (await this._getActiveServices())
            .filter((item) => (item.categoryId || "").toString() === categoryId)
            .sort((a, b) => (a.name || "").toString().localeCompare((b.name || "").toString()));
        const paged = paginateArray(services, pagination);
        return { data: paged.items, pagination: paged.pagination };
    }

    static async getPopularServices(pagination) {
        const services = (await this._getActiveServices())
            .slice()
            .sort((a, b) => Number(b.completedCount || 0) - Number(a.completedCount || 0));
        const paged = paginateArray(services, pagination);
        return { data: paged.items, pagination: paged.pagination };
    }

    static async getAllServices(pagination) {
        const services = (await this._getActiveServices())
            .slice()
            .sort((a, b) => (a.name || "").toString().localeCompare((b.name || "").toString()));
        const paged = paginateArray(services, pagination);
        return { data: paged.items, pagination: paged.pagination };
    }
}

export default ServiceService;
