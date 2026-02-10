import { db } from "../config/firebase.js";
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

        const updatePayload = {
            city: (payload.city ?? '').toString(),
            phoneNumber: (payload.phoneNumber ?? '').toString(),
            birthday: (payload.birthday ?? '').toString(),
            bio: (payload.bio ?? '').toString(),
        };
        Object.keys(updatePayload).forEach((key) => {
            if(updatePayload[key] === ''){
                delete updatePayload[key];
            }
        });

        if(Object.keys(updatePayload).length > 0){
            await providerRef.update(updatePayload);
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
}

export default ProviderService;
