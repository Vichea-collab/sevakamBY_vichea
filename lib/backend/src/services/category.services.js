import {db} from '../config/firebase.js';

class CategoryService {
    static async getAllCategories(){
        const categoriesSnap = await db.collection('categories').where('isActive', '==', true).get();
        if(categoriesSnap.empty){
            return {data: []};
        }
        const categories = categoriesSnap.docs.map(doc => ({id:doc.id, ...doc.data()})); 
        return {data : categories};
    }

    static async getCategoryById(categoryId){
        const categorySnap = await db.collection('categories').doc(categoryId).get();
        return {data : categorySnap.exists ? categorySnap.data() : null};
    }
}

export default CategoryService;