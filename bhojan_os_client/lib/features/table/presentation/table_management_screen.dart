import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/table_model.dart';
import 'table_notifier.dart';
import '../../order/presentation/order_notifier.dart';
import '../../order/domain/order_model.dart';
import '../../order/presentation/order_intake_screen.dart';
import '../../auth/presentation/auth_notifier.dart';

class TableManagementScreen extends ConsumerWidget {
  const TableManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(tableProvider);
    final orderState = ref.watch(orderProvider);
    final authState = ref.watch(authProvider);

    final userRole = authState.user?.role ?? 'WAITER';
    final hasEditPermission = userRole == 'OWNER' || userRole == 'MANAGER';

    // Group tables by section
    final sections = tables.map((t) => t.section).toSet().toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final columns = screenWidth < 500
        ? 2
        : (screenWidth < 820 ? 3 : (screenWidth < 1100 ? 4 : 5));
    final double ratio =
        screenWidth < 500 ? 1.05 : (screenWidth < 820 ? 1.15 : 1.25);

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
          actions: [
            if (hasEditPermission)
              IconButton(
                icon: const Icon(Icons.edit_road_rounded,
                    color: Color(0xFF003893)),
                tooltip: 'Manage Floor Layout',
                onPressed: () =>
                    _showLayoutManagementSheet(context, ref, tables, sections),
              ),
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              tooltip: 'Refresh Tables',
              onPressed: () => ref.read(tableProvider.notifier).fetchTables(),
            ),
            const SizedBox(width: 8),
          ],
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
            : Column(
                children: [
                  _buildStatusLegend(),
                  Expanded(
                    child: TabBarView(
                      children: sections.map((sec) {
                        final secTables =
                            tables.where((t) => t.section == sec).toList();
                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: ratio,
                          ),
                          itemCount: secTables.length,
                          itemBuilder: (context, index) {
                            final table = secTables[index];
                            final activeOrder =
                                orderState.activeOrders[table.id];
                            return _buildTableCard(
                                context, ref, table, activeOrder);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatusLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLegendItem('Available', const Color(0xFF2E7D32)),
            const SizedBox(width: 16),
            _buildLegendItem('Occupied', const Color(0xFFC8102E)),
            const SizedBox(width: 16),
            _buildLegendItem('Billing', const Color(0xFFE65100)),
            const SizedBox(width: 16),
            _buildLegendItem('Dirty', const Color(0xFFF57F17)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildTableCard(BuildContext context, WidgetRef ref, TableModel table,
      OrderModel? activeOrder) {
    Color colorTheme;
    String statusLabel;

    switch (table.status) {
      case 'OCCUPIED':
        colorTheme = const Color(0xFFC8102E);
        statusLabel = 'Occupied';
        break;
      case 'BILLING':
        colorTheme = const Color(0xFFE65100);
        statusLabel = 'Billing';
        break;
      case 'DIRTY':
        colorTheme = const Color(0xFFF57F17);
        statusLabel = 'Dirty / Clean';
        break;
      case 'FREE':
      default:
        colorTheme = const Color(0xFF2E7D32);
        statusLabel = 'Available';
        break;
    }

    const double cardAlpha = 0.08;

    return GestureDetector(
      onTap: () => _handleTableTap(context, ref, table),
      child: Container(
        decoration: BoxDecoration(
          color: colorTheme.withValues(alpha: cardAlpha),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: colorTheme.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: colorTheme.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Section: Table Number & Seating Capacity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  table.tableNumber,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorTheme,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: colorTheme.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.people_outline_rounded,
                          size: 13, color: colorTheme),
                      const SizedBox(width: 4),
                      Text(
                        '${table.capacity}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colorTheme,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Middle Section: Live Telemetry (If Occupied/Billing)
            if (activeOrder != null &&
                (table.status == 'OCCUPIED' || table.status == 'BILLING')) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rs. ${activeOrder.subtotal.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorTheme,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 10, color: colorTheme.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Text(
                          '${DateTime.now().difference(activeOrder.createdAt).inMinutes} mins ago',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: colorTheme.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 10),
            ],

            // Bottom Section: Status tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorTheme,
                  ),
                ),
                if (activeOrder != null)
                  Text(
                    '${activeOrder.items.fold(0, (sum, i) => sum + i.quantity)} items',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: colorTheme.withValues(alpha: 0.85),
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
          content: const Text(
              'Confirm that this table is cleaned and ready for new guests.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32)),
              onPressed: () {
                ref
                    .read(tableProvider.notifier)
                    .updateTableStatus(table.id, 'FREE');
                Navigator.pop(context);
              },
              child: const Text('Mark Clean',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      // Occupied / Billing table details sheet
      _showTableOptionsSheet(context, ref, table);
    }
  }

  void _showTableOptionsSheet(
      BuildContext context, WidgetRef ref, TableModel table) {
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
                  style:
                      const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add Items (Modify Order)',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003893),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
                      MaterialPageRoute(
                          builder: (context) => const OrderIntakeScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                if (table.status == 'OCCUPIED')
                  OutlinedButton.icon(
                    icon: const Icon(Icons.receipt_long,
                        color: Color(0xFFE65100)),
                    label: const Text('Request Bill (Go to Billing)',
                        style: TextStyle(color: Color(0xFFE65100))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE65100)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      ref
                          .read(orderProvider.notifier)
                          .updateOrderStatus(table.id, 'BILLING');
                      Navigator.pop(context);
                    },
                  ),
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: const Icon(Icons.cancel_outlined,
                      color: Color(0xFFC8102E)),
                  label: const Text('Release Table / Cancel Order',
                      style: TextStyle(color: Color(0xFFC8102E))),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Cancel Order?'),
                        content: const Text(
                            'Are you sure you want to cancel the order and release the table? This action requires owner override in production.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('No'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC8102E)),
                            onPressed: () {
                              ref
                                  .read(orderProvider.notifier)
                                  .updateOrderStatus(table.id, 'SETTLED');
                              ref
                                  .read(tableProvider.notifier)
                                  .updateTableStatus(table.id, 'FREE');
                              Navigator.pop(context);
                            },
                            child: const Text('Yes, Cancel',
                                style: TextStyle(color: Colors.white)),
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

  // --- Layout Management & CRUD Operations ---

  void _showLayoutManagementSheet(BuildContext context, WidgetRef ref,
      List<TableModel> tables, List<String> sections) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Floor Layout Manager',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003893),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showAddEditTableDialog(context, ref, sections);
                          },
                          icon: const Icon(Icons.add,
                              color: Colors.white, size: 18),
                          label: const Text('Add Table',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Create, modify parameters, or delete tables from layout sections.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: tables.length,
                        separatorBuilder: (context, index) =>
                            const Divider(color: Color(0xFFE2E8F0)),
                        itemBuilder: (context, index) {
                          final table = tables[index];
                          final isDeletable = table.status == 'FREE';

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Table ${table.tableNumber} (${table.section})',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                                'Capacity: ${table.capacity} guests  •  Status: ${table.status}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      color: Color(0xFF003893)),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showAddEditTableDialog(
                                        context, ref, sections,
                                        table: table);
                                  },
                                  tooltip: 'Edit Parameters',
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    color: isDeletable
                                        ? const Color(0xFFC8102E)
                                        : const Color(0xFF94A3B8),
                                  ),
                                  onPressed: isDeletable
                                      ? () {
                                          Navigator.pop(context);
                                          _confirmDeleteTable(
                                              context, ref, table);
                                        }
                                      : null,
                                  tooltip: isDeletable
                                      ? 'Delete Table'
                                      : 'Locked (Occupied/Billing)',
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddEditTableDialog(
      BuildContext context, WidgetRef ref, List<String> existingSections,
      {TableModel? table}) {
    final isEditing = table != null;
    final formKey = GlobalKey<FormState>();
    final numberController =
        TextEditingController(text: table?.tableNumber ?? '');
    final capacityController =
        TextEditingController(text: table?.capacity.toString() ?? '4');

    // Provide a default list of categories if sections are empty
    final sectionsList = existingSections.isEmpty
        ? ['Ground Floor', 'Rooftop Garden', 'Terrace']
        : existingSections;
    String selectedSection = table?.section ?? sectionsList.first;
    final newSectionController = TextEditingController();
    bool useCustomSection = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEditing ? 'Edit Table details' : 'Add New Dining Table',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF003893)),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: numberController,
                        decoration: InputDecoration(
                          labelText: 'Table Number / Name',
                          hintText: 'e.g., T-10, Bar-3',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter table number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: capacityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Seating Capacity',
                          hintText: 'e.g., 2, 4, 8',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Enter seating capacity';
                          }
                          final numVal = int.tryParse(v);
                          if (numVal == null || numVal <= 0) {
                            return 'Enter a valid capacity number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Section dropdown or new section input
                      if (!useCustomSection) ...[
                        DropdownButtonFormField<String>(
                          value: selectedSection,
                          decoration: InputDecoration(
                            labelText: 'Dining Floor Section',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          items: sectionsList
                              .map((sec) => DropdownMenuItem(
                                    value: sec,
                                    child: Text(sec),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => selectedSection = val);
                            }
                          },
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => useCustomSection = true),
                          child: const Text('+ Create New Dining Section',
                              style: TextStyle(color: Color(0xFFC8102E))),
                        ),
                      ] else ...[
                        TextFormField(
                          controller: newSectionController,
                          decoration: InputDecoration(
                            labelText: 'New Section Name',
                            hintText: 'e.g., Balcony, Poolside',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          validator: (v) {
                            if (useCustomSection &&
                                (v == null || v.trim().isEmpty)) {
                              return 'Enter section name';
                            }
                            return null;
                          },
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => useCustomSection = false),
                          child: const Text('Use Existing Section',
                              style: TextStyle(color: Color(0xFF003893))),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003893)),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final number = numberController.text.trim();
                      final capacity =
                          int.parse(capacityController.text.trim());
                      final section = useCustomSection
                          ? newSectionController.text.trim()
                          : selectedSection;

                      Navigator.pop(context);

                      bool success;
                      if (isEditing) {
                        success =
                            await ref.read(tableProvider.notifier).updateTable(
                                  id: table.id,
                                  tableNumber: number,
                                  capacity: capacity,
                                  section: section,
                                );
                      } else {
                        success =
                            await ref.read(tableProvider.notifier).createTable(
                                  tableNumber: number,
                                  capacity: capacity,
                                  section: section,
                                );
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Layout updated successfully.'
                                : 'Failed to update layout. Verify parameters or uniqueness.'),
                            backgroundColor: success
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFC8102E),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(isEditing ? 'Save Changes' : 'Create Table',
                      style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteTable(
      BuildContext context, WidgetRef ref, TableModel table) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Table ${table.tableNumber}?'),
        content: Text(
            'Are you sure you want to permanently delete Table ${table.tableNumber} from section "${table.section}"? This action is irreversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC8102E)),
            onPressed: () async {
              Navigator.pop(context);
              final success =
                  await ref.read(tableProvider.notifier).deleteTable(table.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Table deleted successfully.'
                        : 'Failed to delete table. Make sure it is unoccupied.'),
                    backgroundColor: success
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC8102E),
                  ),
                );
              }
            },
            child: const Text('Yes, Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
