import { db } from "../config/firebase.js";
import { paginateArray } from "../utils/pagination.util.js";

const ACTIVE_CATEGORIES_CACHE_TTL_MS = 6 * 60 * 60 * 1000;
let _activeCategoriesCache = {
    expiresAt: 0,
    items: [],
};

class CategoryService {
    static async _getActiveCategories(force = false) {
        if (!force && _activeCategoriesCache.expiresAt > Date.now() && _activeCategoriesCache.items.length > 0) {
            return _activeCategoriesCache.items;
        }
        const categoriesSnap = await db.collection("categories").where("isActive", "==", true).get();
        const items = categoriesSnap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
        _activeCategoriesCache = {
            expiresAt: Date.now() + ACTIVE_CATEGORIES_CACHE_TTL_MS,
            items,
        };
        return items;
    }

    static async getAllCategories(pagination) {
        const categories = (await this._getActiveCategories())
            .slice()
            .sort((a, b) => (a.name || "").toString().localeCompare((b.name || "").toString()));
        const paged = paginateArray(categories, pagination);
        return { data: paged.items, pagination: paged.pagination };
    }

    static async getCategoryById(categoryId) {
        const categorySnap = await db.collection("categories").doc(categoryId).get();
        return { data: categorySnap.exists ? categorySnap.data() : null };
    }
}

export default CategoryService;
