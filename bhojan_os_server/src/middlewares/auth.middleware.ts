import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { Role } from '@prisma/client';

export interface AuthUserPayload {
  userId: string;
  role: Role;
  restaurantId: string;
}

// Extend Express Request type declarations to support user context payload injection
declare global {
  namespace Express {
    interface Request {
      user?: AuthUserPayload;
    }
  }
}

/**
 * Middleware to authenticate requests using JSON Web Tokens (JWT).
 * Extracts claims and attaches them to `req.user` for controller execution.
 */
export const authenticateJWT = (req: Request, res: Response, next: NextFunction) => {
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
    const decoded = jwt.verify(token, secret) as AuthUserPayload;
    
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
  } catch (error: any) {
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

/**
 * Middleware generator to enforce Role-Based Access Control (RBAC) on endpoints.
 */
export const requireRoles = (...allowedRoles: Role[]) => {
  return (req: Request, res: Response, next: NextFunction) => {
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
