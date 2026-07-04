import { Router } from 'express';
import { login, register, verifyPin } from './auth.controller';
import { authenticateJWT } from '../../middlewares/auth.middleware';

const router = Router();

// Public auth endpoints
router.post('/login', login);
router.post('/register', register);

// Protected auth endpoints (requires active JWT session)
router.post('/pin-verify', authenticateJWT, verifyPin);

export default router;
