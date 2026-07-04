import { Router } from 'express';
import { openShift, closeShift, getActiveShift, getShiftHistory } from './shift.controller';
import { authenticateJWT, requireRoles } from '../../middlewares/auth.middleware';
import { Role } from '@prisma/client';

const router = Router();

router.get('/active', authenticateJWT, getActiveShift);
router.get('/history', authenticateJWT, requireRoles(Role.OWNER, Role.MANAGER), getShiftHistory);
router.post('/open', authenticateJWT, requireRoles(Role.OWNER, Role.MANAGER, Role.CASHIER), openShift);
router.post('/close', authenticateJWT, requireRoles(Role.OWNER, Role.MANAGER, Role.CASHIER), closeShift);

export default router;
