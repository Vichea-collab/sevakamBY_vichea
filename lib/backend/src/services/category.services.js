import {db} from '../config/firebase.js';
import { paginateArray } from "../utils/pagination.util.js";

class CategoryService {
    static async getAllCategories(pagination){
        const categoriesSnap = await db.collection('categories').where('isActive', '==', true).get();
        if(categoriesSnap.empty){
            const paged = paginateArray([], pagination);
            return {data: paged.items, pagination: paged.pagination};
        }
        const categories = categoriesSnap.docs
            .map(doc => ({id:doc.id, ...doc.data()}))
            .sort((a, b) => (a.name || "").toString().localeCompare((b.name || "").toString()));
        const paged = paginateArray(categories, pagination);
        return {data : paged.items, pagination: paged.pagination};
    }

    static async getCategoryById(categoryId){
        const categorySnap = await db.collection('categories').doc(categoryId).get();
        return {data : categorySnap.exists ? categorySnap.data() : null};
    }
}

export default CategoryService;
