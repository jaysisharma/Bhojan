import { Request, Response } from 'express';
import { getTenantPrisma } from '../../config/prisma';
import { PaymentMethod } from '@prisma/client';

export const createInvoice = async (req: Request, res: Response) => {
  try {
    const restaurantId = req.user?.restaurantId;
    const cashierId = req.user?.userId;

    if (!restaurantId || !cashierId) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'Tenant or user credentials context required.' },
      });
    }

    const { orderId, discountAmount = 0, paymentMethod } = req.body;

    if (!orderId || !paymentMethod) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'Invalid invoice request payload.' },
      });
    }

    // Validate payment method matches schema enums
    if (!Object.values(PaymentMethod).includes(paymentMethod as PaymentMethod)) {
      return res.status(400).json({
        success: false,
        data: null,
        error: { message: 'Invalid payment method option.' },
      });
    }

    const tenantPrisma = getTenantPrisma(restaurantId);

    const invoiceResult = await tenantPrisma.$transaction(async (tx) => {
      // 1. Fetch order details
      const order = await tx.order.findUnique({
        where: { id: orderId },
      });

      if (!order) {
        throw new Error(`Order not found: ${orderId}`);
      }

      if (order.status === 'SETTLED') {
        throw new Error('Order is already settled.');
      }

      // 2. Fetch tenant rates
      const tenant = await tx.tenant.findUnique({
        where: { id: restaurantId },
      });

      if (!tenant) {
        throw new Error(`Tenant not found: ${restaurantId}`);
      }

      const subtotal = Number(order.subtotal);
      const discount = Number(discountAmount);
      const taxableSubtotal = Math.max(0, subtotal - discount);

      const scPercentage = Number(tenant.scRate) / 100;
      const vatPercentage = Number(tenant.vatRate) / 100;

      const serviceCharge = taxableSubtotal * scPercentage;
      const vatAmount = (taxableSubtotal + serviceCharge) * vatPercentage;
      const grandTotal = taxableSubtotal + serviceCharge + vatAmount;

      // 3. Generate sequential invoice number
      const billCount = await tx.bill.count({
        where: { restaurantId },
      });
      const year = new Date().getFullYear();
      const billNumber = `INV-${year}-${(billCount + 1).toString().padStart(4, '0')}`;

      // 4. Create the Bill
      const bill = await tx.bill.create({
        data: {
          restaurantId,
          orderId,
          cashierId,
          billNumber,
          subtotal,
          discountAmount: discount,
          serviceCharge,
          vatAmount,
          grandTotal,
          paymentMethod: paymentMethod as PaymentMethod,
          paymentStatus: 'PAID',
        },
      });

      // 5. Settle the order
      await tx.order.update({
        where: { id: orderId },
        data: { status: 'SETTLED' },
      });

      // 6. Transition table to DIRTY
      await tx.table.update({
        where: { id: order.tableId },
        data: { status: 'DIRTY' },
      });

      // 7. Write Audit Log
      await tx.auditLog.create({
        data: {
          restaurantId,
          userId: cashierId,
          action: 'SETTLE_ORDER',
          entityName: 'Order',
          entityId: orderId,
          newValues: {
            billId: bill.id,
            billNumber,
            grandTotal,
            discountAmount: discount,
          },
        },
      });

      return bill;
    });

    return res.status(200).json({
      success: true,
      data: invoiceResult,
      error: null,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    return res.status(500).json({
      success: false,
      data: null,
      error: {
        message: 'Failed to create invoice.',
        details: error.message,
      },
    });
  }
};
