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

export const createTable = async (req: Request, res: Response) => {
  try {
    const restaurantId = req.user?.restaurantId;
    const { tableNumber, capacity, section } = req.body;

    if (!restaurantId) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'Tenant context required.' },
      });
    }

    if (!tableNumber || !capacity || !section) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'Missing table fields: tableNumber, capacity, and section are required.' },
      });
    }

    const tenantPrisma = getTenantPrisma(restaurantId);

    // Check if tableNumber already exists for this tenant
    const existingTable = await tenantPrisma.table.findFirst({
      where: { tableNumber },
    });

    if (existingTable) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: `Table number "${tableNumber}" already exists.` },
      });
    }

    const newTable = await tenantPrisma.table.create({
      data: {
        restaurantId,
        tableNumber,
        capacity: Number(capacity),
        section,
        status: 'FREE',
      },
    });

    return res.status(201).json({
      success: true,
      data: newTable,
      error: null,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    return res.status(500).json({
      success: false,
      data: null,
      error: {
        message: 'Failed to create table.',
        details: error.message,
      },
    });
  }
};

export const updateTable = async (req: Request, res: Response) => {
  try {
    const restaurantId = req.user?.restaurantId;
    const { id } = req.params;
    const { tableNumber, capacity, section } = req.body;

    if (!restaurantId) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'Tenant context required.' },
      });
    }

    const tenantPrisma = getTenantPrisma(restaurantId);

    // Check if tableNumber is taken by another table
    if (tableNumber) {
      const existingTable = await tenantPrisma.table.findFirst({
        where: { 
          tableNumber,
          id: { not: id }
        },
      });

      if (existingTable) {
        return res.status(400).json({
          success: false,
          data: null,
          error: { message: `Table number "${tableNumber}" is already in use by another table.` },
        });
      }
    }

    const updatedTable = await tenantPrisma.table.update({
      where: { id },
      data: {
        ...(tableNumber && { tableNumber }),
        ...(capacity !== undefined && { capacity: Number(capacity) }),
        ...(section && { section }),
      },
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
        message: 'Failed to update table details.',
        details: error.message,
      },
    });
  }
};

export const deleteTable = async (req: Request, res: Response) => {
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

    const tenantPrisma = getTenantPrisma(restaurantId);

    // Find the table and make sure it is FREE
    const table = await tenantPrisma.table.findUnique({
      where: { id },
    });

    if (!table) {
      return res.status(404).json({
        success: false,
        data: null,
        error: { message: 'Table not found.' },
      });
    }

    if (table.status !== 'FREE') {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'Cannot delete a table that is not FREE.' },
      });
    }

    await tenantPrisma.table.delete({
      where: { id },
    });

    return res.status(200).json({
      success: true,
      data: { id },
      error: null,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    return res.status(500).json({
      success: false,
      data: null,
      error: {
        message: 'Failed to delete table.',
        details: error.message,
      },
    });
  }
};

