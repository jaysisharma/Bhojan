"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_controller_1 = require("./auth.controller");
const auth_middleware_1 = require("../../middlewares/auth.middleware");
const router = (0, express_1.Router)();
// Public auth endpoints
router.post('/login', auth_controller_1.login);
router.post('/register', auth_controller_1.register);
// Protected auth endpoints (requires active JWT session)
router.post('/pin-verify', auth_middleware_1.authenticateJWT, auth_controller_1.verifyPin);
exports.default = router;
