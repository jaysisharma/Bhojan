import { Router } from 'express';
import { createOrder, updateOrderStatus, getActiveOrders } from './order.controller';
import { authenticateJWT } from '../../middlewares/auth.middleware';

const router = Router();

router.post('/', authenticateJWT, createOrder);
router.get('/', authenticateJWT, getActiveOrders);
router.patch('/:id/status', authenticateJWT, updateOrderStatus);

export default router;
