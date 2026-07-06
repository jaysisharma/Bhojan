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
import '../../order/presentation/order_notifier.dart';
import '../../order/presentation/order_intake_screen.dart';
import '../../reports/presentation/reports_notifier.dart';
import '../../table/domain/table_model.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final tables = ref.watch(tableProvider);
    final orderState = ref.watch(orderProvider);
    final reportsState = ref.watch(reportsProvider);
    final billingTables = tables
        .where((t) => t.status == 'OCCUPIED' || t.status == 'BILLING')
        .toList();

    // Today's Gross Sales
    String salesValue = 'Rs. 0.00';
    String salesSubtitle = 'Sales this shift';
    if (reportsState.isLoading) {
      salesValue = 'Loading...';
    } else if (reportsState.report != null) {
      salesValue = 'Rs. ${reportsState.report!.totalSales.toStringAsFixed(2)}';
      salesSubtitle =
          'Avg: Rs. ${reportsState.report!.avgOrderValue.toStringAsFixed(0)} / order';
    } else if (reportsState.errorMessage != null) {
      salesValue = 'Error';
    }

    // Active KOT Orders
    final activeKOTCount = orderState.activeOrders.values
        .where((o) =>
            o.status == 'PENDING' ||
            o.status == 'PREPARING' ||
            o.status == 'READY')
        .length;
    final activeKOTValue =
        '$activeKOTCount Kitchen Ticket${activeKOTCount == 1 ? "" : "s"}';

    // Table Occupancy
    final occupiedTables = tables
        .where((t) => t.status == 'OCCUPIED' || t.status == 'BILLING')
        .length;
    final totalTables = tables.length;
    final occupancyValue =
        '$occupiedTables / $totalTables Table${totalTables == 1 ? "" : "s"}';
    final double occupancyPercentage =
        totalTables == 0 ? 0.0 : (occupiedTables / totalTables) * 100;
    final occupancySubtitle =
        '${occupancyPercentage.toStringAsFixed(0)}% capacity active';

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
    final bool isWide = screenWidth > 900;
    final double ratio =
        screenWidth < 600 ? 1.30 : (screenWidth < 950 ? 1.40 : 1.50);

    Widget _buildModuleCard({
      required IconData icon,
      required String title,
      required String desc,
      required Color color,
      required VoidCallback onTap,
    }) {
      final isMobile = screenWidth < 600;
      if (isMobile) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          desc,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
        );
      }

      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.015),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
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

    final List<Widget> moduleCards = [];

    // Operations Category (Index 0)
    if (_selectedTabIndex == 0) {
      if (isOwner || isManager || isCashier || isWaiter) {
        moduleCards.add(
          _buildModuleCard(
            icon: Icons.table_restaurant_outlined,
            title: isCashier ? 'Tables Ready to Pay' : 'Table Management',
            desc: isCashier
                ? 'Tables requesting bill & checkouts.'
                : 'Take orders, check floor status maps.',
            color: const Color(0xFF003893),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const TableManagementScreen()),
              );
            },
          ),
        );
      }

      if (isOwner || isManager || isWaiter || isKitchen) {
        moduleCards.add(
          _buildModuleCard(
            icon: Icons.kitchen_outlined,
            title: isKitchen ? 'Kitchen Queue' : 'Order Status (Kitchen)',
            desc: isKitchen
                ? 'Incoming orders, prepare & complete tickets.'
                : 'Track active tables food preparation status.',
            color: const Color(0xFF2E7D32),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const KitchenDisplayScreen()),
              );
            },
          ),
        );
      }

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
              MaterialPageRoute(
                  builder: (context) => const MenuManagementScreen()),
            );
          },
        ),
      );
    }

    // Finance & Sales Category (Index 1)
    if (_selectedTabIndex == 1) {
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
                MaterialPageRoute(
                    builder: (context) => const BillingTerminalScreen()),
              );
            },
          ),
        );
      }

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
                MaterialPageRoute(
                    builder: (context) => const ShiftManagementScreen()),
              );
            },
          ),
        );
      }

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
                MaterialPageRoute(
                    builder: (context) => const SalesReportsScreen()),
              );
            },
          ),
        );
      }
    }

    // Management & Settings Category (Index 2)
    if (_selectedTabIndex == 2) {
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
                MaterialPageRoute(
                    builder: (context) => const StaffManagementScreen()),
              );
            },
          ),
        );
      }

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
                MaterialPageRoute(
                    builder: (context) => const RestaurantSettingsScreen()),
              );
            },
          ),
        );
      }
    }

    if (moduleCards.isEmpty) {
      moduleCards.add(
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 36.0),
            child: Text(
              'No modules available for your role under this tab.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ),
        ),
      );
    }

    Widget _buildTabSelector() {
      final tabStyles = [
        {'title': 'Operations', 'icon': Icons.bolt_rounded},
        {'title': 'Finance', 'icon': Icons.account_balance_wallet_rounded},
        {'title': 'Management', 'icon': Icons.admin_panel_settings_rounded},
      ];

      return Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
        child: Row(
          children: List.generate(tabStyles.length, (index) {
            final isSelected = _selectedTabIndex == index;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTabIndex = index;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected
                            ? const Color(0xFF003893)
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tabStyles[index]['icon'] as IconData,
                        size: 15,
                        color: isSelected
                            ? const Color(0xFF003893)
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tabStyles[index]['title'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF003893)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      );
    }

    // Main layout contents
    Widget _buildLeftPanel() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome Banner
          _buildWelcomeBanner(staffName, staffRole),
          const SizedBox(height: 18),

          // Status Badges (Mobile displays these at top, Desktop/Tablet keeps them clean)
          if (!isWide) ...[
            _buildStatusHeader(context),
            const SizedBox(height: 24),
          ],

          // Real-time Insights (Gross Sales, Active Orders, Table Occupancy)
          if (isOwner || isManager) ...[
            const Text(
              'Real-Time Insights',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            _buildInsightsGrid(
              screenWidth: screenWidth,
              salesValue: salesValue,
              salesSubtitle: salesSubtitle,
              activeKOTValue: activeKOTValue,
              occupancyValue: occupancyValue,
              occupancySubtitle: occupancySubtitle,
            ),
            const SizedBox(height: 24),
          ],

          // Waiter active orders horizontal slider
          if (isWaiter && billingTables.isNotEmpty) ...[
            const Text(
              'My Active Tables',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: billingTables.length,
                itemBuilder: (context, index) {
                  final table = billingTables[index];
                  final tableOrder = orderState.activeOrders[table.id];
                  final isBilling = table.status == 'BILLING';
                  final accentColor = isBilling
                      ? const Color(0xFFE65100)
                      : const Color(0xFF003893);
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () {
                        ref.read(orderProvider.notifier).selectTable(table.id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const OrderIntakeScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          children: [
                            Container(
                              width: 5,
                              color: accentColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Table ${table.tableNumber}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: accentColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tableOrder != null
                                        ? 'Rs. ${tableOrder.subtotal.toStringAsFixed(0)}'
                                        : 'No order',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                size: 16, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Operational Modules with Tab Selector
          const Text(
            'Operational Modules',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          _buildTabSelector(),
          const SizedBox(height: 16),
          screenWidth < 600 || _selectedTabIndex == 2
              ? Column(
                  children: moduleCards,
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 3 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: ratio,
                  ),
                  itemCount: moduleCards.length,
                  itemBuilder: (context, index) => moduleCards[index],
                ),
          if (!isWide) ...[
            const SizedBox(height: 24),
            _buildMiniTableMap(tables),
            const SizedBox(height: 24),
            _buildVerticalNotificationFeed(staffRole),
          ],
        ],
      );
    }

    Widget _buildRightPanel() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live Station Drawer badges
          _buildStatusHeader(context),
          const SizedBox(height: 24),

          // Live Table Grid map
          _buildMiniTableMap(tables),
          const SizedBox(height: 24),

          // Live operations Alerts Feed
          _buildVerticalNotificationFeed(staffRole),
        ],
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
              ref.read(orderProvider.notifier).fetchActiveOrders(),
              ref.read(reportsProvider.notifier).fetchDashboardReport(),
            ]);
          },
          color: const Color(0xFF003893),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildLeftPanel(),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 4,
                        child: _buildRightPanel(),
                      ),
                    ],
                  )
                : _buildLeftPanel(),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(String staffName, String staffRole) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE2E8F0),
            child: const Icon(
              Icons.person_outline_rounded,
              color: Color(0xFF0F172A),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Namaste, $staffName',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  staffRole,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context) {
    final shiftState = ref.watch(shiftProvider);
    final isShiftOpen = shiftState.activeShift != null;

    final syncState = ref.watch(syncServiceProvider);
    final pendingSyncCount = syncState.queueLength;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildStatusBadge(
          icon: Icons.wallet_outlined,
          label: isShiftOpen ? 'Shift Active' : 'Drawer Closed',
          color:
              isShiftOpen ? const Color(0xFF2E7D32) : const Color(0xFFC8102E),
        ),
        _buildStatusBadge(
          icon: pendingSyncCount > 0
              ? Icons.sync_rounded
              : Icons.cloud_done_outlined,
          label: pendingSyncCount > 0
              ? 'Syncing ($pendingSyncCount)'
              : 'Cloud Synced',
          color: pendingSyncCount > 0
              ? const Color(0xFFE65100)
              : const Color(0xFF2E7D32),
        ),
        _buildStatusBadge(
          icon: Icons.print_outlined,
          label: 'Printer: OK',
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsGrid({
    required double screenWidth,
    required String salesValue,
    required String salesSubtitle,
    required String activeKOTValue,
    required String occupancyValue,
    required String occupancySubtitle,
  }) {
    final columnsCount = screenWidth < 600 ? 1 : 3;
    final cards = [
      _buildInsightCard(
        title: "Today's Gross Sales",
        value: salesValue,
        subtitle: salesSubtitle,
        color: const Color(0xFF003893),
        icon: Icons.trending_up_rounded,
      ),
      _buildInsightCard(
        title: 'Active KOT Orders',
        value: activeKOTValue,
        subtitle: 'KOT queue size',
        color: const Color(0xFF2E7D32),
        icon: Icons.soup_kitchen_rounded,
      ),
      _buildInsightCard(
        title: 'Table Occupancy',
        value: occupancyValue,
        subtitle: occupancySubtitle,
        color: const Color(0xFFE65100),
        icon: Icons.table_bar_rounded,
      ),
    ];

    if (columnsCount == 1) {
      return Column(
        children: cards
            .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: c,
                ))
            .toList(),
      );
    }

    return Row(
      children: cards
          .map((c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: c,
                ),
              ))
          .toList(),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
              fontSize: 16,
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

  Widget _buildMiniTableMap(List<TableModel> tables) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Interactive Floor Map Preview',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),
          tables.isEmpty
              ? const Text('No tables configured.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13))
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tables.map((table) {
                    final isBilling = table.status == 'BILLING';
                    final isOccupied = table.status == 'OCCUPIED';
                    final isDirty = table.status == 'DIRTY';

                    Color statusColor = const Color(0xFF2E7D32); // FREE = Green
                    if (isBilling) {
                      statusColor = const Color(0xFFE65100); // BILLING = Orange
                    } else if (isOccupied) {
                      statusColor = const Color(0xFF003893); // OCCUPIED = Blue
                    } else if (isDirty) {
                      statusColor =
                          const Color(0xFF78909C); // DIRTY = Grey-blue
                    }

                    return InkWell(
                      onTap: () {
                        ref.read(orderProvider.notifier).selectTable(table.id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const OrderIntakeScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: statusColor, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          table.tableNumber,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildVerticalNotificationFeed(String role) {
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
            MaterialPageRoute(
                builder: (context) => const BillingTerminalScreen()),
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
            MaterialPageRoute(
                builder: (context) => const KitchenDisplayScreen()),
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

    if (alerts.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.done_all_rounded, color: Color(0xFF2E7D32)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'All stations online. No warnings.',
                style: TextStyle(fontSize: 13, color: const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.notifications_active_outlined,
                color: Color(0xFFC8102E), size: 18),
            const SizedBox(width: 8),
            Text(
              'Action Center (${alerts.length})',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...alerts.map((alert) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.012),
                  blurRadius: 6,
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
                  child: Icon(alert['icon'], color: alert['color'], size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                  color: Color(0xFF1E293B)),
                            ),
                          ),
                          Text(alert['time'],
                              style: const TextStyle(
                                  fontSize: 9, color: Color(0xFF94A3B8))),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alert['desc'],
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                if (alert['action'] != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.arrow_circle_right_outlined,
                        color: alert['color'], size: 18),
                    onPressed: alert['action'],
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}
