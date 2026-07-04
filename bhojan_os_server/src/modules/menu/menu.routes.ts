import { Router } from 'express';
import { getMenuItems, updateMenuItem } from './menu.controller';
import { authenticateJWT, requireRoles } from '../../middlewares/auth.middleware';
import { Role } from '@prisma/client';

const router = Router();

router.get('/items', authenticateJWT, getMenuItems);
router.patch('/items/:id', authenticateJWT, requireRoles(Role.OWNER, Role.MANAGER), updateMenuItem);

export default router;
