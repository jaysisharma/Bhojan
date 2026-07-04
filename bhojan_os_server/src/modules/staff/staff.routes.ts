import { Router } from 'express';
import { getStaff, createStaff, updateStaff, toggleStaffActive, resetStaffAuth, deleteStaff } from './staff.controller';
import { authenticateJWT, requireRoles } from '../../middlewares/auth.middleware';
import { Role } from '@prisma/client';

const router = Router();

router.get('/', authenticateJWT, requireRoles(Role.OWNER, Role.MANAGER), getStaff);
router.post('/', authenticateJWT, requireRoles(Role.OWNER, Role.MANAGER), createStaff);
router.put('/:id', authenticateJWT, requireRoles(Role.OWNER, Role.MANAGER), updateStaff);
router.patch('/:id/toggle', authenticateJWT, requireRoles(Role.OWNER, Role.MANAGER), toggleStaffActive);
router.patch('/:id/reset-auth', authenticateJWT, requireRoles(Role.OWNER, Role.MANAGER), resetStaffAuth);
router.delete('/:id', authenticateJWT, requireRoles(Role.OWNER, Role.MANAGER), deleteStaff);

export default router;
