import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../table/presentation/table_management_screen.dart';
import '../../kitchen/presentation/kitchen_display_screen.dart';
import '../../billing/presentation/billing_terminal_screen.dart';
import '../../shift/presentation/shift_management_screen.dart';
import '../../auth/presentation/staff_management_screen.dart';
import '../../settings/presentation/restaurant_settings_screen.dart';
import '../../reports/presentation/sales_reports_screen.dart';
import '../../menu/presentation/menu_management_screen.dart';
import '../../sync/domain/sync_service.dart';
import '../../shift/presentation/shift_notifier.dart';
import '../../table/presentation/table_notifier.dart';
import '../../menu/presentation/menu_notifier.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final staffName = user?.name ?? 'Staff Name';
    final staffRole = user?.role ?? 'Staff Role';
    final restName = user?.restaurantName ?? 'Kathmandu Cafe & Diner';
    final isOwner = staffRole == 'OWNER';
    final isManager = staffRole == 'MANAGER';
    final isCashier = staffRole == 'CASHIER';
    final isWaiter = staffRole == 'WAITER';
    final isKitchen = staffRole == 'KITCHEN';

    final screenWidth = MediaQuery.of(context).size.width;
    final columns = screenWidth < 600 ? 2 : (screenWidth < 950 ? 3 : 4);
    final double ratio = screenWidth < 600 ? 1.30 : (screenWidth < 950 ? 1.40 : 1.50);

    final List<Widget> moduleCards = [];

    // 1. Table Management (Owner, Manager, Cashier, Waiter)
    if (isOwner || isManager || isCashier || isWaiter) {
      moduleCards.add(
        _buildModuleCard(
          icon: Icons.table_restaurant_outlined,
          title: isCashier ? 'Tables Ready to Pay' : 'Table Management',
          desc: isCashier ? 'Tables requesting bill & checkouts.' : 'Take orders, check floor status maps.',
          color: const Color(0xFF003893),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TableManagementScreen()),
            );
          },
        ),
      );
    }

    // 2. Kitchen Display / Queue (Owner, Manager, Waiter, Kitchen)
    if (isOwner || isManager || isWaiter || isKitchen) {
      moduleCards.add(
        _buildModuleCard(
          icon: Icons.kitchen_outlined,
          title: isKitchen ? 'Kitchen Queue' : 'Order Status (Kitchen)',
          desc: isKitchen ? 'Incoming orders, prepare & complete tickets.' : 'Track active tables food preparation status.',
          color: const Color(0xFF2E7D32),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const KitchenDisplayScreen()),
            );
          },
        ),
      );
    }

    // 3. Menu & Stock (All roles)
    moduleCards.add(
      _buildModuleCard(
        icon: Icons.inventory_2_outlined,
        title: 'Menu & Stock',
        desc: (isOwner || isManager || isKitchen)
            ? 'Browse menu and manage item stock availability.'
            : 'Check real-time menu item stock levels.',
        color: const Color(0xFFE65100),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MenuManagementScreen()),
          );
        },
      ),
    );

    // 4. Billing & Invoices (Owner, Manager, Cashier)
    if (isOwner || isManager || isCashier) {
      moduleCards.add(
        _buildModuleCard(
          icon: Icons.receipt_long_outlined,
          title: 'Billing & Invoices',
          desc: 'Print receipts, check Fonepay/Cash splits.',
          color: const Color(0xFFD84315),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BillingTerminalScreen()),
            );
          },
        ),
      );
    }

    // 5. Shift & Cash Drawer (Owner, Manager, Cashier)
    if (isOwner || isManager || isCashier) {
      moduleCards.add(
        _buildModuleCard(
          icon: Icons.wallet_outlined,
          title: 'Shift & Cash Drawer',
          desc: 'Manage drawer opening/closing audits.',
          color: const Color(0xFF8E24AA),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ShiftManagementScreen()),
            );
          },
        ),
      );
    }

    // 6. Staff Management (Owner, Manager)
    if (isOwner || isManager) {
      moduleCards.add(
        _buildModuleCard(
          icon: Icons.people_outline,
          title: 'Staff Management',
          desc: 'Manage roles, active credentials & PINs.',
          color: const Color(0xFF00ACC1),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StaffManagementScreen()),
            );
          },
        ),
      );
    }

    // 7. Restaurant Settings (Owner ONLY!)
    if (isOwner) {
      moduleCards.add(
        _buildModuleCard(
          icon: Icons.settings_outlined,
          title: 'Restaurant Settings',
          desc: 'Configure taxes, profiles & printers.',
          color: const Color(0xFFD81B60),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RestaurantSettingsScreen()),
            );
          },
        ),
      );
    }

    // 8. Sales & Reports (Owner, Manager)
    if (isOwner || isManager) {
      moduleCards.add(
        _buildModuleCard(
          icon: Icons.analytics_outlined,
          title: 'Sales & Reports',
          desc: 'Review sales ledger and statistics charts.',
          color: const Color(0xFF5E35B1),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SalesReportsScreen()),
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              restName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003893),
              ),
            ),
            const Text(
              'BhojanOS Operational Console',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => ref.read(authProvider.notifier).lockSession(),
            icon: const Icon(Icons.lock_outline, color: Color(0xFF64748B)),
            tooltip: 'Lock Terminal Screen',
          ),
          IconButton(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout_outlined, color: Color(0xFFC8102E)),
            tooltip: 'Log out',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              ref.read(tableProvider.notifier).fetchTables(),
              ref.read(shiftProvider.notifier).fetchActiveShift(),
              ref.read(menuProvider.notifier).fetchMenu(),
            ]);
          },
          color: const Color(0xFF003893),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome Banner
                _buildWelcomeBanner(staffName, staffRole),
                const SizedBox(height: 18),
                
                // Status Indicator Row (Shift, Sync, Printer)
                _buildStatusHeader(context, ref),
                const SizedBox(height: 28),

                // Real-time Action Center / Alerts
                _buildNotificationCenter(staffRole, context, ref),

                // Owner Real-time Insights (Only for admin roles)
                if (isOwner || isManager) ...[
                  const Text(
                    'Real-Time Insights',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildInsightsGrid(screenWidth),
                  const SizedBox(height: 28),
                ],

                const Text(
                  'Operational Modules',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: ratio,
                  ),
                  itemCount: moduleCards.length,
                  itemBuilder: (context, index) => moduleCards[index],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(String staffName, String staffRole) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF003893)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003893).withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            child: const Icon(
              Icons.person_outline_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Namaste, $staffName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Role: $staffRole',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context, WidgetRef ref) {
    // 1. Shift state
    final shiftState = ref.watch(shiftProvider);
    final isShiftOpen = shiftState.activeShift != null;
    
    // 2. Sync Queue length
    final syncState = ref.watch(syncServiceProvider);
    final pendingSyncCount = syncState.queueLength;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // Shift Badge
        _buildStatusBadge(
          icon: Icons.wallet_outlined,
          label: isShiftOpen ? 'Shift Active' : 'Shift Drawer Closed',
          color: isShiftOpen ? const Color(0xFF2E7D32) : const Color(0xFFC8102E),
        ),
        // Sync Badge
        _buildStatusBadge(
          icon: pendingSyncCount > 0 ? Icons.sync_rounded : Icons.cloud_done_outlined,
          label: pendingSyncCount > 0 ? 'Syncing ($pendingSyncCount pending)' : 'Cloud Synced',
          color: pendingSyncCount > 0 ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
        ),
        // Printer Badge
        _buildStatusBadge(
          icon: Icons.print_outlined,
          label: 'Printer: Ready',
          color: const Color(0xFF2E7D32),
        ),
      ],
    );
  }

  Widget _buildStatusBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsGrid(double screenWidth) {
    final columnsCount = screenWidth < 600 ? 1 : 3;
    final cards = [
      _buildInsightCard(
        title: "Today's Gross Sales",
        value: 'Rs. 24,580.00',
        subtitle: '+12% from yesterday',
        color: const Color(0xFF003893),
        icon: Icons.trending_up_rounded,
      ),
      _buildInsightCard(
        title: 'Active KOT Orders',
        value: '6 Kitchen Tickets',
        subtitle: 'Avg prep time: 14m',
        color: const Color(0xFF2E7D32),
        icon: Icons.soup_kitchen_rounded,
      ),
      _buildInsightCard(
        title: 'Table Occupancy',
        value: '8 / 15 Tables',
        subtitle: '53% capacity active',
        color: const Color(0xFFE65100),
        icon: Icons.table_bar_rounded,
      ),
    ];

    if (columnsCount == 1) {
      return Column(
        children: cards.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: c,
        )).toList(),
      );
    }

    return Row(
      children: cards.map((c) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: c,
        ),
      )).toList(),
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCenter(String role, BuildContext context, WidgetRef ref) {
    final List<Map<String, dynamic>> alerts = [];

    final isOwner = role == 'OWNER';
    final isManager = role == 'MANAGER';
    final isCashier = role == 'CASHIER';
    final isWaiter = role == 'WAITER';
    final isKitchen = role == 'KITCHEN';

    if (isWaiter) {
      alerts.addAll([
        {
          'title': 'Kitchen Order Ready',
          'desc': 'Order #142 (Table 4) is ready to serve.',
          'icon': Icons.flatware_rounded,
          'color': const Color(0xFF2E7D32),
          'time': 'Just now',
        },
        {
          'title': 'Item Out of Stock',
          'desc': 'Chicken Momo is now out of stock.',
          'icon': Icons.warning_amber_rounded,
          'color': const Color(0xFFE65100),
          'time': '10m ago',
        },
      ]);
    }

    if (isCashier || isOwner || isManager) {
      alerts.add({
        'title': 'Bill Requested',
        'desc': 'Table 6 requested their bill. NPR 2,450 pending.',
        'icon': Icons.receipt_long_rounded,
        'color': const Color(0xFFE65100),
        'time': '2m ago',
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BillingTerminalScreen()),
          );
        }
      });
    }

    if (isKitchen) {
      alerts.add({
        'title': 'New Incoming Order',
        'desc': 'Table 3 sent a new order ticket.',
        'icon': Icons.library_add_rounded,
        'color': const Color(0xFF003893),
        'time': 'Just now',
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const KitchenDisplayScreen()),
          );
        }
      });
    }

    if (isOwner || isManager) {
      alerts.addAll([
        {
          'title': 'Shift Ending Warning',
          'desc': 'Morning shift ends in 10 minutes.',
          'icon': Icons.timer_outlined,
          'color': const Color(0xFF8E24AA),
          'time': '5m ago',
        },
        {
          'title': 'Printer Disconnected',
          'desc': 'Kitchen Printer is disconnected.',
          'icon': Icons.print_disabled_outlined,
          'color': const Color(0xFFC8102E),
          'time': '12m ago',
        },
      ]);
    }

    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.notifications_active_outlined, color: Color(0xFFC8102E), size: 18),
            SizedBox(width: 8),
            Text(
              'Action Center & Alerts',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 95,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: alert['color'].withValues(alpha: 0.25), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: alert['color'].withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(alert['icon'], color: alert['color'], size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  alert['title'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                alert['time'],
                                style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            alert['desc'],
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (alert['action'] != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(Icons.arrow_circle_right_outlined, color: alert['color'], size: 20),
                        onPressed: alert['action'],
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Take Action',
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

