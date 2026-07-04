import { z } from 'zod';

export const loginSchema = z.object({
  phone: z.string().min(8, 'Phone number must be at least 8 digits'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
});

export const registerSchema = z.object({
  restaurantName: z.string().min(2, 'Restaurant name must be at least 2 characters'),
  ownerName: z.string().min(2, 'Owner name must be at least 2 characters'),
  phone: z.string().min(8, 'Phone number must be at least 8 digits'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  address: z.string().min(2, 'Address must be at least 2 characters'),
  panNumber: z.string().min(9, 'PAN number must be at least 9 digits').optional(),
});

export const pinVerifySchema = z.object({
  pin: z.string().length(4, 'PIN must be exactly 4 digits'),
});
