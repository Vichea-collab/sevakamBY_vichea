import { db } from "../config/firebase.js";
class ProviderService{
    static async getProviderData(uid){
        const providerSnap = await db.collection('providers').doc(uid).get();
        return {data : providerSnap.exists ? providerSnap.data() : null};
    }

    static async updateProviderService(uid, service){
        const providerRef =  db.collection('providers').doc(uid);
        const providerSnap = await providerRef.get();
        if(!providerSnap.exists){
            const e = new Error('provider not found'); 
            e.status = 404;
            throw e;
        }
        await providerRef.update({
            serviceName : service.serviceName,
            serviceId : service.serviceId,
            serviceImageUrl : service.serviceImageUrl
        });
        return {success : true};
    }
}

export default ProviderService;