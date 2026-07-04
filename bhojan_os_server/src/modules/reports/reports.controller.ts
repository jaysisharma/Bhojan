import { Request, Response } from 'express';
import { getTenantPrisma } from '../../config/prisma';

export const getDashboardMetrics = async (req: Request, res: Response) => {
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

    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);

    const endOfToday = new Date();
    endOfToday.setHours(23, 59, 59, 999);

    // 1. Fetch bills for today
    const bills = await tenantPrisma.bill.findMany({
      where: {
        restaurantId,
        createdAt: {
          gte: startOfToday,
          lte: endOfToday,
        },
      },
    });

    const totalSales = bills.reduce((sum, bill) => sum + Number(bill.grandTotal), 0);
    const ordersCount = await tenantPrisma.order.count({
      where: {
        restaurantId,
        createdAt: {
          gte: startOfToday,
          lte: endOfToday,
        },
      },
    });

    const avgOrderValue = ordersCount > 0 ? totalSales / ordersCount : 0;

    // 2. Payment breakdowns
    const payments = {
      CASH: bills.filter((b) => b.paymentMethod === 'CASH').reduce((s, b) => s + Number(b.grandTotal), 0),
      FONEPAY: bills.filter((b) => b.paymentMethod === 'FONEPAY').reduce((s, b) => s + Number(b.grandTotal), 0),
      CARD: bills.filter((b) => b.paymentMethod === 'CARD').reduce((s, b) => s + Number(b.grandTotal), 0),
      CREDIT: bills.filter((b) => b.paymentMethod === 'CREDIT').reduce((s, b) => s + Number(b.grandTotal), 0),
    };

    // 3. Top selling items
    const orderItems = await tenantPrisma.orderItem.findMany({
      where: {
        order: {
          restaurantId,
          createdAt: {
            gte: startOfToday,
            lte: endOfToday,
          },
        },
      },
      include: {
        menuItem: {
          select: { name: true },
        },
      },
    });

    const itemsMap: { [name: string]: number } = {};
    orderItems.forEach((oi) => {
      const name = oi.menuItem.name;
      itemsMap[name] = (itemsMap[name] || 0) + oi.quantity;
    });

    const topSellingItems = Object.entries(itemsMap)
      .map(([name, quantity]) => ({ name, quantity }))
      .sort((a, b) => b.quantity - a.quantity)
      .slice(0, 5);

    // 4. Daily historical metrics for the past 7 days (Weekly trend)
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    sevenDaysAgo.setHours(0, 0, 0, 0);

    const weeklyBills = await tenantPrisma.bill.findMany({
      where: {
        restaurantId,
        createdAt: {
          gte: sevenDaysAgo,
        },
      },
    });

    const weeklyTrend: { [date: string]: number } = {};
    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const dateStr = d.toISOString().substring(0, 10);
      weeklyTrend[dateStr] = 0;
    }

    weeklyBills.forEach((bill) => {
      const dateStr = bill.createdAt.toISOString().substring(0, 10);
      if (weeklyTrend[dateStr] !== undefined) {
        weeklyTrend[dateStr] += Number(bill.grandTotal);
      }
    });

    const trend = Object.entries(weeklyTrend).map(([date, amount]) => ({
      date,
      amount,
    }));

    return res.status(200).json({
      success: true,
      data: {
        totalSales,
        ordersCount,
        avgOrderValue,
        payments,
        topSellingItems,
        weeklyTrend: trend,
      },
      error: null,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    return res.status(500).json({
      success: false,
      data: null,
      error: { message: 'Failed to compile reports summaries.', details: error.message },
    });
  }
};
