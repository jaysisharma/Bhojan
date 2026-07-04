import { Request, Response } from 'express';
import { getTenantPrisma } from '../../config/prisma';

export const createOrder = async (req: Request, res: Response) => {
  try {
    const restaurantId = req.user?.restaurantId;
    const waiterId = req.user?.userId;

    if (!restaurantId || !waiterId) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'Tenant or user credentials context required.' },
      });
    }

    const { id, tableId, items, subtotal } = req.body;

    if (!id || !tableId || !items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'Invalid order request payload.' },
      });
    }

    const tenantPrisma = getTenantPrisma(restaurantId);

    // Create order and update table state in a transaction
    const orderResult = await tenantPrisma.$transaction(async (tx) => {
      // 1. Create order
      const newOrder = await tx.order.create({
        data: {
          id,
          restaurantId,
          tableId,
          waiterId,
          subtotal,
          status: 'PENDING',
        },
      });

      // 2. Create order items
      for (const item of items) {
        const menuItem = await tx.menuItem.findUnique({
          where: { id: item.menuItemId },
        });

        if (!menuItem) {
          throw new Error(`Menu item not found: ${item.menuItemId}`);
        }

        await tx.orderItem.create({
          data: {
            orderId: newOrder.id,
            menuItemId: item.menuItemId,
            quantity: item.quantity,
            unitPrice: menuItem.price,
            notes: item.notes || '',
          },
        });
      }

      // 3. Mark table as OCCUPIED
      await tx.table.update({
        where: { id: tableId },
        data: { status: 'OCCUPIED' },
      });

      return newOrder;
    });

    return res.status(200).json({
      success: true,
      data: orderResult,
      error: null,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    return res.status(500).json({
      success: false,
      data: null,
      error: {
        message: 'Failed to create order.',
        details: error.message,
      },
    });
  }
};

export const updateOrderStatus = async (req: Request, res: Response) => {
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

    const updatedOrder = await tenantPrisma.order.update({
      where: { id },
      data: { status },
    });

    // If cancelled, free up the table associated with the order
    if (status === 'CANCELLED') {
      await tenantPrisma.table.update({
        where: { id: updatedOrder.tableId },
        data: { status: 'FREE' },
      });
    }

    return res.status(200).json({
      success: true,
      data: updatedOrder,
      error: null,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    return res.status(500).json({
      success: false,
      data: null,
      error: {
        message: 'Failed to update order status.',
        details: error.message,
      },
    });
  }
};
