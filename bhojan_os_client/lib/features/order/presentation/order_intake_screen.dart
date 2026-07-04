import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../menu/domain/menu_model.dart';
import '../../menu/presentation/menu_notifier.dart';
import '../../table/presentation/table_notifier.dart';
import '../../table/domain/table_model.dart';
import '../domain/order_model.dart';
import 'order_notifier.dart';

class OrderIntakeScreen extends ConsumerStatefulWidget {
  const OrderIntakeScreen({super.key});

  @override
  ConsumerState<OrderIntakeScreen> createState() => _OrderIntakeScreenState();
}

class _OrderIntakeScreenState extends ConsumerState<OrderIntakeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuProvider);
    final orderState = ref.watch(orderProvider);
    final tableList = ref.watch(tableProvider);

    final selectedTable = tableList.firstWhere(
      (t) => t.id == orderState.selectedTableId,
      orElse: () => TableModel(id: '', tableNumber: '?', capacity: 0, section: '', status: 'FREE'),
    );

    // Filter items by category and search query
    final categoryItems = menuState.items
        .where((item) => item.categoryId == menuState.selectedCategoryId)
        .where((item) => item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order: Table ${selectedTable.tableNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003893), fontSize: 18),
            ),
            Text(
              'Section: ${selectedTable.section}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(orderProvider.notifier).clearCart();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cart cleared.')),
              );
            },
            icon: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFC8102E)),
            tooltip: 'Clear Cart',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Left side: Menu items grid
          Expanded(
            flex: isTablet ? 2 : 1,
            child: Column(
              children: [
                // Search & Categories panel
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      // Search bar
                      TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search menu items...',
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Horizontal Category tabs
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: menuState.categories.length,
                          itemBuilder: (context, index) {
                            final category = menuState.categories[index];
                            final isSelected = category.id == menuState.selectedCategoryId;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(category.name),
                                selected: isSelected,
                                selectedColor: const Color(0xFFC8102E),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                                  fontWeight: FontWeight.bold,
                                ),
                                onSelected: (_) {
                                  ref.read(menuProvider.notifier).selectCategory(category.id);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Items Grid
                Expanded(
                  child: categoryItems.isEmpty
                      ? const Center(child: Text('No items found matching filter.'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isTablet ? 3 : 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: categoryItems.length,
                          itemBuilder: (context, index) {
                            final item = categoryItems[index];
                            return _buildMenuItemCard(item);
                          },
                        ),
                ),
              ],
            ),
          ),
          // Right side: Persistent Cart for Tablet view
          if (isTablet)
            Container(
              width: 320,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(left: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: _buildCartView(context),
            ),
        ],
      ),
      bottomNavigationBar: !isTablet
          ? Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${orderState.cartItems.length} items in cart',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        Text(
                          'NPR ${_calculateCartTotal(orderState.cartItems).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFC8102E)),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC8102E),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: orderState.cartItems.isEmpty
                        ? null
                        : () => _showMobileCartSheet(context),
                    child: const Text('Review Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    return GestureDetector(
      onTap: item.isAvailable ? () => _showModifierSheet(item) : null,
      child: Opacity(
        opacity: item.isAvailable ? 1.0 : 0.5,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Veg/Non-Veg Tag icon
                  Icon(
                    Icons.circle,
                    size: 14,
                    color: item.isVeg ? const Color(0xFF2E7D32) : const Color(0xFFC8102E),
                  ),
                  if (!item.isAvailable)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('OUT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                'NPR ${item.price.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF003893)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showModifierSheet(MenuItem item) {
    List<MenuItemModifier> selectedModifiers = [];
    String customNotes = '';
    int qty = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF003893)),
                      ),
                      Text(
                        'NPR ${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(item.description, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                  const Divider(height: 24),
                  if (item.modifiers.isNotEmpty) ...[
                    const Text('Modifiers & Add-ons', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    ...item.modifiers.map((mod) {
                      final isSelected = selectedModifiers.contains(mod);
                      return CheckboxListTile(
                        title: Text(mod.name),
                        secondary: Text('+NPR ${mod.price.toStringAsFixed(2)}'),
                        value: isSelected,
                        activeColor: const Color(0xFFC8102E),
                        onChanged: (val) {
                          setSheetState(() {
                            if (val == true) {
                              selectedModifiers.add(mod);
                            } else {
                              selectedModifiers.remove(mod);
                            }
                          });
                        },
                      );
                    }),
                    const Divider(height: 24),
                  ],
                  const Text('Kitchen Instructions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (val) => customNotes = val,
                    decoration: InputDecoration(
                      hintText: 'e.g. Spicy, extra chutney, no onion...',
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (qty > 1) {
                                setSheetState(() => qty--);
                              }
                            },
                            icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF64748B)),
                          ),
                          Text('$qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          IconButton(
                            onPressed: () => setSheetState(() => qty++),
                            icon: const Icon(Icons.add_circle_outline, color: Color(0xFFC8102E)),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC8102E),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          ref.read(orderProvider.notifier).addToCart(
                                item,
                                selectedModifiers,
                                customNotes,
                                qty,
                              );
                          Navigator.pop(context);
                        },
                        child: const Text('Add to Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCartView(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final total = _calculateCartTotal(orderState.cartItems);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFFF8F9FA),
          child: const Text(
            'Order Summary (KOT Cart)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
          ),
        ),
        Expanded(
          child: orderState.cartItems.isEmpty
              ? const Center(child: Text('Cart is empty. Select items to order.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orderState.cartItems.length,
                  itemBuilder: (context, index) {
                    final item = orderState.cartItems[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.menuItem.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                Text(
                                  'NPR ${item.itemTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF003893)),
                                ),
                              ],
                            ),
                            if (item.selectedModifiers.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              ...item.selectedModifiers.map((mod) => Text(
                                    '+ ${mod.name} (NPR ${mod.price})',
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                  )),
                            ],
                            if (item.notes.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Note: "${item.notes}"',
                                style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Color(0xFFC8102E)),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        ref.read(orderProvider.notifier).updateCartQuantity(index, item.quantity - 1);
                                      },
                                      icon: const Icon(Icons.remove, size: 16),
                                    ),
                                    Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        ref.read(orderProvider.notifier).updateCartQuantity(index, item.quantity + 1);
                                      },
                                      icon: const Icon(Icons.add, size: 16),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () {
                                    ref.read(orderProvider.notifier).removeFromCart(index);
                                  },
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFC8102E)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    'NPR ${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFFC8102E)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC8102E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: orderState.cartItems.isEmpty
                    ? null
                    : () {
                        ref.read(orderProvider.notifier).submitOrder();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('KOT sent to kitchen successfully!')),
                        );
                        Navigator.pop(context);
                      },
                child: const Text(
                  'Send to Kitchen (Confirm KOT)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showMobileCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: _buildCartView(context),
        );
      },
    );
  }

  double _calculateCartTotal(List<OrderItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.itemTotal);
  }
}
