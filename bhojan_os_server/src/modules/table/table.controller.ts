import { Request, Response } from 'express';
import { getTenantPrisma } from '../../config/prisma';

export const getTables = async (req: Request, res: Response) => {
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
    const tables = await tenantPrisma.table.findMany({
      orderBy: { tableNumber: 'asc' },
    });

    return res.status(200).json({
      success: true,
      data: tables,
      error: null,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    return res.status(500).json({
      success: false,
      data: null,
      error: {
        message: 'Failed to retrieve tables.',
        details: error.message,
      },
    });
  }
};

export const updateTableStatus = async (req: Request, res: Response) => {
  try {
    const restaurantId = req.user?.restaurantId;
    const { id } = req.params;
    const { status } = req.body;

    if (!restaurantId) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'Tenant context required.' },
      });
    }

    const tenantPrisma = getTenantPrisma(restaurantId);

    const updatedTable = await tenantPrisma.table.update({
      where: { id },
      data: { status },
    });

    return res.status(200).json({
      success: true,
      data: updatedTable,
      error: null,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    return res.status(500).json({
      success: false,
      data: null,
      error: {
        message: 'Failed to update table status.',
        details: error.message,
      },
    });
  }
};
