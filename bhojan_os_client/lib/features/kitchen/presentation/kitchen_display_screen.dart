import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../order/presentation/order_notifier.dart';
import '../../table/presentation/table_notifier.dart';
import '../../table/domain/table_model.dart';
import '../../order/domain/order_model.dart';

class KitchenDisplayScreen extends ConsumerWidget {
  const KitchenDisplayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderProvider);
    final tables = ref.watch(tableProvider);

    // Filter and sort active orders (oldest first)
    final activeOrdersList = orderState.activeOrders.values
        .where((order) => order.status == 'PENDING' || order.status == 'PREPARING' || order.status == 'READY')
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        title: const Text(
          'Kitchen Display System (KDS)',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
        ),
      ),
      body: activeOrdersList.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Color(0xFF2E7D32)),
                  SizedBox(height: 16),
                  Text('All clear! No pending orders.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isTablet ? 3 : 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: activeOrdersList.length,
              itemBuilder: (context, index) {
                final order = activeOrdersList[index];
                final table = tables.firstWhere(
                  (t) => t.id == order.tableId,
                  orElse: () => TableModel(id: '', tableNumber: '?', capacity: 0, section: '', status: ''),
                );
                return _buildKdsCard(context, ref, order, table);
              },
            ),
    );
  }

  Widget _buildKdsCard(BuildContext context, WidgetRef ref, OrderModel order, TableModel table) {
    final minutesElapsed = DateTime.now().difference(order.createdAt).inMinutes;

    // SLA Color Tagging
    Color headerColor;
    Color alertColor;
    if (minutesElapsed >= 20) {
      headerColor = const Color(0xFFC8102E); // Red (Overdue)
      alertColor = Colors.red.shade50;
    } else if (minutesElapsed >= 10) {
      headerColor = const Color(0xFFE65100); // Orange (Warning)
      alertColor = Colors.orange.shade50;
    } else {
      headerColor = const Color(0xFF2E7D32); // Green (Healthy)
      alertColor = Colors.green.shade50;
    }

    // Button status controls
    String buttonText = '';
    Color buttonColor = const Color(0xFF2E7D32);
    String nextStatus = '';

    if (order.status == 'PENDING') {
      buttonText = 'Start Preparing';
      buttonColor = const Color(0xFF003893);
      nextStatus = 'PREPARING';
    } else if (order.status == 'PREPARING') {
      buttonText = 'Mark Ready';
      buttonColor = const Color(0xFF2E7D32);
      nextStatus = 'READY';
    } else if (order.status == 'READY') {
      buttonText = 'Done & Serve';
      buttonColor = const Color(0xFF455A64);
      nextStatus = 'SERVED';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: headerColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Header
          Container(
            color: headerColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Table ${table.tableNumber}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$minutesElapsed m ago',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // Status Strip
          Container(
            color: alertColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status: ${order.status}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: headerColor,
                  ),
                ),
                Text(
                  table.section,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          // Items List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: order.items.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final item = order.items[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.quantity} x ',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                        ),
                        Expanded(
                          child: Text(
                            item.menuItem.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                          ),
                        ),
                      ],
                    ),
                    if (item.selectedModifiers.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      ...item.selectedModifiers.map((mod) => Padding(
                            padding: const EdgeInsets.only(left: 24.0),
                            child: Text(
                              '+ ${mod.name}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          )),
                    ],
                    if (item.notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 24.0),
                        child: Text(
                          'Note: "${item.notes}"',
                          style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFFC8102E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          // Action Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (nextStatus == 'SERVED') {
                  ref.read(orderProvider.notifier).updateOrderStatus(table.id, 'BILLING');
                } else {
                  ref.read(orderProvider.notifier).updateOrderStatus(table.id, nextStatus);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Order updated to $nextStatus.')),
                );
              },
              child: Text(
                buttonText,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
