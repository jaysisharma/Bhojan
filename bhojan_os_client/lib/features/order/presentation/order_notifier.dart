import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../core/network/dio_client.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../auth/domain/auth_state.dart';
import '../../menu/domain/menu_model.dart';
import '../../table/presentation/table_notifier.dart';
import '../../sync/domain/sync_service.dart';
import '../domain/order_model.dart';

class OrderState {
  final Map<String, OrderModel> activeOrders;
  final List<OrderItem> cartItems;
  final String? selectedTableId;

  OrderState({
    required this.activeOrders,
    required this.cartItems,
    this.selectedTableId,
  });

  OrderState copyWith({
    Map<String, OrderModel>? activeOrders,
    List<OrderItem>? cartItems,
    String? selectedTableId,
  }) {
    return OrderState(
      activeOrders: activeOrders ?? this.activeOrders,
      cartItems: cartItems ?? this.cartItems,
      selectedTableId: selectedTableId ?? this.selectedTableId,
    );
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  final Ref _ref;
  io.Socket? _socket;

  OrderNotifier(this._ref)
      : super(OrderState(
          activeOrders: _initialOrders,
          cartItems: [],
          selectedTableId: null,
        )) {
    _initSocket();
    
    // Listen reactive to auth status changes to connect/disconnect socket.IO gateway
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated && 
          previous?.status != AuthStatus.authenticated) {
        _initSocket();
      } else if (next.status == AuthStatus.unauthenticated) {
        _disconnectSocket();
      }
    });
  }

  static final Map<String, OrderModel> _initialOrders = {
    't2': OrderModel(
      id: 'ord_t2',
      tableId: 't2',
      status: 'PREPARING',
      createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
      items: [
        OrderItem(
          menuItem: MenuItem(
            id: 'm1',
            categoryId: 'cat_momo',
            name: 'Chicken Momo',
            description: '',
            price: 250.00,
            isVeg: false,
            isAvailable: true,
            modifiers: [],
          ),
          quantity: 2,
          selectedModifiers: [
            MenuItemModifier(id: 'mod1', name: 'Cheese Momo (Add-on)', price: 60.00, isAvailable: true),
          ],
          notes: 'Spicy, soup separate',
        ),
      ],
    ),
    'r1': OrderModel(
      id: 'ord_r1',
      tableId: 'r1',
      status: 'PENDING',
      createdAt: DateTime.now().subtract(const Duration(minutes: 22)),
      items: [
        OrderItem(
          menuItem: MenuItem(
            id: 'm3',
            categoryId: 'cat_main',
            name: 'Chicken Chowmein',
            description: '',
            price: 280.00,
            isVeg: false,
            isAvailable: true,
            modifiers: [],
          ),
          quantity: 1,
          selectedModifiers: [],
          notes: 'Extra spicy',
        ),
        OrderItem(
          menuItem: MenuItem(
            id: 'm4',
            categoryId: 'cat_bev',
            name: 'Iced Americano',
            description: '',
            price: 150.00,
            isVeg: true,
            isAvailable: true,
            modifiers: [],
          ),
          quantity: 1,
          selectedModifiers: [
            MenuItemModifier(id: 'mod5', name: 'Caramel Syrup', price: 40.00, isAvailable: true),
          ],
          notes: 'No sugar',
        ),
      ],
    ),
    'r3': OrderModel(
      id: 'ord_r3',
      tableId: 'r3',
      status: 'READY',
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
      items: [
        OrderItem(
          menuItem: MenuItem(
            id: 'm2',
            categoryId: 'cat_momo',
            name: 'Veg Momo',
            description: '',
            price: 200.00,
            isVeg: true,
            isAvailable: true,
            modifiers: [],
          ),
          quantity: 2,
          selectedModifiers: [],
          notes: '',
        ),
      ],
    ),
  };

  void _initSocket() {
    final authState = _ref.read(authProvider);
    if (authState.accessToken == null || authState.user == null) return;

    _disconnectSocket();

    try {
      _socket = io.io(
        'http://192.168.1.68:3000',
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      _socket!.connect();

      _socket!.onConnect((_) {
        // ignore: avoid_print
        print('Socket.IO gateway connected.');
        _socket!.emit('join:room', {
          'restaurantId': authState.user!.restaurantId,
          'token': authState.accessToken,
        });
      });

      _socket!.on('order:new', (data) {
        // Dynamically pull latest order state
        _ref.read(tableProvider.notifier).fetchTables();
      });

      _socket!.on('order:updated', (data) {
        final orderId = data['orderId'] as String;
        final status = data['status'] as String;
        _updateLocalOrderStatusById(orderId, status);
      });
      
    } catch (e) {
      // ignore: avoid_print
      print('Socket connection initialization failed: $e');
    }
  }

  void _disconnectSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void _updateLocalOrderStatusById(String orderId, String status) {
    final updatedOrders = Map<String, OrderModel>.from(state.activeOrders);
    String? targetTableId;

    updatedOrders.forEach((tableId, order) {
      if (order.id == orderId) {
        updatedOrders[tableId] = order.copyWith(status: status);
        targetTableId = tableId;
      }
    });

    if (targetTableId != null) {
      if (status == 'SETTLED') {
        _ref.read(tableProvider.notifier).updateTableStatus(targetTableId!, 'FREE');
        updatedOrders.remove(targetTableId);
      } else if (status == 'BILLING') {
        _ref.read(tableProvider.notifier).updateTableStatus(targetTableId!, 'BILLING');
      }
      state = state.copyWith(activeOrders: updatedOrders);
    }
  }

  void selectTable(String tableId) {
    state = state.copyWith(
      selectedTableId: tableId,
      cartItems: [],
    );
  }

  void addToCart(MenuItem item, List<MenuItemModifier> modifiers, String notes, int quantity) {
    final newItem = OrderItem(
      menuItem: item,
      quantity: quantity,
      selectedModifiers: modifiers,
      notes: notes,
    );
    state = state.copyWith(
      cartItems: [...state.cartItems, newItem],
    );
  }

  void removeFromCart(int index) {
    final updated = List<OrderItem>.from(state.cartItems)..removeAt(index);
    state = state.copyWith(cartItems: updated);
  }

  void updateCartQuantity(int index, int quantity) {
    if (quantity <= 0) {
      removeFromCart(index);
      return;
    }
    final updated = List<OrderItem>.from(state.cartItems);
    updated[index].quantity = quantity;
    state = state.copyWith(cartItems: updated);
  }

  void clearCart() {
    state = state.copyWith(cartItems: []);
  }

  Future<void> submitOrder() async {
    final tableId = state.selectedTableId;
    if (tableId == null || state.cartItems.isEmpty) return;

    final newOrder = OrderModel(
      id: 'ord_${DateTime.now().millisecondsSinceEpoch}',
      tableId: tableId,
      items: List.from(state.cartItems),
      status: 'PENDING',
      createdAt: DateTime.now(),
    );

    // Optimistic UI updates
    final updatedOrders = Map<String, OrderModel>.from(state.activeOrders);
    updatedOrders[tableId] = newOrder;
    _ref.read(tableProvider.notifier).updateTableStatus(tableId, 'OCCUPIED');

    state = state.copyWith(
      activeOrders: updatedOrders,
      cartItems: [],
    );

    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.post('/orders', data: newOrder.toJson());
      
      if (response.statusCode == 200) {
        final authState = _ref.read(authProvider);
        // Dispatch real-time Socket notification
        _socket?.emit('order:create', {
          'restaurantId': authState.user?.restaurantId,
          'orderId': newOrder.id,
          'payload': newOrder.toJson(),
        });
      }
    } catch (e) {
      // Queue order submission in sync service cache
      await _ref.read(syncServiceProvider).queueMutation(
        '/orders',
        'POST',
        newOrder.toJson(),
      );
    }
  }

  Future<void> updateOrderStatus(String tableId, String status) async {
    final updatedOrders = Map<String, OrderModel>.from(state.activeOrders);
    final order = updatedOrders[tableId];
    if (order == null) return;

    // Optimistic UI updates
    updatedOrders[tableId] = order.copyWith(status: status);
    if (status == 'SETTLED') {
      _ref.read(tableProvider.notifier).updateTableStatus(tableId, 'FREE');
      updatedOrders.remove(tableId);
    } else if (status == 'BILLING') {
      _ref.read(tableProvider.notifier).updateTableStatus(tableId, 'BILLING');
    }
    state = state.copyWith(activeOrders: updatedOrders);

    try {
      final dio = _ref.read(dioProvider);
      await dio.patch('/orders/${order.id}/status', data: {'status': status});

      final authState = _ref.read(authProvider);
      // Dispatch real-time status update to other terminals
      _socket?.emit('order:update-status', {
        'restaurantId': authState.user?.restaurantId,
        'orderId': order.id,
        'status': status,
      });
    } catch (e) {
      // Queue status updates in sync service cache
      await _ref.read(syncServiceProvider).queueMutation(
        '/orders/${order.id}/status',
        'PATCH',
        {'status': status},
      );
    }
  }

  Future<void> settleOrder(String tableId) async {
    final updatedOrders = Map<String, OrderModel>.from(state.activeOrders);
    final order = updatedOrders[tableId];
    if (order == null) return;

    // Optimistic UI updates
    updatedOrders.remove(tableId);
    _ref.read(tableProvider.notifier).updateTableStatus(tableId, 'DIRTY');
    state = state.copyWith(activeOrders: updatedOrders);

    try {
      final dio = _ref.read(dioProvider);
      await dio.post('/billing/invoice', data: {
        'orderId': order.id,
        'discount': 0.0,
        'paymentMethod': 'CASH',
      });
    } catch (e) {
      // Queue invoice settlement in sync service cache
      await _ref.read(syncServiceProvider).queueMutation(
        '/billing/invoice',
        'POST',
        {
          'orderId': order.id,
          'discount': 0.0,
          'paymentMethod': 'CASH',
        },
      );
    }
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  return OrderNotifier(ref);
});
