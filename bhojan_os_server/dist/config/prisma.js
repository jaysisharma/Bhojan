"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getTenantPrisma = exports.prisma = void 0;
const client_1 = require("@prisma/client");
exports.prisma = new client_1.PrismaClient();
// List of database models that contain the `restaurantId` column to be isolated per tenant
const modelsWithTenant = [
    'User',
    'Category',
    'MenuItem',
    'Table',
    'Order',
    'Bill',
    'AuditLog'
];
/**
 * Returns an extended Prisma client instance scoped to a specific restaurant tenant.
 * Automatically injects `restaurantId` into queries and insertions to enforce data isolation.
 */
const getTenantPrisma = (restaurantId) => {
    return exports.prisma.$extends({
        query: {
            $allModels: {
                async $allOperations({ model, operation, args, query }) {
                    if (modelsWithTenant.includes(model)) {
                        const anyArgs = args;
                        // Scope reads, updates and deletes (all operations except create/createMany)
                        if (operation !== 'create' && operation !== 'createMany') {
                            anyArgs.where = anyArgs.where || {};
                            anyArgs.where.restaurantId = restaurantId;
                        }
                        // Enforce tenant ID on insertions
                        if (operation === 'create') {
                            anyArgs.data = anyArgs.data || {};
                            anyArgs.data.restaurantId = restaurantId;
                        }
                        else if (operation === 'createMany') {
                            if (Array.isArray(anyArgs.data)) {
                                anyArgs.data.forEach((item) => {
                                    item.restaurantId = restaurantId;
                                });
                            }
                            else if (anyArgs.data && 'data' in anyArgs.data && Array.isArray(anyArgs.data.data)) {
                                anyArgs.data.data.forEach((item) => {
                                    item.restaurantId = restaurantId;
                                });
                            }
                        }
                    }
                    return query(args);
                },
            },
        },
    });
};
exports.getTenantPrisma = getTenantPrisma;
