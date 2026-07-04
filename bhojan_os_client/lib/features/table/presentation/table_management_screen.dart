import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/table_model.dart';
import 'table_notifier.dart';
import '../../order/presentation/order_notifier.dart';
import '../../order/presentation/order_intake_screen.dart';

class TableManagementScreen extends ConsumerWidget {
  const TableManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(tableProvider);

    // Group tables by section
    final sections = tables.map((t) => t.section).toSet().toList();

    return DefaultTabController(
      length: sections.isEmpty ? 1 : sections.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
          title: const Text(
            'Table & Floor Layout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF003893),
            ),
          ),
          bottom: sections.isEmpty
              ? null
              : TabBar(
                  isScrollable: true,
                  labelColor: const Color(0xFFC8102E),
                  unselectedLabelColor: const Color(0xFF64748B),
                  indicatorColor: const Color(0xFFC8102E),
                  tabs: sections.map((sec) => Tab(text: sec)).toList(),
                ),
        ),
        body: sections.isEmpty
            ? const Center(child: Text('No dining sections configured.'))
            : TabBarView(
                children: sections.map((sec) {
                  final secTables = tables.where((t) => t.section == sec).toList();
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: secTables.length,
                    itemBuilder: (context, index) {
                      final table = secTables[index];
                      return _buildTableCard(context, ref, table);
                    },
                  );
                }).toList(),
              ),
      ),
    );
  }

  Widget _buildTableCard(BuildContext context, WidgetRef ref, TableModel table) {
    Color cardColor;
    Color textColor;
    String statusLabel;

    switch (table.status) {
      case 'OCCUPIED':
        cardColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC8102E);
        statusLabel = 'Occupied';
        break;
      case 'BILLING':
        cardColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        statusLabel = 'Billing';
        break;
      case 'DIRTY':
        cardColor = const Color(0xFFFFFDE7);
        textColor = const Color(0xFFF57F17);
        statusLabel = 'Dirty / Cleanup';
        break;
      case 'FREE':
      default:
        cardColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        statusLabel = 'Available';
        break;
    }

    return GestureDetector(
      onTap: () => _handleTableTap(context, ref, table),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: textColor.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: textColor.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  table.tableNumber,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.people_outline, size: 14, color: textColor),
                      const SizedBox(width: 4),
                      Text(
                        '${table.capacity}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Tap to manage',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleTableTap(BuildContext context, WidgetRef ref, TableModel table) {
    if (table.status == 'FREE') {
      // Start a new order
      ref.read(orderProvider.notifier).selectTable(table.id);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const OrderIntakeScreen(),
        ),
      );
    } else if (table.status == 'DIRTY') {
      // Prompt to clean/free table
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Reset ${table.tableNumber}?'),
          content: const Text('Confirm that this table is cleaned and ready for new guests.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
              onPressed: () {
                ref.read(tableProvider.notifier).updateTableStatus(table.id, 'FREE');
                Navigator.pop(context);
              },
              child: const Text('Mark Clean', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      // Occupied / Billing table details sheet
      _showTableOptionsSheet(context, ref, table);
    }
  }

  void _showTableOptionsSheet(BuildContext context, WidgetRef ref, TableModel table) {
    final orderState = ref.read(orderProvider);
    final activeOrder = orderState.activeOrders[table.id];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Table ${table.tableNumber} Management',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003893),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  activeOrder != null
                      ? 'Order Status: ${activeOrder.status}  •  Subtotal: NPR ${activeOrder.subtotal}'
                      : 'Billing or processing order...',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add Items (Modify Order)', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003893),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ref.read(orderProvider.notifier).selectTable(table.id);
                    // Add items from active order to cart
                    if (activeOrder != null) {
                      for (final item in activeOrder.items) {
                        ref.read(orderProvider.notifier).addToCart(
                              item.menuItem,
                              item.selectedModifiers,
                              item.notes,
                              item.quantity,
                            );
                      }
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const OrderIntakeScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                if (table.status == 'OCCUPIED')
                  OutlinedButton.icon(
                    icon: const Icon(Icons.receipt_long, color: Color(0xFFE65100)),
                    label: const Text('Request Bill (Go to Billing)', style: TextStyle(color: Color(0xFFE65100))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE65100)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      ref.read(orderProvider.notifier).updateOrderStatus(table.id, 'BILLING');
                      Navigator.pop(context);
                    },
                  ),
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: const Icon(Icons.cancel_outlined, color: Color(0xFFC8102E)),
                  label: const Text('Release Table / Cancel Order', style: TextStyle(color: Color(0xFFC8102E))),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Cancel Order?'),
                        content: const Text('Are you sure you want to cancel the order and release the table? This action requires owner override in production.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('No'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC8102E)),
                            onPressed: () {
                              ref.read(orderProvider.notifier).updateOrderStatus(table.id, 'SETTLED');
                              ref.read(tableProvider.notifier).updateTableStatus(table.id, 'FREE');
                              Navigator.pop(context);
                            },
                            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
