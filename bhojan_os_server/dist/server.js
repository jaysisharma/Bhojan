"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const http_1 = __importDefault(require("http"));
const socket_io_1 = require("socket.io");
const cors_1 = __importDefault(require("cors"));
const dotenv_1 = __importDefault(require("dotenv"));
const prisma_1 = require("./config/prisma");
const auth_routes_1 = __importDefault(require("./modules/auth/auth.routes"));
dotenv_1.default.config();
const app = (0, express_1.default)();
const server = http_1.default.createServer(app);
const io = new socket_io_1.Server(server, {
    cors: {
        origin: '*',
        methods: ['GET', 'POST'],
    },
});
const PORT = process.env.PORT || 3000;
app.use((0, cors_1.default)());
app.use(express_1.default.json());
// Registered routes
app.use('/api/v1/auth', auth_routes_1.default);
// Logger middleware
app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
    next();
});
// Health check endpoint
app.get('/api/v1/health', async (req, res) => {
    try {
        // Basic database ping test
        await prisma_1.prisma.$queryRaw `SELECT 1`;
        res.status(200).json({
            success: true,
            data: {
                status: 'UP',
                database: 'CONNECTED',
                timestamp: new Date().toISOString(),
            },
            error: null,
        });
    }
    catch (error) {
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
    socket.on('join:room', (data) => {
        if (data?.restaurantId) {
            const roomName = `restaurant_${data.restaurantId}`;
            socket.join(roomName);
            console.log(`Socket ${socket.id} joined room: ${roomName}`);
            socket.emit('joined', { success: true, room: roomName });
        }
    });
    // Client creates order
    socket.on('order:create', (data) => {
        if (data?.restaurantId) {
            const roomName = `restaurant_${data.restaurantId}`;
            socket.to(roomName).emit('order:new', data.payload);
            console.log(`Order event broadcasted to room: ${roomName}`);
        }
    });
    // Client updates order status
    socket.on('order:update-status', (data) => {
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
