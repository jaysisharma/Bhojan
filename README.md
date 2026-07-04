# BhojanOS (भोजनOS) — Master System Specification & Architecture Design
## Multi-Tenant, Mobile-First, Offline-Friendly Restaurant Operating System & SaaS

---

## 1. Document Control & Metadata
* **Project Name:** BhojanOS (भोजनOS)
* **Status:** Approved / Architectural Baseline
* **Version:** 1.0.0
* **Target Audience:** Core Engineering Team, DevOps, QA, Product Managers, Security Auditing Team
* **Primary Target Market:** Nepal (Phase 1), South Asia (Phase 2), Global (Phase 3)
* **Primary Platform:** Android Mobile & Tablet (Flutter)
* **Backend Platform:** Node.js, Express, TypeScript, Prisma ORM, PostgreSQL (AWS RDS)

---

## 2. Project Overview & Business Case

### 2.1 Why BhojanOS Exists
In emerging economies like Nepal, the restaurant sector is a vital economic driver. However, operations are plagued by structural challenges:
* **Pen-and-Paper Reliance:** High rates of order mismatches, lost Kitchen Order Tickets (KOTs), pricing errors, and long customer wait times.
* **Unstable Infrastructure:** Constant threats of internet outages, electricity fluctuations, and hardware failures. Existing desktop-based POS software requires dedicated power backups (UPS/inverters) and expensive hardware.
* **High Staff Turnover:** Restaurant staff (waiters, kitchen crews) rotate frequently. Complex systems with steep learning curves lead to training overheads and operational friction.
* **Lack of Data Visibility:** Owners struggle to track performance across margins, popular items, inventory wastage, and cashier leakages.

BhojanOS replaces heavy, static, and complex systems with a lightweight, secure, **mobile-first, offline-first operating system** running on affordable Android devices. 

```
┌─────────────────────────────────────────────────────────────┐
│                          BhojanOS                           │
│               "The Modern Restaurant Engine"               │
├──────────────────────────────┬──────────────────────────────┤
│      Operations Control      │         SaaS Core            │
│  - Instant Digital KOTs      │  - Multi-Tenant Isolation    │
│  - Real-Time Kitchen Sync    │  - Offline-First Auto-Sync   │
│  - One-Tap Mobile Billing    │  - Granular Role Security    │
└──────────────────────────────┴──────────────────────────────┘
```

### 2.2 Problems Solved
* **Operational Latency:** Reduces the time from order taking to kitchen preparation by up to 40% using digital routing instead of physical paper KOT runner delivery.
* **Connectivity Bottlenecks:** Operates fully offline. Waiters can input orders, kitchen screens update, and cashiers can issue bills without an active internet connection. The system reconciles data transparently when connection is restored.
* **Revenue Leakage:** Every modification, deletion, or discount is tracked and authenticated via owner/manager PIN overrides, preventing unauthorized bill alterations.
* **Infrastructure Costs:** Eliminates the need for expensive desktop PCs, servers, and heavy UPS configurations. Works on basic 4G/Wi-Fi Android tablets or smartphones and connects directly to Bluetooth thermal receipt printers.

### 2.3 Target Customers & Market Segments
1. **Cafes & Coffee Shops:** Fast checkout speed, high volume, modification of items (e.g., milk choices, syrup add-ons), quick-service flow.
2. **Small Restaurants & Diners:** Simple table layouts, dynamic seat ordering, fast table turnaround tracking.
3. **Fine Dining Restaurants:** Multi-course order management, table merging, waiter assignments, custom bills, separate tax and service charges.

### 2.4 SaaS Business Model & Pricing Strategy
BhojanOS is structured as a tiered subscription B2B SaaS model.

| Subscription Tier | Ideal For | Features Included | Monthly Price (NPR) | Annual Price (NPR) |
| :--- | :--- | :--- | :--- | :--- |
| **Basic (Sajilo)** | Small Cafes / Outlets | 1 Tenant, 3 User Accounts, Offline POS, Basic Menu Management, Standard Local Reports. | NPR 1,500 / mo | NPR 15,000 / yr |
| **Pro (Prakash)** | Mid-sized Restaurants | Unlimited Users, Real-time KDS Sync, Multi-Device local networking, Advanced cloud analytics, SMS billing integrations. | NPR 4,000 / mo | NPR 40,000 / yr |
| **Enterprise (Uttama)** | Multi-outlet / Fine Dining | Multi-location dashboard, Custom integrations, Dedicated support, Priority cloud hosting, Custom inventory pipelines. | Custom Quote | Custom Quote |

* **Billing Management:** Fully integrated via local digital wallets (e.g., eSewa, Khalti, Fonepay) and wire transfers. Automated tenant suspension rules apply with a 7-day grace period.

---

## 3. Mission & Core Philosophy

### 3.1 The Simple UI Rule
If a waiter, cashier, or kitchen worker cannot learn to use their primary interface within **five minutes of training**, the design is considered a failure and must be iterated. All UI actions are restricted to a shallow hierarchy:
* **Max 3 taps** to place a standard order.
* **Max 2 taps** to print a bill.
* **Highly iconographic and high-contrast designs** to support low-literacy or fast-paced operational scenarios.

### 3.2 Core Architectural Principles
* **Mobile-First & Touch-Native:** Custom-tailored layouts for 5"-7" mobile devices (waiters) and 10"+ tablets (cashier and kitchen displays).
* **Robust Offline Capability:** A restaurant's operations must never freeze. Local storage (Hive) acts as the primary data interface. The cloud is a synchronization and reporting layer, not a hard runtime dependency.
* **Deterministic Event Synchronization:** Real-time communications use WebSockets (Socket.IO). When offline, events queue locally and resolve sequentially using versioned records to prevent out-of-order race conditions.
* **Strict Multi-Tenancy:** Complete logical isolation across all compute nodes, cache lines, and database records using a strict tenant indexing mechanism.

