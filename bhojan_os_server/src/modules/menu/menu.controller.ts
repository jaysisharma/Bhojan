import { Request, Response } from 'express';
import { getTenantPrisma } from '../../config/prisma';

export const getMenuItems = async (req: Request, res: Response) => {
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

    // Fetch all active menu items, resolving categories and modifiers
    const items = await tenantPrisma.menuItem.findMany({
      where: { isDeleted: false },
      include: {
        category: true,
        modifiers: true,
      },
    });

    return res.status(200).json({
      success: true,
      data: items,
      error: null,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    return res.status(500).json({
      success: false,
      data: null,
      error: {
        message: 'Failed to retrieve menu items.',
        details: error.message,
      },
    });
  }
};

export const updateMenuItem = async (req: Request, res: Response) => {
  try {
    const restaurantId = req.user?.restaurantId;
    const { id } = req.params;
    const { isAvailable } = req.body;

    if (!restaurantId) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'Tenant context required.' },
      });
    }

    const tenantPrisma = getTenantPrisma(restaurantId);

    const updatedItem = await tenantPrisma.menuItem.update({
      where: { id },
      data: { isAvailable },
    });

    return res.status(200).json({
      success: true,
      data: updatedItem,
      error: null,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    return res.status(500).json({
      success: false,
      data: null,
      error: {
        message: 'Failed to update menu item.',
        details: error.message,
      },
    });
  }
};
