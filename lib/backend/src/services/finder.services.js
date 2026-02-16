import {db} from '../config/firebase.js';

class FinderService {
    static async getFinderData(uid){
        const finderSnap = await db.collection('finders').doc(uid).get();
        return {data : finderSnap.exists? finderSnap.data() : null};
    }

    static async updateFinderData(uid, payload){
        const finderRef = db.collection('finders').doc(uid);
        const finderSnap = await finderRef.get();
        if(!finderSnap.exists){
            const e = new Error('finder not found');
            e.status = 404;
            throw e;
        }

        const normalizedCity = (payload.city ?? '').toString().trim();
        const normalizedLocation = (payload.location ?? '').toString().trim();
        const updatePayload = {
            city: normalizedCity,
            location: normalizedLocation,
            phoneNumber: (payload.phoneNumber ?? '').toString(),
            birthday: (payload.birthday ?? '').toString(),
        };
        if (normalizedCity && !normalizedLocation) {
            updatePayload.location = normalizedCity;
        }
        if (normalizedLocation && !normalizedCity) {
            updatePayload.city = normalizedLocation;
        }
        Object.keys(updatePayload).forEach((key) => {
            if(updatePayload[key] === ''){
                delete updatePayload[key];
            }
        });

        if(Object.keys(updatePayload).length > 0){
            await finderRef.update(updatePayload);
        }
        const updated = await finderRef.get();
        return {data: updated.data()};
    }
}

export default FinderService;
