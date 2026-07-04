"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyPin = exports.register = exports.login = void 0;
const bcrypt_1 = __importDefault(require("bcrypt"));
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const prisma_1 = require("../../config/prisma");
const client_1 = require("@prisma/client");
const JWT_SECRET = process.env.JWT_SECRET || 'dev_secret_key_bhojan_os_super_secure_hash';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'dev_refresh_secret_key_bhojan_os_super_secure_hash';
/**
 * Handle staff login credentials validation and JWT token issuance.
 */
const login = async (req, res) => {
    const { phone, password } = req.body;
    if (!phone || !password) {
        return res.status(400).json({
            success: false,
            data: null,
            error: { message: 'Phone number and password are required.' },
        });
    }
    try {
        const user = await prisma_1.prisma.user.findUnique({
            where: { phone },
            include: { tenant: true },
        });
        if (!user || !user.isActive || !user.tenant.isActive) {
            return res.status(401).json({
                success: false,
                data: null,
                error: { message: 'Authentication failed. Invalid phone or password.' },
            });
        }
        const isMatch = await bcrypt_1.default.compare(password, user.passwordHash);
        if (!isMatch) {
            return res.status(401).json({
                success: false,
                data: null,
                error: { message: 'Authentication failed. Invalid phone or password.' },
            });
        }
        // Generate JWT access & refresh tokens
        const tokenPayload = {
            userId: user.id,
            role: user.role,
            restaurantId: user.restaurantId,
        };
        const accessToken = jsonwebtoken_1.default.sign(tokenPayload, JWT_SECRET, { expiresIn: '15m' });
        const refreshToken = jsonwebtoken_1.default.sign({ userId: user.id }, JWT_REFRESH_SECRET, { expiresIn: '7d' });
        return res.status(200).json({
            success: true,
            data: {
                accessToken,
                refreshToken,
                user: {
                    id: user.id,
                    name: user.name,
                    phone: user.phone,
                    role: user.role,
                    restaurantId: user.restaurantId,
                    restaurantName: user.tenant.name,
                },
            },
            error: null,
        });
    }
    catch (error) {
        return res.status(500).json({
            success: false,
            data: null,
            error: { message: 'Error logging in.', details: error.message },
        });
    }
};
exports.login = login;
/**
 * Handle tenant onboarding (Restaurant signup).
 * Sets up the Tenant (Restaurant) and its Owner profile in a transaction.
 */
const register = async (req, res) => {
    const { restaurantName, phone, password, address, panNumber, ownerName } = req.body;
    if (!restaurantName || !phone || !password || !address || !ownerName) {
        return res.status(400).json({
            success: false,
            data: null,
            error: { message: 'Missing required onboarding registration fields.' },
        });
    }
    try {
        // Check if phone number already exists
        const existingUser = await prisma_1.prisma.user.findUnique({
            where: { phone },
        });
        if (existingUser) {
            return res.status(409).json({
                success: false,
                data: null,
                error: { message: 'Phone number already registered.' },
            });
        }
        const saltRounds = 10;
        const passwordHash = await bcrypt_1.default.hash(password, saltRounds);
        // Default PIN for new restaurant owners is '1234'
        const defaultPinHash = await bcrypt_1.default.hash('1234', saltRounds);
        // Execute tenant and owner registration inside a database transaction
        const result = await prisma_1.prisma.$transaction(async (tx) => {
            const tenant = await tx.tenant.create({
                data: {
                    name: restaurantName,
                    phone,
                    address,
                    panNumber,
                    vatRate: 13.00, // Default VAT for Nepal compliance
                    scRate: 10.00, // Default service charge rate
                },
            });
            const user = await tx.user.create({
                data: {
                    restaurantId: tenant.id,
                    name: ownerName,
                    phone,
                    passwordHash,
                    pinHash: defaultPinHash,
                    role: client_1.Role.OWNER,
                },
            });
            return { tenant, user };
        });
        return res.status(201).json({
            success: true,
            data: {
                restaurantId: result.tenant.id,
                restaurantName: result.tenant.name,
                owner: {
                    id: result.user.id,
                    name: result.user.name,
                    phone: result.user.phone,
                    role: result.user.role,
                },
                message: 'Onboarding completed. Default PIN is 1234.',
            },
            error: null,
        });
    }
    catch (error) {
        return res.status(500).json({
            success: false,
            data: null,
            error: { message: 'Error during restaurant onboarding registration.', details: error.message },
        });
    }
};
exports.register = register;
/**
 * Handle staff PIN code verification to unlock client terminal screens.
 */
const verifyPin = async (req, res) => {
    const { pin } = req.body;
    if (!pin) {
        return res.status(400).json({
            success: false,
            data: null,
            error: { message: 'PIN code is required.' },
        });
    }
    // Expecting auth middleware to have populated user details
    if (!req.user) {
        return res.status(401).json({
            success: false,
            data: null,
            error: { message: 'Unauthorized session.' },
        });
    }
    try {
        const user = await prisma_1.prisma.user.findUnique({
            where: { id: req.user.userId },
        });
        if (!user || !user.isActive) {
            return res.status(404).json({
                success: false,
                data: null,
                error: { message: 'Staff member account not found or deactivated.' },
            });
        }
        const isMatch = await bcrypt_1.default.compare(pin, user.pinHash);
        if (!isMatch) {
            return res.status(401).json({
                success: false,
                data: { verified: false },
                error: { message: 'Incorrect PIN.' },
            });
        }
        return res.status(200).json({
            success: true,
            data: { verified: true },
            error: null,
        });
    }
    catch (error) {
        return res.status(500).json({
            success: false,
            data: null,
            error: { message: 'Error verifying PIN.', details: error.message },
        });
    }
};
exports.verifyPin = verifyPin;
