import { Router } from 'express';
import { createInvoice } from './billing.controller';
import { authenticateJWT, requireRoles } from '../../middlewares/auth.middleware';
import { Role } from '@prisma/client';

const router = Router();

router.post('/invoice', authenticateJWT, requireRoles(Role.OWNER, Role.MANAGER, Role.CASHIER), createInvoice);

export default router;
