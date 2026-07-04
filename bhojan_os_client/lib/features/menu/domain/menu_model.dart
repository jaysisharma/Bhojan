class MenuItemModifier {
  final String id;
  final String name;
  final double price;
  final bool isAvailable;

  MenuItemModifier({
    required this.id,
    required this.name,
    required this.price,
    required this.isAvailable,
  });

  factory MenuItemModifier.fromJson(Map<String, dynamic> json) {
    return MenuItemModifier(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }
}

class MenuItem {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final double price;
  final bool isVeg;
  final bool isAvailable;
  final List<MenuItemModifier> modifiers;

  MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.isVeg,
    required this.isAvailable,
    required this.modifiers,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    var modList = json['modifiers'] as List<dynamic>? ?? [];
    return MenuItem(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      isVeg: json['isVeg'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? true,
      modifiers: modList.map((m) => MenuItemModifier.fromJson(m as Map<String, dynamic>)).toList(),
    );
  }
}

class MenuCategory {
  final String id;
  final String name;
  final int sortOrder;

  MenuCategory({
    required this.id,
    required this.name,
    required this.sortOrder,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}
