import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'menu_notifier.dart';
import '../domain/menu_model.dart';
import '../../auth/presentation/auth_notifier.dart';

class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  ConsumerState<MenuManagementScreen> createState() =>
      _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
    // Force refresh menu listings
    Future.microtask(() => ref.read(menuProvider.notifier).fetchMenu());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuProvider);
    final authState = ref.watch(authProvider);

    final userRole = authState.user?.role ?? 'WAITER';
    final hasEditPermission = userRole == 'OWNER' || userRole == 'MANAGER' || userRole == 'KITCHEN';

    // Filter items by category and search query
    final selectedCategoryItems = menuState.items
        .where((item) => item.categoryId == menuState.selectedCategoryId)
        .where((item) =>
            _searchQuery.isEmpty ||
            item.name.toLowerCase().contains(_searchQuery))
        .toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 650;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Menu & Stock Management',
          style:
              TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003893)),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          IconButton(
            onPressed: () => ref.read(menuProvider.notifier).fetchMenu(),
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh Menu',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Alert Banner for Permission Warning (if Read-Only)
          if (!hasEditPermission)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFFFFF3E0),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFE65100), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Read-only View: Only owners and managers are permitted to toggle menu item availability.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFE65100),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 2. Search Box
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search menu items...',
                prefixIcon:
                    const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: Color(0xFF64748B)),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF003893), width: 1.5),
                ),
              ),
            ),
          ),

          // 3. Categories Selection Tabs List
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: menuState.categories.length,
              itemBuilder: (context, index) {
                final category = menuState.categories[index];
                final isSelected = category.id == menuState.selectedCategoryId;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(
                      category.name,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color:
                            isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        ref
                            .read(menuProvider.notifier)
                            .selectCategory(category.id);
                      }
                    },
                    selectedColor: const Color(0xFF003893),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF003893)
                          : const Color(0xFFE2E8F0),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // 4. Menu Items Grid or List
          Expanded(
            child: selectedCategoryItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 48, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No items match your search.'
                              : 'No items under this category.',
                          style: const TextStyle(
                              color: Color(0xFF64748B), fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : isTablet
                    ? GridView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 380,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 2.2,
                        ),
                        itemCount: selectedCategoryItems.length,
                        itemBuilder: (context, index) => _buildItemCard(
                            selectedCategoryItems[index], hasEditPermission),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: selectedCategoryItems.length,
                        itemBuilder: (context, index) => _buildItemListTile(
                            selectedCategoryItems[index], hasEditPermission),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(MenuItem item, bool hasEditPermission) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: const Color(0xFFE2E8F0), width: item.isAvailable ? 1 : 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Veg/Non-Veg Dot
                      Container(
                        width: 14,
                        height: 14,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: item.isVeg
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFC8102E)),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item.isVeg
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFC8102E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: item.isAvailable
                                ? const Color(0xFF1E293B)
                                : const Color(0xFF94A3B8),
                            decoration: item.isAvailable
                                ? null
                                : TextDecoration.lineThrough,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style:
                        const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rs. ${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: item.isAvailable
                          ? const Color(0xFF003893)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Available Switch
                Switch.adaptive(
                  value: item.isAvailable,
                  activeTrackColor:
                      const Color(0xFF2E7D32).withValues(alpha: 0.5),
                  activeThumbColor: const Color(0xFF2E7D32),
                  onChanged: hasEditPermission
                      ? (value) {
                          ref
                              .read(menuProvider.notifier)
                              .toggleItemAvailability(item.id);
                        }
                      : null,
                ),
                Text(
                  item.isAvailable ? 'Available' : 'Unavailable',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: item.isAvailable
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemListTile(MenuItem item, bool hasEditPermission) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(
                    color: item.isVeg
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC8102E)),
                borderRadius: BorderRadius.circular(3),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isVeg
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFC8102E),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: item.isAvailable
                      ? const Color(0xFF1E293B)
                      : const Color(0xFF94A3B8),
                  decoration:
                      item.isAvailable ? null : TextDecoration.lineThrough,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                item.description,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Rs. ${item.price.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: item.isAvailable
                    ? const Color(0xFF003893)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch.adaptive(
              value: item.isAvailable,
              activeTrackColor: const Color(0xFF2E7D32).withValues(alpha: 0.5),
              activeThumbColor: const Color(0xFF2E7D32),
              onChanged: hasEditPermission
                  ? (value) {
                      ref
                          .read(menuProvider.notifier)
                          .toggleItemAvailability(item.id);
                    }
                  : null,
            ),
            Text(
              item.isAvailable ? 'Available' : 'Unavailable',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: item.isAvailable
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
