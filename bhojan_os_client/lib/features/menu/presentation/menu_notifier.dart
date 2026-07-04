import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/menu_model.dart';

class MenuState {
  final List<MenuCategory> categories;
  final List<MenuItem> items;
  final String selectedCategoryId;

  MenuState({
    required this.categories,
    required this.items,
    required this.selectedCategoryId,
  });

  MenuState copyWith({
    List<MenuCategory>? categories,
    List<MenuItem>? items,
    String? selectedCategoryId,
  }) {
    return MenuState(
      categories: categories ?? this.categories,
      items: items ?? this.items,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
    );
  }
}

class MenuNotifier extends StateNotifier<MenuState> {
  final Ref _ref;

  MenuNotifier(this._ref)
      : super(MenuState(
          categories: _initialCategories,
          items: _initialItems,
          selectedCategoryId: 'cat_momo',
        )) {
    fetchMenu();
  }

  static final List<MenuCategory> _initialCategories = [
    MenuCategory(id: 'cat_momo', name: 'Momo', sortOrder: 1),
    MenuCategory(id: 'cat_main', name: 'Main Course', sortOrder: 2),
    MenuCategory(id: 'cat_bev', name: 'Beverages', sortOrder: 3),
  ];

  static final List<MenuItem> _initialItems = [
    MenuItem(
      id: 'm1',
      categoryId: 'cat_momo',
      name: 'Chicken Momo',
      description: 'Steam chicken momo served with tomato sesame chutney',
      price: 250.00,
      isVeg: false,
      isAvailable: true,
      modifiers: [
        MenuItemModifier(id: 'mod1', name: 'Cheese Momo (Add-on)', price: 60.00, isAvailable: true),
        MenuItemModifier(id: 'mod2', name: 'Jhol Momo style', price: 40.00, isAvailable: true),
      ],
    ),
    MenuItem(
      id: 'm2',
      categoryId: 'cat_momo',
      name: 'Veg Momo',
      description: 'Steam paneer and mixed veg momo served with sesame chutney',
      price: 200.00,
      isVeg: true,
      isAvailable: true,
      modifiers: [
        MenuItemModifier(id: 'mod3', name: 'Kothey style (Fried)', price: 30.00, isAvailable: true),
      ],
    ),
    MenuItem(
      id: 'm3',
      categoryId: 'cat_main',
      name: 'Chicken Chowmein',
      description: 'Stir-fried noodles cooked with chicken chunks and fresh vegetables',
      price: 280.00,
      isVeg: false,
      isAvailable: true,
      modifiers: [],
    ),
    MenuItem(
      id: 'm4',
      categoryId: 'cat_bev',
      name: 'Iced Americano',
      description: 'Double espresso shot poured over ice water',
      price: 150.00,
      isVeg: true,
      isAvailable: true,
      modifiers: [
        MenuItemModifier(id: 'mod4', name: 'Extra Shot Espresso', price: 50.00, isAvailable: true),
        MenuItemModifier(id: 'mod5', name: 'Caramel Syrup', price: 40.00, isAvailable: true),
      ],
    ),
    MenuItem(
      id: 'm5',
      categoryId: 'cat_bev',
      name: 'Nepalese Milk Tea',
      description: 'Traditional spiced tea brewed with milk and cardamom',
      price: 80.00,
      isVeg: true,
      isAvailable: true,
      modifiers: [],
    ),
  ];

  Future<void> fetchMenu() async {
    try {
      final response = await _ref.read(dioProvider).get('/menu/items');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List<dynamic>;
        final fetchedItems = data.map((json) => MenuItem.fromJson(json as Map<String, dynamic>)).toList();
        
        final Map<String, MenuCategory> categoryMap = {};
        for (final itemJson in data) {
          final catJson = itemJson['category'] as Map<String, dynamic>?;
          if (catJson != null) {
            final cat = MenuCategory.fromJson(catJson);
            categoryMap[cat.id] = cat;
          }
        }

        final categoriesList = categoryMap.isNotEmpty
            ? (categoryMap.values.toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)))
            : _initialCategories;

        state = state.copyWith(
          items: fetchedItems,
          categories: categoriesList,
          selectedCategoryId: categoriesList.isNotEmpty ? categoriesList.first.id : 'cat_momo',
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Network offline. Loaded local mock menu listings: $e');
    }
  }

  void selectCategory(String categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId);
  }

  Future<void> toggleItemAvailability(String itemId) async {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == itemId)
            MenuItem(
              id: item.id,
              categoryId: item.categoryId,
              name: item.name,
              description: item.description,
              price: item.price,
              isVeg: item.isVeg,
              isAvailable: !item.isAvailable,
              modifiers: item.modifiers,
            )
          else
            item
      ],
    );

    try {
      final item = state.items.firstWhere((i) => i.id == itemId);
      await _ref.read(dioProvider).patch('/menu/items/$itemId', data: {'isAvailable': item.isAvailable});
    } catch (e) {
      // ignore: avoid_print
      print('Failed to sync item availability change to server: $e');
    }
  }
}

final menuProvider = StateNotifierProvider<MenuNotifier, MenuState>((ref) {
  return MenuNotifier(ref);
});
