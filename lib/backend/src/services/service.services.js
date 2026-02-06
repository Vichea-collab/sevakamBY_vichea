import {db} from '../config/firebase.js';
class ServiceService {
    static async getServiceById(id){
        const serviceSnap = await db.collection('services').doc(id).get();
        if(!serviceSnap.exists || !serviceSnap.data().active){
            return {data: null};
        }
        return {data: serviceSnap.data()};
    }

    static async getServiceByCategoryId(categoryId){
        const servicesSnap = await db.collection('services').where('categoryId', '==', categoryId).where('active','==', true).get();
        if(servicesSnap.empty){
            return {data: []};
        }
        const services = servicesSnap.docs.map(doc => ({id: doc.id, ...doc.data()}));
        return {data: services};
    }

    static async getPopularServices(){
        const servicesSnap = await db.collection('services').where('active', '==', true).orderBy('completedCount', 'desc').limit(10).get();
        if(servicesSnap.empty){
            return {data: []};
        }
        const services = servicesSnap.docs.map(doc => ({id: doc.id, ...doc.data()}));
        return {data: services};
    }

    static async getAllServices(){
        const servicesSnap = await db.collection('services').where('active', '==', true).get();
        if(servicesSnap.empty){
            return {data: []};
        }
        const services = servicesSnap.docs.map(doc => ({id: doc.id, ...doc.data()}));
        return {data: services};
    }
}

export default ServiceService;