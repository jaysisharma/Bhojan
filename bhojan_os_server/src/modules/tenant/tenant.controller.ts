import { Request, Response } from 'express';
import { getTenantPrisma } from '../../config/prisma';

export const getTenantSettings = async (req: Request, res: Response) => {
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
    const tenant = await tenantPrisma.tenant.findUnique({
      where: { id: restaurantId },
    });

    return res.status(200).json({
      success: true,
      data: tenant,
      error: null,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    return res.status(500).json({
      success: false,
      data: null,
      error: { message: 'Failed to retrieve tenant settings.', details: error.message },
    });
  }
};

export const updateTenantSettings = async (req: Request, res: Response) => {
  try {
    const restaurantId = req.user?.restaurantId;
    if (!restaurantId) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'Tenant context required.' },
      });
    }

    const { name, phone, address, panNumber, vatRate, scRate } = req.body;
    const tenantPrisma = getTenantPrisma(restaurantId);

    const updated = await tenantPrisma.tenant.update({
      where: { id: restaurantId },
      data: {
        name,
        phone,
        address,
        panNumber,
        vatRate: vatRate !== undefined ? Number(vatRate) : undefined,
        scRate: scRate !== undefined ? Number(scRate) : undefined,
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
      error: { message: 'Failed to update tenant settings.', details: error.message },
    });
  }
};
