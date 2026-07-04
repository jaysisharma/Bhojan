"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.requireRoles = exports.authenticateJWT = void 0;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
/**
 * Middleware to authenticate requests using JSON Web Tokens (JWT).
 * Extracts claims and attaches them to `req.user` for controller execution.
 */
const authenticateJWT = (req, res, next) => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({
            success: false,
            data: null,
            error: {
                message: 'Access Denied: No token provided.',
            },
        });
    }
    const token = authHeader.split(' ')[1];
    try {
        const secret = process.env.JWT_SECRET || 'dev_secret_key_bhojan_os_super_secure_hash';
        const decoded = jsonwebtoken_1.default.verify(token, secret);
        // Attach the verified tenant and user attributes to the request context
        req.user = decoded;
        // Optional Check: If client sends X-Restaurant-Id header, verify it matches token metadata
        const clientRestaurantId = req.headers['x-restaurant-id'];
        if (clientRestaurantId && clientRestaurantId !== decoded.restaurantId) {
            return res.status(403).json({
                success: false,
                data: null,
                error: {
                    message: 'Access Forbidden: Tenant context mismatch.',
                },
            });
        }
        next();
    }
    catch (error) {
        return res.status(403).json({
            success: false,
            data: null,
            error: {
                message: 'Invalid or expired token.',
                details: error.message,
            },
        });
    }
};
exports.authenticateJWT = authenticateJWT;
/**
 * Middleware generator to enforce Role-Based Access Control (RBAC) on endpoints.
 */
const requireRoles = (...allowedRoles) => {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({
                success: false,
                data: null,
                error: { message: 'Authentication required.' },
            });
        }
        if (!allowedRoles.includes(req.user.role)) {
            return res.status(403).json({
                success: false,
                data: null,
                error: {
                    message: `Access Forbidden: Required role missing. Allowed roles: ${allowedRoles.join(', ')}`,
                },
            });
        }
        next();
    };
};
exports.requireRoles = requireRoles;
