import '../../menu/domain/menu_model.dart';

class OrderItem {
  final MenuItem menuItem;
  int quantity;
  final List<MenuItemModifier> selectedModifiers;
  final String notes;

  OrderItem({
    required this.menuItem,
    this.quantity = 1,
    required this.selectedModifiers,
    this.notes = '',
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