---

## 4. Technology Stack Justification

### 4.1 Frontend (Flutter / Android Target)
* **Flutter (v3.x+):** Provides high-performance, hardware-accelerated UI rendering (Impeller engine) at 60fps/120fps on low-end Android devices. Single codebase for eventual web/iOS expansion.
* **Riverpod:** Predictable, compile-safe, and testable state management. Ensures decoupling of business logic from UI widgets.
* **GoRouter:** Declarative, URL-driven routing. Standardizes navigation flows and simplifies role-based view redirection.
* **Dio:** Advanced HTTP client. Features interceptors to handle automatic token refresh, dynamic offline request queuing, and retry mechanisms.
* **Hive:** Light, fast NoSQL key-value/document local database written in pure Dart. Reads/writes take $<3\text{ms}$, outperforming SQLite for high-frequency operations.
* **Socket.IO Client:** Handles real-time bi-directional local and remote event streaming.
* **Firebase Cloud Messaging (FCM):** Out-of-band notifications for configuration updates, system alerts, and remote sync triggers.

### 4.2 Backend (Node.js / Express / TypeScript)
* **TypeScript:** Ensures static analysis, interface safety, and maintainable data contracts between frontend and backend.
* **Node.js & Express:** Lightweight, event-driven, high concurrency capacity. Ideal for handling multiple HTTP and WebSocket connections simultaneously.
* **Prisma ORM:** Type-safe database queries, declarative schema design, and seamless database migration flows.
* **Socket.IO:** Powers real-time KOT updates and cashier notifications across multi-device tenant setups.

### 4.3 Database & Storage
* **PostgreSQL (v15+):** Relational database with robust transaction support, JSONB querying capabilities for semi-structured data, and strict ACID guarantees.
* **Amazon RDS:** Multi-AZ deployment for automated backups, high availability, and horizontal read replica scaling.
* **Amazon S3:** Scalable object storage for menu item photos, company logos, and exported Excel/PDF reports.

