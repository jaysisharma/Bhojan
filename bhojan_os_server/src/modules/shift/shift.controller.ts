import { Request, Response } from 'express';
import { getTenantPrisma } from '../../config/prisma';

export const openShift = async (req: Request, res: Response) => {
  try {
    const restaurantId = req.user?.restaurantId;
    const openedById = req.user?.userId;

    if (!restaurantId || !openedById) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'Tenant or user context credentials required.' },
      });
    }

    const { openingCash } = req.body;
    if (openingCash === undefined || openingCash === null || isNaN(Number(openingCash))) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'Valid opening cash balance required.' },
      });
    }

    const tenantPrisma = getTenantPrisma(restaurantId);

    // Verify if there is already an open shift
    const activeShift = await tenantPrisma.shift.findFirst({
      where: { restaurantId, status: 'OPEN' },
    });

    if (activeShift) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'An active shift is already open. Close it before opening a new one.' },
      });
    }

    const newShift = await tenantPrisma.shift.create({
      data: {
        restaurantId,
        openedById,
        openingCash: Number(openingCash),
        status: 'OPEN',
      },
      include: {
        openedBy: { select: { id: true, name: true, role: true } },
      },
    });

    return res.status(200).json({
      success: true,
      data: newShift,
      error: null,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    return res.status(500).json({
      success: false,
      data: null,
      error: { message: 'Failed to open shift.', details: error.message },
    });
  }
};

export const closeShift = async (req: Request, res: Response) => {
  try {
    const restaurantId = req.user?.restaurantId;
    const closedById = req.user?.userId;

    if (!restaurantId || !closedById) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'Tenant or user context credentials required.' },
      });
    }

    const { actualCash } = req.body;
    if (actualCash === undefined || actualCash === null || isNaN(Number(actualCash))) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'Valid actual drawer closing cash required.' },
      });
    }

    const tenantPrisma = getTenantPrisma(restaurantId);

    // Fetch active open shift
    const activeShift = await tenantPrisma.shift.findFirst({
      where: { restaurantId, status: 'OPEN' },
    });

    if (!activeShift) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'No active shift found to close.' },
      });
    }

    // Calculate cash bills total between openedAt and now
    const cashBills = await tenantPrisma.bill.findMany({
      where: {
        restaurantId,
        paymentMethod: 'CASH',
        createdAt: {
          gte: activeShift.openedAt,
        },
      },
    });

    const cashSales = cashBills.reduce((sum, bill) => sum + Number(bill.grandTotal), 0);
    const expectedCash = Number(activeShift.openingCash) + cashSales;
    const actual = Number(actualCash);
    const cashDiff = actual - expectedCash;

    const closedShift = await tenantPrisma.shift.update({
      where: { id: activeShift.id },
      data: {
        closedById,
        closedAt: new Date(),
        closingCash: actual,
        expectedCash,
        actualCash: actual,
        cashDiff,
        status: 'CLOSED',
      },
      include: {
        openedBy: { select: { id: true, name: true, role: true } },
        closedBy: { select: { id: true, name: true, role: true } },
      },
    });

    return res.status(200).json({
      success: true,
      data: closedShift,
      error: null,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    return res.status(500).json({
      success: false,
      data: null,
      error: { message: 'Failed to close shift.', details: error.message },
    });
  }
};

export const getActiveShift = async (req: Request, res: Response) => {
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
    const activeShift = await tenantPrisma.shift.findFirst({
      where: { restaurantId, status: 'OPEN' },
      include: {
        openedBy: { select: { id: true, name: true, role: true } },
      },
    });

    return res.status(200).json({
      success: true,
      data: activeShift,
      error: null,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    return res.status(500).json({
      success: false,
      data: null,
      error: { message: 'Failed to retrieve active shift.', details: error.message },
    });
  }
};

export const getShiftHistory = async (req: Request, res: Response) => {
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
    const history = await tenantPrisma.shift.findMany({
      where: { restaurantId },
      orderBy: { openedAt: 'desc' },
      include: {
        openedBy: { select: { id: true, name: true, role: true } },
        closedBy: { select: { id: true, name: true, role: true } },
      },
    });

    return res.status(200).json({
      success: true,
      data: history,
      error: null,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    return res.status(500).json({
      success: false,
      data: null,
      error: { message: 'Failed to retrieve shift history.', details: error.message },
    });
  }
};
