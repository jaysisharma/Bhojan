import '../../menu/domain/menu_model.dart';

class OrderItem {
  final MenuItem menuItem;
  int quantity;
  final List<MenuItemModifier> selectedModifiers;
  final String notes;
  bool isPlaced;

  OrderItem({
    required this.menuItem,
    this.quantity = 1,
    required this.selectedModifiers,
    this.notes = '',
    this.isPlaced = false,
  });

  double get itemTotal {
    double modifiersTotal = selectedModifiers.fold(0, (sum, mod) => sum + mod.price);
    return (menuItem.price + modifiersTotal) * quantity;
  }

  Map<String, dynamic> toJson() {
    return {
      'menuItemId': menuItem.id,
      'quantity': quantity,
      'notes': notes,
      'modifierIds': selectedModifiers.map((m) => m.id).toList(),
    };
  }

  Map<String, dynamic> toSocketJson() {
    return {
      'menuItem': menuItem.toJson(),
      'quantity': quantity,
      'notes': notes,
      'selectedModifiers': selectedModifiers.map((m) => m.toJson()).toList(),
      'isPlaced': isPlaced,
    };
  }

  factory OrderItem.fromSocketJson(Map<String, dynamic> json) {
    var mods = json['selectedModifiers'] as List<dynamic>? ?? [];
    return OrderItem(
      menuItem: MenuItem.fromJson(json['menuItem'] as Map<String, dynamic>),
      quantity: json['quantity'] as int? ?? 1,
      notes: json['notes'] as String? ?? '',
      selectedModifiers: mods.map((m) => MenuItemModifier.fromJson(m as Map<String, dynamic>)).toList(),
      isPlaced: json['isPlaced'] as bool? ?? false,
    );
  }
}

class OrderModel {
  final String id;
  final String tableId;
  final List<OrderItem> items;
  final String status; // 'PENDING', 'PREPARING', 'READY', 'SERVED', 'SETTLED', 'CANCELLED'
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.tableId,
    required this.items,
    required this.status,
    required this.createdAt,
  });

  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.itemTotal);
  }

  OrderModel copyWith({
    String? id,
    String? tableId,
    List<OrderItem>? items,
    String? status,
    DateTime? createdAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      items: items ?? this.items,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableId': tableId,
      'items': items.map((i) => i.toJson()).toList(),
      'status': status,
      'subtotal': subtotal,
    };
  }

  Map<String, dynamic> toSocketJson() {
    return {
      'id': id,
      'tableId': tableId,
      'items': items.map((i) => i.toSocketJson()).toList(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OrderModel.fromSocketJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List<dynamic>? ?? [];
    return OrderModel(
      id: json['id'] as String,
      tableId: json['tableId'] as String,
      items: itemsList.map((i) => OrderItem.fromSocketJson(i as Map<String, dynamic>)).toList(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class BillModel {
  final String id;
  final String orderId;
  final String billNumber;
  final double subtotal;
  final double discountAmount;
  final double serviceCharge;
  final double vatAmount;
  final double grandTotal;
  final String paymentMethod; // 'CASH', 'FONEPAY', 'CARD', 'CREDIT'
  final DateTime createdAt;

  BillModel({
    required this.id,
    required this.orderId,
    required this.billNumber,
    required this.subtotal,
    required this.discountAmount,
    required this.serviceCharge,
    required this.vatAmount,
    required this.grandTotal,
    required this.paymentMethod,
    required this.createdAt,
  });
}