### 4.4 Infrastructure & Security
* **Docker:** Containerizes backend services, ensuring parity between local development and production environments.
* **Nginx:** Handles reverse proxying, SSL termination (Let's Encrypt), static asset caching, and request rate limiting.
* **AWS EC2:** Hosts Dockerized backend application instances under an Application Load Balancer.
* **GitHub Actions:** Automates building, linting, testing, and deployment (CI/CD) pipelines.
* **AWS CloudWatch:** Collects system logs, monitors API latency patterns, and alerts on database CPU threshold breaches.

---

## 5. System Architecture & Information Flows

### 5.1 System Architecture Topology
This block diagram illustrates how the Flutter clients interact with the cloud backend, database layers, and the local hardware peripheral system (receipt printers).

```
                      +────────────────────────────────────────────+
                      │             Android Client (Flutter)       │
                      │  ┌──────────────┐        ┌──────────────┐  │
                      │  │  Riverpod VM │◄──────►│  Hive DB     │  │
                      │  └──────┬───────┘        └──────────────┘  │
                      +─────────┼──────────────────────────────────+
                                │ (REST API / Socket.IO)
                                ▼
                      +────────────────────────────────────────────+
                      │            Nginx Reverse Proxy             │
                      │  - SSL Termination                         │
                      │  - Rate Limiting (100 req/min/IP)          │
                      +─────────┬──────────────────────────────────+
                                │ (Reverse Proxy Route)
                                ▼
                      +────────────────────────────────────────────+
                      │       Express API Node.js Cluster          │
                      │  ┌──────────────┐        ┌──────────────┐  │
                      │  │  REST Routes │        │ Socket.IO    │  │
                      │  └──────┬───────┘        └──────┬───────┘  │
                      +─────────┼───────────────────────┼──────────+
                                │                       │
                                │ (Prisma Client)       │
                                ▼                       ▼
                      +───────────────────+   +────────────────────+
                      │   PostgreSQL DB   │   │  Redis Cache/PubSub│
                      │   (Amazon RDS)    │   │  (Socket State)    │
                      +───────────────────+   +────────────────────+
```

### 5.2 Real-time Sync Topology (Local & Remote Network)
To handle real-time sync, clients join a tenant-specific room on the Socket.IO cluster.

```
 Waiter App              KDS (Kitchen Display)         Cashier Terminal
     │                            ▲                            ▲
     │ (Order Created)            │                            │
     ├─► [Socket Event]           │                            │
     │   "kot:new"                │                            │
     │                            │ (Broadcast "kot:new")      │ (Broadcast "kot:new")
     ▼                            ├────────────────────────────┼
[Socket.IO Server] ───────────────┤                            │
  (Redis Room: "tenant_123")      ▼                            ▼
                               [Render Card]               [Update Total]
```

### 5.3 Offline Sync Logic & State Transition
When the device is offline, operations continue without interruption. The local Hive DB queues sync payloads, tracking operations using logical timestamps.

```
                    ┌─────────────────────────┐
                    │ Waiter Submits KOT      │
                    └────────────┬────────────┘
                                 ▼
                    ┌─────────────────────────┐
                    │ Write to Local Hive DB  │
                    │ Status: "PENDING_SYNC"  │
                    └────────────┬────────────┘
                                 ▼
                    ┌─────────────────────────┐
                    │ Append to Sync Queue    │
                    │ (Hive Box: sync_queue)  │
                    └────────────┬────────────┘
                                 ▼
                     Is Network Available?
                     ├── Yes ──► Send Sync Payload ──► Server Commits
                     │                                  Status: "SYNCED"
                     │                                  Clear Queue Item
                     │
                     └── No ───► Register Internet Listener
                                 Keep Status: "PENDING_SYNC"
                                 Wait for connection resume
```

### 5.4 Database Sync and Conflict Resolution Flow
When offline clients reconnect, conflict resolution must prevent data overwrites. We implement a **State-Based Merge with Last-Write-Wins (LWW) resolution** for orders:

```
[Offline Client Sync Initiated]
               │
               ▼
[Validate Order Version on Cloud Database]
               │
      Is Server Version > Client Local Version?
      ├── YES ──► Check Order Status on Server
      │             ├── Status == "SETTLED" (Paid)
      │             │     └── Reject Client Sync, Mark Failed, Fetch Server State.
      │             │
      │             └── Status == "PREPARING" / "SERVED"
      │                   └── Merge Item Quantities (Add Diff), Apply Last-Write-Wins.
      │
      └── NO ───► Commit Client Changes, Increment Version, Broadcast to Room.
```

---

## 6. Multi-Tenant Architecture & Data Isolation

### 6.1 Tenant Isolation Strategy
BhojanOS implements a **Shared Database, Shared Schema, Tenant-Isolated Column** design. Every table containing operational data has a foreign key to the `Tenant` (Restaurant) model.

```
                                  +─────────────────+
                                  │   Tenant (T1)   │
                                  +────────┬────────+
                                           │
                    ┌──────────────────────┴──────────────────────┐
                    ▼                                             ▼
        +───────────────────────+                     +───────────────────────+
        │     MenuItem (T1)     │                     │      Order (T1)       │
        │ - restaurantId: T1    │                     │ - restaurantId: T1    │
        │ - name: "Momo"        │                     │ - total: 250.00       │
        +───────────────────────+                     +───────────────────────+
```

### 6.2 Prisma Query Enforcement Middleware
To enforce data isolation and prevent developers from accidentally querying another tenant's data, we use a Prisma Client extension. This extension dynamically injects `restaurantId` filters into all queries.

```typescript
import { PrismaClient } from '@prisma/client';

export const getTenantPrisma = (restaurantId: string) => {
  const prisma = new PrismaClient();
  
  return prisma.$extends({
    query: {
      $allModels: {
        async $allOperations({ model, operation, args, query }) {
          // Check if model contains restaurantId field
          const modelFields = (prisma as any)._meta?.models[model]?.fields;
          const hasRestaurantId = modelFields?.some((f: any) => f.name === 'restaurantId');

          if (hasRestaurantId) {
            args.where = args.where || {};
            // Force filter to match the validated tenant ID from the request context
            args.where.restaurantId = restaurantId;

            // Prevent tenant reassignment on writes
            if (operation === 'create' || operation === 'createMany') {
              if (Array.isArray(args.data)) {
                args.data.forEach((item: any) => {
                  item.restaurantId = restaurantId;
                });
              } else if (args.data) {
                args.data.restaurantId = restaurantId;
              }
            }
          }
          return query(args);
        },
      },
    },
  });
};
```

### 6.3 Future Scalability: Database Partitioning & Sharding
As the platform scales to handle thousands of active restaurants, database bottlenecks will be addressed via:
1. **PostgreSQL Declarative Partitioning:** Partitioning heavy tables (e.g., `Order`, `OrderItem`, `AuditLog`) by `LIST` using the `restaurantId` value.
2. **Horizontal Database Sharding:** Routing requests to shard-specific database instances based on a tenant lookup table stored in an index database.
3. **Media Isolation:** Upload directory isolation in S3: `/tenants/{restaurantId}/menu/{itemId}.png`. Media assets are protected via signed URLs with short expirations (15 minutes).

---

## 7. User Roles & Access Control Grid

BhojanOS relies on a strict **Role-Based Access Control (RBAC)** strategy. Access privileges are validated both at the Flutter UI level (hiding unauthorized views) and enforced strictly on the Express backend routes.

### 7.1 Access Control Matrix

| Feature Module | Super Admin | Owner | Manager | Cashier | Waiter | Kitchen |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Global SaaS Control** | Yes | No | No | No | No | No |
| **System Settings & Billing** | No | Yes | No | No | No | No |
| **Staff Management (CRUD)** | No | Yes | Yes | No | No | No |
| **Menu Modifications** | No | Yes | Yes | No | No | No |
| **View Financial Reports** | Yes | Yes | Yes | No | No | No |
| **Settle Bills / Cashout** | No | Yes | Yes | Yes | No | No |
| **Apply Custom Discounts** | No | Yes | Yes | No | No | No |
| **Create / Modify Orders** | No | Yes | Yes | Yes | Yes | No |
| **Update KOT Status (KDS)**| No | Yes | Yes | Yes | No | Yes |

### 7.2 Detailed Role Profiles

#### 1. Super Admin
* **Definition:** Platform owners managing the multi-tenant SaaS application infrastructure.
* **Responsibilities:** Onboarding new tenants, handling system-wide maintenance, managing subscription updates, and debugging system errors.

#### 2. Owner
* **Definition:** The restaurant proprietor who pays for the software subscription.
* **Responsibilities:** Full visibility into financial data, pricing configs, billing status, role assignments, and key audits (e.g., deleted orders, manual discount reviews).

#### 3. Manager
* **Definition:** Operates day-to-day business.
* **Responsibilities:** Adjusts daily menu availability, overrides waiter errors (with a secure manager PIN), tracks staff log-ins, and generates shift close-out reports.

#### 4. Cashier
* **Definition:** Stationed at the primary counter terminal.
* **Responsibilities:** Generating customer invoices, printing thermal receipts, accepting cash/Fonepay/card payments, processing refunds, and verifying shift cash drawers.

#### 5. Waiter
* **Definition:** Table-side staff running the mobile client.
* **Responsibilities:** Taking orders, routing KOT updates to the kitchen, processing table change requests, and notifying customers of bill amounts.

#### 6. Kitchen Staff
* **Definition:** Kitchen managers and chefs using tablet displays in preparation areas.
* **Responsibilities:** Managing KOT queue priorities, updating order status to "PREPARING" or "READY", and managing out-of-stock item indicators.

---

## 8. End-to-End Feature Specifications

### 8.1 Authentication & Onboarding
* **Multi-Factor Login:** Initial login via phone number and OTP for verification.
* **Tenant Registration:** Multi-step wizard to setup the restaurant entity, target currency (NPR/USD), taxes, and floor sections.
* **PIN Access:** Fast 4-digit PIN authentication for waiters and cashiers to resume active shifts without entering long passwords.
* **Token Rotation:** Stateless access tokens (15-min life) paired with cryptographically signed, database-tracked refresh tokens.

### 8.2 Restaurant Setup & Profiles
* **Taxes & Surcharges:** Ability to configure standard Nepalese tax models (e.g., 13% VAT, dynamic 10% Service Charge, or zero taxes for tax-exempt operations).
* **Configuration Sync:** All settings are pushed to clients via Socket.IO immediately, forcing cached structures to sync automatically.

### 8.3 Menu Management
* **Hierarchical Structure:** Group items under categories (e.g., "Momo", "Beverages", "Desserts").
* **Modifiers & Add-ons:** Custom group options (e.g., "Momo Type" -> [Steam, Fried, Jhol], "Size" -> [Half, Full]).
* **Tags:** Food types categorized as Vegetarian, Non-Vegetarian, or Vegan.
* **Quick Toggle:** Instant out-of-stock toggles mapped to the KDS, blocking waiters from selecting missing menu items.

### 8.4 Table Management
* **Area Partitioning:** Organize tables by floor sections (e.g., "Ground Floor", "Rooftop Garden", "Bar Area").
* **Visual States:** Real-time state indicator maps:
  * `FREE` (Green)
  * `OCCUPIED` (Red)
  * `BILLING` (Orange - invoice printed, waiting for payment)
  * `DIRTY` (Yellow - awaiting cleanup)
* **Actions:** Seamless drag-and-drop table merges, order migration from one table to another, and splitting customers at a single table into distinct orders.

```
┌────────────────────────────────────────────────────────┐
│                      Floor Map                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ Table 1  │  │ Table 2  │  │ Table 3  │  │ Table 4  │  │
│  │  (Free)  │  │(Occupied)│  │(Billing) │  │ (Dirty)  │  │
│  │  [Green] │  │  [Red]   │  │ [Orange] │  │ [Yellow] │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │
└────────────────────────────────────────────────────────┘
```

### 8.5 Order Management (KOT System)
* **KOT Routing:** Dynamic order assignment to separate preparation stations (e.g., drinks go to "Bar KDS", main courses to "Main Kitchen KDS").
* **Incremental Updates:** Add items to an ongoing table session. The system tracks delta changes to generate new secondary KOTs, rather than duplicate printing.
* **Audit Trail:** Restricts cancellation or quantity reduction of a committed KOT to Manager/Owner PIN authorization.

### 8.6 Kitchen Display System (KDS)
* **Interactive UI:** Large cards representing active tables. Color coding tracks cooking delays:
  * Green: 0-10 minutes.
  * Orange: 10-20 minutes.
  * Red: Over 20 minutes (exceeds SLA).
* **Grid Optimization:** Designed for standard 10-inch Android screens with touch status updates. Supports connecting to Bluetooth KOT printers for kitchens that prefer physical tickets.

### 8.7 Billing & Invoicing
* **Invoice Calculation Engine:** Calculations must execute deterministically on both local clients and the backend.
  $$\text{Subtotal} = \sum (\text{Qty} \times \text{Item Price}) - \text{Discount}$$
  $$\text{Service Charge} = \text{Subtotal} \times 0.10 \quad (\text{if applicable})$$
  $$\text{VAT} = (\text{Subtotal} + \text{Service Charge}) \times 0.13 \quad (\text{if applicable})$$
  $$\text{Grand Total} = \text{Subtotal} + \text{Service Charge} + \text{VAT}$$
* **Local Printing:** Built-in drivers for ESC/POS protocol thermal printers (connected via Bluetooth, USB, or Network IP). Generates clean layouts for both 58mm and 80mm receipt templates.

### 8.8 Offline Sync Engine
* **Hive Cache Box:** Tracks local mutations.
* **Idempotency Strategy:** Every transaction generated offline contains a UUID created at the source client. The API rejects duplicate UUID submissions, preventing network re-tries from creating duplicate orders.
* **Network Monitor:** Employs the `connectivity_plus` plugin to detect connection state changes, initiating a quiet background synchronization loop once connection stability is verified.

### 8.9 Future Enhancements (Phase 2 & 3 Roadmap)
* **Inventory Control:** Recipe cost parsing, stock deduction on sale, supplier purchase tracking, and low-inventory alerts.
* **CRM & Customer Loyalty:** Customer databases linked by phone number, custom discount rules, and digital stamp rewards.
* **QR Table Ordering:** Dynamic customer-facing QR codes at tables that load the restaurant's menu web-app, sending orders directly to the KDS upon cashier validation.
* **Advanced Analytics:** Predictive insights forecasting busiest operational hours, optimal stock levels, and staff efficiency metrics.

---

## 9. Modular Codebase Architecture

The application is structured into decoupled modules, separating responsibilities and ensuring clean testing patterns.

### 9.1 Module Layout

```
                                  +─────────────────+
                                  │   Application   │
                                  +────────┬────────+
                                           │
         ┌───────────────────┬─────────────┼─────────────┬───────────────────┐
         ▼                   ▼             ▼             ▼                   ▼
  ┌─────────────┐     ┌─────────────┐┌─────────────┐┌─────────────┐   ┌─────────────┐
  │ Auth        │     │ Menu        ││ Order       ││ Table       │   │ Sync        │
  │ Credentials │     │ Category    ││ Cart state  ││ Coordinates │   │ Queue,      │
  │ Login PINs  │     │ Modifiers   ││ KOT status  ││ Visual maps │   │ State merge │
  └─────────────┘     └─────────────┘└─────────────┘└─────────────┘   └─────────────┘
```

### 9.2 Module Communication Contracts
* **Direct Function Calls:** Permitted only within the same module scope.
* **Cross-Module Interactions:** Mediated via Riverpod Providers or dedicated Services.
* **Event Notifications:** Distributed via custom event buses or Socket.IO rooms.

---

## 10. Database Schema Design (Prisma)

Here is the declarative schema design modeling our PostgreSQL target.

```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

enum Role {
  SUPER_ADMIN
  OWNER
  MANAGER
  CASHIER
  WAITER
  KITCHEN
}

enum OrderStatus {
  PENDING
  PREPARING
  READY
  SERVED
  SETTLED
  CANCELLED
}

enum PaymentMethod {
  CASH
  FONEPAY
  CARD
  CREDIT
}

model Tenant {
  id          String       @id @default(uuid())
  name        String
  phone       String
  address     String
  panNumber   String?      // Mandatory for Nepalese business compliance
  vatRate     Decimal      @default(13.00) @db.Decimal(5, 2)
  scRate      Decimal      @default(0.00)  @db.Decimal(5, 2) // Service charge percentage
  isActive    Boolean      @default(true)
  createdAt   DateTime     @default(now())
  updatedAt   DateTime     @updatedAt
  users       User[]
  categories  Category[]
  menuItems   MenuItem[]
  tables      Table[]
  orders      Order[]
  bills       Bill[]
  auditLogs   AuditLog[]

  @@map("tenants")
}

model User {
  id           String     @id @default(uuid())
  restaurantId String
  tenant       Tenant     @relation(fields: [restaurantId], references: [id], onDelete: Cascade)
  name         String
  phone        String     @unique
  passwordHash String
  pinHash      String     // 4-digit PIN for waiter/cashier screen resume
  role         Role
  isActive     Boolean    @default(true)
  createdAt    DateTime   @default(now())
  updatedAt    DateTime   @updatedAt
  orders       Order[]    @relation("WaiterOrders")
  bills        Bill[]     @relation("CashierBills")
  auditLogs    AuditLog[]

  @@index([restaurantId])
  @@map("users")
}

model Category {
  id           String     @id @default(uuid())
  restaurantId String
  tenant       Tenant     @relation(fields: [restaurantId], references: [id], onDelete: Cascade)
  name         String
  sortOrder    Int        @default(0)
  isDeleted    Boolean    @default(false)
  createdAt    DateTime   @default(now())
  updatedAt    DateTime   @updatedAt
  menuItems    MenuItem[]

  @@unique([restaurantId, name])
  @@index([restaurantId])
  @@map("categories")
}

model MenuItem {
  id           String             @id @default(uuid())
  restaurantId String
  tenant       Tenant             @relation(fields: [restaurantId], references: [id], onDelete: Cascade)
  categoryId   String
  category     Category           @relation(fields: [categoryId], references: [id])
  name         String
  description  String?
  price        Decimal            @db.Decimal(10, 2)
  isVeg        Boolean            @default(false)
  imageUrl     String?
  isAvailable  Boolean            @default(true)
  isDeleted    Boolean            @default(false)
  createdAt    DateTime           @default(now())
  updatedAt    DateTime           @updatedAt
  orderItems   OrderItem[]
  modifiers    MenuItemModifier[]

  @@index([restaurantId])
  @@index([categoryId])
  @@map("menu_items")
}

model MenuItemModifier {
  id           String   @id @default(uuid())
  menuItemId   String
  menuItem     MenuItem @relation(fields: [menuItemId], references: [id], onDelete: Cascade)
  name         String   // e.g., "Extra Cheese"
  price        Decimal  @db.Decimal(10, 2)
  isAvailable  Boolean  @default(true)
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt

  @@map("menu_item_modifiers")
}

model Table {
  id           String   @id @default(uuid())
  restaurantId String
  tenant       Tenant   @relation(fields: [restaurantId], references: [id], onDelete: Cascade)
  tableNumber  String   // e.g., "1A", "Bar-3"
  capacity     Int
  section      String   // e.g., "Main Floor", "Rooftop"
  status       String   @default("FREE") // FREE, OCCUPIED, BILLING, DIRTY
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt
  orders       Order[]

  @@unique([restaurantId, tableNumber])
  @@index([restaurantId])
  @@map("tables")
}

model Order {
  id           String      @id @default(uuid()) // UUID generated client-side for sync tracking
  restaurantId String
  tenant       Tenant      @relation(fields: [restaurantId], references: [id], onDelete: Cascade)
  tableId      String
  table        Table       @relation(fields: [tableId], references: [id])
  waiterId     String
  waiter       User        @relation("WaiterOrders", fields: [waiterId], references: [id])
  status       OrderStatus @default(PENDING)
  notes        String?
  subtotal     Decimal     @db.Decimal(10, 2)
  version      Int         @default(1) // For sync concurrency conflict checks
  createdAt    DateTime    @default(now())
  updatedAt    DateTime    @updatedAt
  orderItems   OrderItem[]
  bills        Bill[]

  @@index([restaurantId])
  @@index([tableId])
  @@index([waiterId])
  @@map("orders")
}

model OrderItem {
  id         String   @id @default(uuid())
  orderId    String
  order      Order    @relation(fields: [orderId], references: [id], onDelete: Cascade)
  menuItemId String
  menuItem   MenuItem @relation(fields: [menuItemId], references: [id])
  quantity   Int
  unitPrice  Decimal  @db.Decimal(10, 2)
  notes      String?  // Custom customer notes (e.g., "No onions")
  createdAt  DateTime @default(now())
  updatedAt  DateTime @updatedAt

  @@index([orderId])
  @@map("order_items")
}

model Bill {
  id             String        @id @default(uuid())
  restaurantId   String
  tenant         Tenant        @relation(fields: [restaurantId], references: [id], onDelete: Cascade)
  orderId        String
  order          Order         @relation(fields: [orderId], references: [id])
  cashierId      String
  cashier        User          @relation("CashierBills", fields: [cashierId], references: [id])
  billNumber     String        // Sequentially generated per-tenant string (e.g., "INV-2026-0001")
  subtotal       Decimal       @db.Decimal(10, 2)
  discountAmount Decimal       @default(0.00) @db.Decimal(10, 2)
  serviceCharge  Decimal       @db.Decimal(10, 2)
  vatAmount      Decimal       @db.Decimal(10, 2)
  grandTotal     Decimal       @db.Decimal(10, 2)
  paymentMethod  PaymentMethod
  paymentStatus  String        @default("PAID") // PAID, REFUNDED
  createdAt      DateTime      @default(now())
  updatedAt      DateTime      @updatedAt

  @@unique([restaurantId, billNumber])
  @@index([restaurantId])
  @@index([orderId])
  @@map("bills")
}

model AuditLog {
  id           String   @id @default(uuid())
  restaurantId String
  tenant       Tenant   @relation(fields: [restaurantId], references: [id], onDelete: Cascade)
  userId       String
  user         User     @relation(fields: [userId], references: [id])
  action       String   // e.g., "CANCEL_ORDER", "DELETE_MENU_ITEM", "APPLY_DISCOUNT"
  entityName   String   // e.g., "Order", "MenuItem"
  entityId     String
  oldValues    Json?
  newValues    Json?
  ipAddress    String?
  createdAt    DateTime @default(now())

  @@index([restaurantId])
  @@index([userId])
  @@map("audit_logs")
}
```

---

## 11. API Design & Real-Time Events Contract

All REST APIs run under `/api/v1/` prefix. Payloads are JSON format. Content-Type headers must be `application/json`.

### 11.1 Standard Headers
* `Authorization: Bearer <JWT_ACCESS_TOKEN>`
* `X-Restaurant-Id: <TENANT_UUID>`

### 11.2 Standard Envelope Response
```json
{
  "success": true,
  "data": {},
  "error": null,
  "timestamp": "2026-07-04T10:45:15Z"
}
```

### 11.3 Main REST Endpoints

| Method | Path | Payload / Query | Auth | Description |
| :--- | :--- | :--- | :---: | :--- |
| **POST** | `/auth/login` | `{ "phone": "9800000000", "password": "..." }` | No | Full login, returns JWT and user profile. |
| **POST** | `/auth/refresh`| `{ "refreshToken": "..." }` | No | Issues new access token using rotation model. |
| **POST** | `/auth/pin-verify`| `{ "pin": "1234" }` | Yes | Local verification of user PIN for shift resume. |
| **GET** | `/menu/items` | None | Yes | Fetches all active menu items for the tenant. |
| **POST** | `/menu/items` | `{ "name": "...", "price": 250, ...}`| Yes | Adds new menu item (Manager/Owner only). |
| **GET** | `/tables` | None | Yes | Fetches active table grid and operational states. |
| **POST** | `/orders` | `{ "id": "uuid", "tableId": "...", "items": [...] }`| Yes | Creates new order. Supports offline sync execution. |
| **PATCH**| `/orders/:id/status`| `{ "status": "PREPARING" }` | Yes | Modifies active order state. Broadcats to KDS. |
| **POST** | `/orders/sync` | `[{ "id": "uuid", "items": [...] }]` | Yes | Bulk payload upload for cached offline operations. |
| **POST** | `/billing/invoice`| `{ "orderId": "...", "discount": 10, "method": "CASH" }`| Yes | Finalizes calculation, closes order, commits bill. |

---

### 11.4 Real-Time WebSockets Event Interface (Socket.IO)

#### 1. Connection Event
* **Event:** `join:room`
* **Direction:** Client -> Server
* **Payload:**
  ```json
  {
    "restaurantId": "d7e9b068-12cd-48c0-bc66-3d7fe7b2b0ef",
    "token": "JWT_ACCESS_TOKEN"
  }
  ```

#### 2. KOT Creation Event
* **Event:** `kot:new`
* **Direction:** Client -> Server -> Room Broadcast
* **Broadcast Room:** `restaurant_<restaurantId>`
* **Payload:**
  ```json
  {
    "orderId": "e30c451e-e28a-4933-bfba-8c467a552bfd",
    "tableNumber": "T-14",
    "waiterName": "Ram Prasad",
    "createdAt": "2026-07-04T10:48:00Z",
    "items": [
      {
        "name": "Chicken Momo",
        "quantity": 2,
        "notes": "Spicy, soup separate"
      },
      {
        "name": "Iced Americano",
        "quantity": 1,
        "notes": "No sugar"
      }
    ]
  }
  ```

#### 3. KOT Status Transition Event
* **Event:** `kot:status-update`
* **Direction:** Client -> Server -> Room Broadcast
* **Payload:**
  ```json
  {
    "orderId": "e30c451e-e28a-4933-bfba-8c467a552bfd",
    "status": "PREPARING",
    "estimatedTimeMinutes": 15
  }
  ```

---

## 12. Security Architecture & Controls

```
                         ┌───────────────────────┐
                         │   Client HTTPS Call   │
                         └───────────┬───────────┘
                                     ▼
                         ┌───────────────────────┐
                         │  Nginx Rate Limiting  │
                         └───────────┬───────────┘
                                     ▼
                         ┌───────────────────────┐
                         │ JWT Validation Filter │
                         └───────────┬───────────┘
                                     ▼
                      ┌─────────────────────────────┐
                      │ Context RBAC Match Check    │
                      │ (Does Role allow Access?)  │
                      └─────────────┬───────────────┘
                                    ▼
                      ┌─────────────────────────────┐
                      │ Data Schema Filter Match    │
                      │ (Matches Tenant Context?)   │
                      └─────────────┬───────────────┘
                                    ▼
                         ┌───────────────────────┐
                         │ Execute Query on DB   │
                         └───────────────────────┘
```

* **JSON Web Tokens (JWT):** Encoded with `userId`, `role`, and `restaurantId`. Digitally signed using `RS256` private keys.
* **PIN Code Hashing:** Waiter PIN codes are hashed using `argon2id` before being saved to the database. They are never sent or stored in plaintext.
* **Refresh Token Rotation:** Refresh tokens are single-use. If a reuse event is detected, the token family is revoked to mitigate token-theft risks.
* **Rate Limiting:** Web requests are restricted via Nginx rules to 100 queries per minute per client IP. Critical auth routes (e.g., `/auth/login`) are capped at 5 requests per minute.
* **Environment Variables Management:** Application secrets (private keys, database credentials) are stored securely using AWS Secrets Manager.

---

## 13. System Folder Directory Structures

### 13.1 Frontend App Folder Layout (Flutter Clean Feature-First)

```
bhojan_os_client/
├── android/                  # Native Android configuration
├── assets/                   # Fonts, icons, images, and static assets
├── lib/
│   ├── main.dart             # App initialization point
│   ├── app.dart              # Global widgets & routing config
│   ├── core/                 # Shared features and utilities
│   │   ├── theme/            # Material 3 design system, colors, fonts
│   │   ├── network/          # Dio client, Interceptors, API endpoints
│   │   ├── database/         # Hive initializers, global box types
│   │   ├── utils/            # Shared string/number formatting utilities
│   │   └── widgets/          # Reusable UI components (buttons, text fields)
│   ├── features/             # Business modules (feature-first structure)
│   │   ├── auth/
│   │   │   ├── data/         # Repositories & Hive caching adapters
│   │   │   ├── domain/       # Logical entity definitions
│   │   │   └── presentation/ # UI screens, controllers & Riverpod providers
│   │   ├── menu/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── order/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── table/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   └── sync/
│   │       ├── data/         # SyncQueue storage database
│   │       ├── domain/       # Logical sync routines, reconciliation state machine
│   │       └── presentation/ # Sync progress indicators, network connection banners
│   └── observers/            # State logging, analytics observers
└── pubspec.yaml              # Dart dependencies configuration
```

### 13.2 Backend Server Folder Layout (Express Layered Architecture)

```
bhojan_os_server/
├── prisma/
│   ├── schema.prisma         # Prisma database schema definition
│   └── migrations/           # Database migration log files
├── src/
│   ├── app.ts                # Application setup
│   ├── server.ts             # Server entrypoint & WebSocket setup
│   ├── config/               # Database, JWT, AWS client configurations
│   ├── core/                 # Shared logic, exceptions, logger config
│   ├── middlewares/          # JWT checks, RBAC verification, validation
│   ├── modules/              # Module-first folders
│   │   ├── auth/
│   │   │   ├── auth.controller.ts
│   │   │   ├── auth.service.ts
│   │   │   └── auth.validator.ts
│   │   ├── menu/
│   │   │   ├── menu.controller.ts
│   │   │   ├── menu.service.ts
│   │   │   └── menu.validator.ts
│   │   ├── order/
│   │   │   ├── order.controller.ts
│   │   │   ├── order.service.ts
│   │   │   └── order.validator.ts
│   │   └── sync/
│   │       ├── sync.controller.ts
│   │       └── sync.service.ts
│   └── types/                # Express request type overrides
├── tsconfig.json             # TypeScript compiler options
├── package.json              # Dependency manifests
└── Dockerfile                # Release image instructions
```

### 13.3 Infrastructure Folder Layout

```
bhojan_os_infra/
├── docker/
│   ├── docker-compose.yml    # Local development setup (Postgres, Redis)
│   └── nginx.conf            # Reverse proxy setup & rate limit rules
├── terraform/
│   ├── rds.tf                # PostgreSQL RDS configuration
│   ├── ec2.tf                # Server hosting setup
│   └── variables.tf          # Environment variables mapping
└── .github/
    └── workflows/
        └── deploy.yml        # CI/CD instructions
```

---

## 14. Development Guidelines & Lint Rules

To keep code readable and uniform across contributors, engineers must follow these standards.

### 14.1 Code Quality Configs

#### Dart (Flutter) Analyzer Configuration (`analysis_options.yaml`)
```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true

linter:
  rules:
    - prefer_const_constructors
    - avoid_print
    - always_declare_return_types
    - cancel_subscriptions
    - close_sinks
```

#### TypeScript ESLint Rule Configs (`.eslintrc.json`)
```json
{
  "parser": "@typescript-eslint/parser",
  "plugins": ["@typescript-eslint"],
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended"
  ],
  "rules": {
    "no-console": "warn",
    "@typescript-eslint/explicit-function-return-type": "error",
    "@typescript-eslint/no-unused-vars": ["error", { "argsIgnorePattern": "^_" }],
    "quotes": ["error", "single"]
  }
}
```

### 14.2 Version Control & Commit Messages
* **Branch Pattern:** GitFlow ruleset:
  * `main` (Production release branch)
  * `develop` (Integration branch)
  * `feature/*` (Feature development)
  * `hotfix/*` (Urgent production repairs)
* **Commit Messages:** Follow [Conventional Commits](https://www.conventionalcommits.org/):
  * `feat: added table merging UI layout`
  * `fix: resolved print offset margin on 58mm printer`
  * `docs: updated API schema endpoints table`
  * `refactor: extracted order calculator service logic`

---

## 15. UI/UX Style Guidelines

* **Touch Target Sizes:** Interactive touch elements must be at least $48\text{dp} \times 48\text{dp}$, target $64\text{dp} \times 64\text{dp}$ for fast-paced areas (e.g., cart quantity increment buttons).
* **Color System:** Material 3 engine. High contrast ratios to maintain readability under bright outdoor terrace lighting or low-light indoor cafe environments.
* **Color Palette:**
  * **Brand Primary:** Warm Crimson Red (`#C8102E`) - stimulates appetite, high contrast.
  * **Brand Secondary:** Himalayan Slate Blue (`#003893`) - clean, structural.
  * **Backgrounds:** Off-white (`#F8F9FA`) for clean daylight usage; Dark Charcoal (`#121212`) for battery-saving dark themes.
* **Sound & Haptics:** Subtle haptic ticks on tap events. Clear, distinct alerts sound for new KOT arrivals on KDS tablets.

---

## 16. Non-Functional Requirements (NFR) & SLA Thresholds

* **Performance Response Times:**
  * API latency profiles under ordinary loads must remain $<200\text{ms}$ at p95.
  * Local Hive read operations must perform in $<3\text{ms}$.
  * UI render loop must maintain $60\text{fps}$ min on basic Android budget phones.
* **System High Availability:** Server SLA targets a minimum uptime of $99.9\%$, managed using AWS Auto Scaling clusters across multi-AZ zones.
* **Data Recovery RPO & RTO:**
  * **Recovery Point Objective (RPO):** Maximum 1 hour of potential database loss (hourly automated WAL archiving to S3).
  * **Recovery Time Objective (RTO):** Standard failover recovery inside 10 minutes.
* **Local Offline Queue Capacity:** Support caching up to $10,000$ operations on active local device databases without causing performance degradation.

---

## 17. Multi-Phase Roadmap

```
  Phase 1: MVP Core               Phase 2: Growth                 Phase 3: Scale
 ┌──────────────────────┐        ┌──────────────────────┐        ┌──────────────────────┐
 │ - Local & Cloud POS  │        │ - Inventory Tracking │        │ - QR Table Ordering  │
 │ - Multi-tenant DB    │ ──────►│ - Supplier Management│ ──────►│ - Customer Loyalty   │
 │ - Printer Engine     │        │ - Shift Management   │        │ - Multi-branch Sync  │
 │ - KDS Interfaces     │        │ - Detailed Reports   │        │ - Analytics Engine   │
 └──────────────────────┘        └──────────────────────┘        └──────────────────────┘
```

### 17.1 Phase 1: Minimum Viable Product (MVP)
* Full local order processing offline.
* Multi-tenant structure support on PostgreSQL DB.
* Basic floor plans and table status managers.
* Local thermal print setups.
* Basic sales data reports.

### 17.2 Phase 2: Growth & Operational Controls
* Automated inventory ledger.
* Shift management controls (tracking drawer entry, cashouts, discrepancies).
* Multi-outlet synchronization under a single tenant.
* Customer profile CRM integrations.

### 17.3 Phase 3: Scaling & Platform Expansion
* Customer self-serve QR code dining portal.
* Predictive machine learning analyzing future stock requirements.
* Automatic API connections to third-party delivery platforms.

---

## 18. Out-of-Scope (MVP Exclusions)

The following components will not be built during the initial development sprint:
* **Multi-Branch Inventory Transfers:** Moving stock directly between distinct restaurant branch locations.
* **Customer Self-Checkout:** Card transactions handled directly by customers at the table (QR table ordering is read-only during Phase 1/2).
* **Multi-Currency Settlement:** Conversion calculations across international cash systems (MVP runs exclusively in NPR).
* **Automated Vendor Purchasing:** Placing orders with suppliers automatically when stock drops below threshold levels.
# Bhojan
