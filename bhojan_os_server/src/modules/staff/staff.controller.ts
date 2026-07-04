import { Request, Response } from 'express';
import bcrypt from 'bcrypt';
import { getTenantPrisma } from '../../config/prisma';
import { Role } from '@prisma/client';

export const getStaff = async (req: Request, res: Response) => {
  try {
    const restaurantId = req.user?.restaurantId;
    if (!restaurantId) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'Tenant context required.' },
      });
    }

    const tenantPrisma = getTenantPrisma(restaurantId);
    const staff = await tenantPrisma.user.findMany({
      where: { restaurantId },
      select: {
        id: true,
        name: true,
        phone: true,
        role: true,
        isActive: true,
        createdAt: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    return res.status(200).json({
      success: true,
      data: staff,
      error: null,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    return res.status(500).json({
      success: false,
      data: null,
      error: { message: 'Failed to retrieve staff roster.', details: error.message },
    });
  }
};

export const createStaff = async (req: Request, res: Response) => {
  try {
    const restaurantId = req.user?.restaurantId;
    if (!restaurantId) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'Tenant context required.' },
      });
    }

    const { name, phone, password, pin, role } = req.body;
    if (!name || !phone || !password || !pin || !role) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'Missing staff user configuration parameters.' },
      });
    }

    if (!Object.values(Role).includes(role as Role)) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'Invalid staff role assignment.' },
      });
    }

    const tenantPrisma = getTenantPrisma(restaurantId);

    const existing = await tenantPrisma.user.findUnique({
      where: { phone },
    });

    if (existing) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'Phone number already registered on system.' },
      });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const pinHash = await bcrypt.hash(pin, 10);

    const newStaff = await tenantPrisma.user.create({
      data: {
        restaurantId,
        name,
        phone,
        passwordHash,
        pinHash,
        role: role as Role,
      },
      select: {
        id: true,
        name: true,
        phone: true,
        role: true,
        isActive: true,
        createdAt: true,
      },
    });

    return res.status(201).json({
      success: true,
      data: newStaff,
      error: null,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    return res.status(500).json({
      success: false,
      data: null,
      error: { message: 'Failed to create staff user.', details: error.message },
    });
  }
};

export const updateStaff = async (req: Request, res: Response) => {
  try {
    const restaurantId = req.user?.restaurantId;
    const { id } = req.params;

    if (!restaurantId) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'Tenant context required.' },
      });
    }

    const { name, phone, role } = req.body;
    const tenantPrisma = getTenantPrisma(restaurantId);

    if (phone) {
      const existing = await tenantPrisma.user.findFirst({
        where: { phone, NOT: { id } },
      });
      if (existing) {
        return res.status(400).json({
          success: false,
          data: null,
          error: { message: 'Phone number already registered on another user.' },
        });
      }
    }

    const updated = await tenantPrisma.user.update({
      where: { id },
      data: {
        name,
        phone,
        role: role as Role,
      },
      select: {
        id: true,
        name: true,
        phone: true,
        role: true,
        isActive: true,
      },
    });

    return res.status(200).json({
      success: true,
      data: updated,
      error: null,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    return res.status(500).json({
      success: false,
      data: null,
      error: { message: 'Failed to update staff user.', details: error.message },
    });
  }
};

export const toggleStaffActive = async (req: Request, res: Response) => {
  try {
    const restaurantId = req.user?.restaurantId;
    const { id } = req.params;
    const { isActive } = req.body;

    if (!restaurantId) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'Tenant context required.' },
      });
    }

    const tenantPrisma = getTenantPrisma(restaurantId);

    const updated = await tenantPrisma.user.update({
      where: { id },
      data: { isActive: !!isActive },
      select: { id: true, name: true, phone: true, role: true, isActive: true },
    });

    return res.status(200).json({
      success: true,
      data: updated,
      error: null,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    return res.status(500).json({
      success: false,
      data: null,
      error: { message: 'Failed to toggle active status.', details: error.message },
    });
  }
};

export const resetStaffAuth = async (req: Request, res: Response) => {
  try {
    const restaurantId = req.user?.restaurantId;
    const { id } = req.params;
    const { password, pin } = req.body;

    if (!restaurantId) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'Tenant context required.' },
      });
    }

    if (!password && !pin) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'Password or PIN required for resets.' },
      });
    }

    const tenantPrisma = getTenantPrisma(restaurantId);

    const dataToUpdate: any = {};
    if (password) {
      dataToUpdate.passwordHash = await bcrypt.hash(password, 10);
    }
    if (pin) {
      dataToUpdate.pinHash = await bcrypt.hash(pin, 10);
    }

    await tenantPrisma.user.update({
      where: { id },
      data: dataToUpdate,
    });

    return res.status(200).json({
      success: true,
      data: { message: 'Credentials updated successfully.' },
      error: null,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    return res.status(500).json({
      success: false,
      data: null,
      error: { message: 'Failed to reset staff credentials.', details: error.message },
    });
  }
};

export const deleteStaff = async (req: Request, res: Response) => {
  try {
    const restaurantId = req.user?.restaurantId;
    const { id } = req.params;

    if (!restaurantId) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'Tenant context required.' },
      });
    }

    if (id === req.user?.userId) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'You cannot delete your own active owner session account.' },
      });
    }

    const tenantPrisma = getTenantPrisma(restaurantId);
    await tenantPrisma.user.delete({
      where: { id },
    });

    return res.status(200).json({
      success: true,
      data: { message: 'Staff member account deleted successfully.' },
      error: null,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    return res.status(500).json({
      success: false,
      data: null,
      error: { message: 'Failed to delete staff user.', details: error.message },
    });
  }
};
