import {Router} from 'express';
import ServiceController from '../controllers/service.controller.js';

const router = Router();

router.get('/:id', ServiceController.getServiceById);
router.get('/category/:categoryId', ServiceController.getServiceByCategoryId);
router.get('/popular', ServiceController.getPopularServices);
router.get('/', ServiceController.getAllServices);

export default router;