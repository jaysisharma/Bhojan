import express, { Request, Response } from 'express';
import http from 'http';
import { Server } from 'socket.io';
import cors from 'cors';
import dotenv from 'dotenv';
import { prisma } from './config/prisma';
import authRouter from './modules/auth/auth.routes';
import menuRouter from './modules/menu/menu.routes';
import tableRouter from './modules/table/table.routes';
import orderRouter from './modules/order/order.routes';
import billingRouter from './modules/billing/billing.routes';

dotenv.config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
});

const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Registered routes
app.use('/api/v1/auth', authRouter);
app.use('/api/v1/menu', menuRouter);
app.use('/api/v1/tables', tableRouter);
app.use('/api/v1/orders', orderRouter);
app.use('/api/v1/billing', billingRouter);

// Logger middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// Health check endpoint
app.get('/api/v1/health', async (req: Request, res: Response) => {
  try {
    // Basic database ping test
    await prisma.$queryRaw`SELECT 1`;
    res.status(200).json({
      success: true,
      data: {
        status: 'UP',
        database: 'CONNECTED',
        timestamp: new Date().toISOString(),
      },
      error: null,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      data: null,
      error: {
        message: 'Database connection failed',
        details: error.message,
      },
    });
  }
});

// WebSocket communication routing
io.on('connection', (socket) => {
  console.log(`Socket client connected: ${socket.id}`);

  // Joining tenant room
  socket.on('join:room', (data: { restaurantId: string; token: string }) => {
    if (data?.restaurantId) {
      const roomName = `restaurant_${data.restaurantId}`;
      socket.join(roomName);
      console.log(`Socket ${socket.id} joined room: ${roomName}`);
      socket.emit('joined', { success: true, room: roomName });
    }
  });

  // Client creates order
  socket.on('order:create', (data: { restaurantId: string; orderId: string; payload: any }) => {
    if (data?.restaurantId) {
      const roomName = `restaurant_${data.restaurantId}`;
      socket.to(roomName).emit('order:new', data.payload);
      console.log(`Order event broadcasted to room: ${roomName}`);
    }
  });

  // Client updates order status
  socket.on('order:update-status', (data: { restaurantId: string; orderId: string; status: string }) => {
    if (data?.restaurantId) {
      const roomName = `restaurant_${data.restaurantId}`;
      socket.to(roomName).emit('order:updated', { orderId: data.orderId, status: data.status });
      console.log(`Order status update broadcasted to room: ${roomName}`);
    }
  });

  socket.on('disconnect', () => {
    console.log(`Socket client disconnected: ${socket.id}`);
  });
});

server.listen(PORT, () => {
  console.log(`=========================================`);
  console.log(` BhojanOS Server running on port ${PORT}`);
  console.log(` Database: PostgreSQL via Prisma Client`);
  console.log(` Real-time layer: Socket.IO Gateway active`);
  console.log(`=========================================`);
});
