import { Router } from 'express';
import { getDashboardMetrics } from './reports.controller';
import { authenticateJWT, requireRoles } from '../../middlewares/auth.middleware';
import { Role } from '@prisma/client';

const router = Router();

router.get('/dashboard', authenticateJWT, requireRoles(Role.OWNER, Role.MANAGER), getDashboardMetrics);

export default router;
