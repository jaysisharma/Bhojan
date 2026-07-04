import { Router } from 'express';
import { getTables, updateTableStatus } from './table.controller';
import { authenticateJWT } from '../../middlewares/auth.middleware';

const router = Router();

router.get('/', authenticateJWT, getTables);
router.patch('/:id/status', authenticateJWT, updateTableStatus);

export default router;
