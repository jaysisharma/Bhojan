import { Router } from 'express';
import { 
  getTables, 
  updateTableStatus,
  createTable,
  updateTable,
  deleteTable
} from './table.controller';
import { authenticateJWT, requireRoles } from '../../middlewares/auth.middleware';
import { Role } from '@prisma/client';

const router = Router();

router.get('/', authenticateJWT, getTables);
router.patch('/:id/status', authenticateJWT, updateTableStatus);

router.post('/', authenticateJWT, requireRoles(Role.OWNER, Role.MANAGER), createTable);
router.put('/:id', authenticateJWT, requireRoles(Role.OWNER, Role.MANAGER), updateTable);
router.delete('/:id', authenticateJWT, requireRoles(Role.OWNER, Role.MANAGER), deleteTable);

export default router;

