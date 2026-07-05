import { PrismaClient, Role } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('Starting database seeding...');

  // Clean up existing data (Order of deletion matters due to foreign keys)
  await prisma.auditLog.deleteMany();
  await prisma.bill.deleteMany();
  await prisma.orderItem.deleteMany();
  await prisma.order.deleteMany();
  await prisma.table.deleteMany();
  await prisma.menuItemModifier.deleteMany();
  await prisma.menuItem.deleteMany();
  await prisma.category.deleteMany();
  await prisma.shift.deleteMany();
  await prisma.user.deleteMany();
  await prisma.tenant.deleteMany();

  console.log('Cleared existing data.');

  // 1. Create Tenant (Restaurant)
  const tenant = await prisma.tenant.create({
    data: {
      name: 'Kathmandu Cafe & Diner',
      phone: '+97714444444',
      address: 'Durbarmarg, Kathmandu, Nepal',
      panNumber: '601234567',
      vatRate: 13.00,
      scRate: 10.00,
    },
  });
  console.log(`Created Tenant: ${tenant.name} (${tenant.id})`);

  // 2. Create Users (Staff with hashed passwords & PINs)
  const saltRounds = 10;
  
  const usersData = [
    {
      name: 'Jimmy',
      phone: '9801111111',
      password: 'ownerpassword',
      pin: '1111',
      role: Role.OWNER,
    },
    {
      name: 'Sita Kumari',
      phone: '9802222222',
      password: 'cashierpassword',
      pin: '2222',
      role: Role.CASHIER,
    },
    {
      name: 'Hari Thapa',
      phone: '9803333333',
      password: 'waiterpassword',
      pin: '3333',
      role: Role.WAITER,
    },
    {
      name: 'Gita Shrestha',
      phone: '9804444444',
      password: 'kitchenpassword',
      pin: '4444',
      role: Role.KITCHEN,
    },
  ];

  for (const userData of usersData) {
    const passwordHash = await bcrypt.hash(userData.password, saltRounds);
    const pinHash = await bcrypt.hash(userData.pin, saltRounds);

    const user = await prisma.user.create({
      data: {
        restaurantId: tenant.id,
        name: userData.name,
        phone: userData.phone,
        passwordHash,
        pinHash,
        role: userData.role,
      },
    });
    console.log(`Created User: ${user.name} as ${user.role}`);
  }

  // 3. Create Tables
  const tablesData = [
    { tableNumber: 'T-1', capacity: 4, section: 'Ground Floor' },
    { tableNumber: 'T-2', capacity: 2, section: 'Ground Floor' },
    { tableNumber: 'T-3', capacity: 4, section: 'Ground Floor' },
    { tableNumber: 'Bar-1', capacity: 2, section: 'Ground Floor' },
    { tableNumber: 'R-1', capacity: 6, section: 'Rooftop Garden' },
    { tableNumber: 'R-2', capacity: 4, section: 'Rooftop Garden' },
    { tableNumber: 'R-3', capacity: 8, section: 'Rooftop Garden' },
  ];

  for (const tableData of tablesData) {
    await prisma.table.create({
      data: {
        restaurantId: tenant.id,
        tableNumber: tableData.tableNumber,
        capacity: tableData.capacity,
        section: tableData.section,
        status: 'FREE',
      },
    });
  }
  console.log(`Created ${tablesData.length} dining tables.`);

  // 4. Create Categories
  const categoryMomo = await prisma.category.create({
    data: { restaurantId: tenant.id, name: 'Momo', sortOrder: 1 },
  });
  const categoryMain = await prisma.category.create({
    data: { restaurantId: tenant.id, name: 'Main Course', sortOrder: 2 },
  });
  const categoryBeverage = await prisma.category.create({
    data: { restaurantId: tenant.id, name: 'Beverages', sortOrder: 3 },
  });
  console.log('Created Menu Categories.');

  // 5. Create Menu Items
  // Momo Items
  const chickenMomo = await prisma.menuItem.create({
    data: {
      restaurantId: tenant.id,
      categoryId: categoryMomo.id,
      name: 'Chicken Momo',
      description: 'Steam chicken momo served with tomato sesame chutney',
      price: 250.00,
      isVeg: false,
    },
  });

  const vegMomo = await prisma.menuItem.create({
    data: {
      restaurantId: tenant.id,
      categoryId: categoryMomo.id,
      name: 'Veg Momo',
      description: 'Steam paneer and mixed veg momo served with sesame chutney',
      price: 200.00,
      isVeg: true,
    },
  });

  // Main Course Items
  const chickenChowmein = await prisma.menuItem.create({
    data: {
      restaurantId: tenant.id,
      categoryId: categoryMain.id,
      name: 'Chicken Chowmein',
      description: 'Stir-fried noodles cooked with chicken chunks and fresh vegetables',
      price: 280.00,
      isVeg: false,
    },
  });

  // Beverage Items
  const icedAmericano = await prisma.menuItem.create({
    data: {
      restaurantId: tenant.id,
      categoryId: categoryBeverage.id,
      name: 'Iced Americano',
      description: 'Double espresso shot poured over ice water',
      price: 150.00,
      isVeg: true,
    },
  });

  const milkTea = await prisma.menuItem.create({
    data: {
      restaurantId: tenant.id,
      categoryId: categoryBeverage.id,
      name: 'Nepalese Milk Tea',
      description: 'Traditional spiced tea brewed with milk and cardamom',
      price: 80.00,
      isVeg: true,
    },
  });

  console.log('Created Menu Items.');

  // 6. Create MenuItem Modifiers
  await prisma.menuItemModifier.createMany({
    data: [
      { menuItemId: chickenMomo.id, name: 'Cheese Momo (Add-on)', price: 60.00 },
      { menuItemId: chickenMomo.id, name: 'Jhol Momo style', price: 40.00 },
      { menuItemId: vegMomo.id, name: 'Kothey style (Fried)', price: 30.00 },
      { menuItemId: icedAmericano.id, name: 'Extra Shot Espresso', price: 50.00 },
      { menuItemId: icedAmericano.id, name: 'Caramel Syrup', price: 40.00 },
    ],
  });
  console.log('Created Menu Modifiers.');

  console.log('Database seeding successfully finished!');
}

main()
  .catch((e) => {
    console.error('Error during database seed execution:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
