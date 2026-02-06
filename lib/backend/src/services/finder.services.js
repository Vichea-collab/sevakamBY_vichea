import {db} from '../config/firebase.js';

class FinderService {
    static async getFinderData(uid){
        const finderSnap = await db.collection('finders').doc(uid).get();
        return {data : finderSnap.exists? finderSnap.data() : null};
    }
}

export default FinderService;