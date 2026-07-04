import { Router } from 'express';
import { getTenantSettings, updateTenantSettings } from './tenant.controller';
import { authenticateJWT, requireRoles } from '../../middlewares/auth.middleware';
import { Role } from '@prisma/client';

const router = Router();

router.get('/', authenticateJWT, getTenantSettings);
router.put('/', authenticateJWT, requireRoles(Role.OWNER, Role.MANAGER), updateTenantSettings);

export default router;
