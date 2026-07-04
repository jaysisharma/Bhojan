import { Router } from 'express';
import { login, register, verifyPin, updateDeviceToken } from './auth.controller';
import { authenticateJWT } from '../../middlewares/auth.middleware';
import { validateBody } from '../../middlewares/validation.middleware';
import { loginSchema, registerSchema, pinVerifySchema } from './auth.schema';

const router = Router();

// Public auth endpoints
router.post('/login', validateBody(loginSchema), login);
router.post('/register', validateBody(registerSchema), register);

// Protected auth endpoints (requires active JWT session)
router.post('/pin-verify', authenticateJWT, validateBody(pinVerifySchema), verifyPin);
router.post('/device-token', authenticateJWT, updateDeviceToken);

export default router;
