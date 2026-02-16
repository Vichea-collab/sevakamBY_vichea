import {db} from '../config/firebase.js';
import { paginateArray } from "../utils/pagination.util.js";
class ServiceService {
    static async getServiceById(id){
        const serviceSnap = await db.collection('services').doc(id).get();
        if(!serviceSnap.exists || !serviceSnap.data().active){
            return {data: null};
        }
        return {data: serviceSnap.data()};
    }

    static async getServiceByCategoryId(categoryId, pagination){
        const servicesSnap = await db.collection('services').where('categoryId', '==', categoryId).where('active','==', true).get();
        if(servicesSnap.empty){
            const paged = paginateArray([], pagination);
            return {data: paged.items, pagination: paged.pagination};
        }
        const services = servicesSnap.docs
            .map(doc => ({id: doc.id, ...doc.data()}))
            .sort((a, b) => (a.name || "").toString().localeCompare((b.name || "").toString()));
        const paged = paginateArray(services, pagination);
        return {data: paged.items, pagination: paged.pagination};
    }

    static async getPopularServices(pagination){
        const servicesSnap = await db.collection('services').where('active', '==', true).get();
        if(servicesSnap.empty){
            const paged = paginateArray([], pagination);
            return {data: paged.items, pagination: paged.pagination};
        }
        const services = servicesSnap.docs
            .map(doc => ({id: doc.id, ...doc.data()}))
            .sort((a, b) => Number(b.completedCount || 0) - Number(a.completedCount || 0));
        const paged = paginateArray(services, pagination);
        return {data: paged.items, pagination: paged.pagination};
    }

    static async getAllServices(pagination){
        const servicesSnap = await db.collection('services').where('active', '==', true).get();
        if(servicesSnap.empty){
            const paged = paginateArray([], pagination);
            return {data: paged.items, pagination: paged.pagination};
        }
        const services = servicesSnap.docs
            .map(doc => ({id: doc.id, ...doc.data()}))
            .sort((a, b) => (a.name || "").toString().localeCompare((b.name || "").toString()));
        const paged = paginateArray(services, pagination);
        return {data: paged.items, pagination: paged.pagination};
    }
}

export default ServiceService;
