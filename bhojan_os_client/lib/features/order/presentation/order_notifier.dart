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
          activeOrders: const {},
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

  Future<void> fetchActiveOrders() async {
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.get('/orders');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List<dynamic>;
        final Map<String, OrderModel> loadedOrders = {};
        for (final item in data) {
          final order = OrderModel.fromSocketJson(item as Map<String, dynamic>);
          loadedOrders[order.tableId] = order;
        }
        state = state.copyWith(activeOrders: loadedOrders);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Failed to fetch active orders from server: $e');
    }
  }

  void _initSocket() {
    final authState = _ref.read(authProvider);
    if (authState.accessToken == null || authState.user == null) return;

    _disconnectSocket();
    fetchActiveOrders();

    try {
      _socket = io.io(
        'http://192.168.1.76:3000',
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
        try {
          final newOrder = OrderModel.fromSocketJson(data as Map<String, dynamic>);
          final updatedOrders = Map<String, OrderModel>.from(state.activeOrders);
          updatedOrders[newOrder.tableId] = newOrder;
          state = state.copyWith(activeOrders: updatedOrders);
        } catch (e) {
          // ignore: avoid_print
          print('Error parsing realtime order: $e');
        }
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
        _ref.read(tableProvider.notifier).updateTableStatus(targetTableId!, 'DIRTY');
        updatedOrders.remove(targetTableId);
      } else if (status == 'BILLING') {
        _ref.read(tableProvider.notifier).updateTableStatus(targetTableId!, 'BILLING');
      }
      state = state.copyWith(activeOrders: updatedOrders);
    }
  }

  void selectTable(String tableId) {
    final existingOrder = state.activeOrders[tableId];
    final cartItems = existingOrder != null
        ? existingOrder.items.map((item) => OrderItem(
            menuItem: item.menuItem,
            quantity: item.quantity,
            selectedModifiers: List.from(item.selectedModifiers),
            notes: item.notes,
            isPlaced: true,
          )).toList()
        : <OrderItem>[];

    state = state.copyWith(
      selectedTableId: tableId,
      cartItems: cartItems,
    );
  }

  void addToCart(MenuItem item, List<MenuItemModifier> modifiers, String notes, int quantity) {
    final updatedCart = List<OrderItem>.from(state.cartItems);
    
    final existingIndex = updatedCart.indexWhere((cartItem) {
      if (cartItem.isPlaced) return false; // Do NOT merge with already placed items
      if (cartItem.menuItem.id != item.id) return false;
      if (cartItem.notes != notes) return false;
      if (cartItem.selectedModifiers.length != modifiers.length) return false;
      
      for (final mod in modifiers) {
        if (!cartItem.selectedModifiers.any((m) => m.id == mod.id)) return false;
      }
      return true;
    });

    if (existingIndex != -1) {
      updatedCart[existingIndex] = OrderItem(
        menuItem: updatedCart[existingIndex].menuItem,
        quantity: updatedCart[existingIndex].quantity + quantity,
        selectedModifiers: updatedCart[existingIndex].selectedModifiers,
        notes: updatedCart[existingIndex].notes,
        isPlaced: updatedCart[existingIndex].isPlaced,
      );
    } else {
      updatedCart.add(OrderItem(
        menuItem: item,
        quantity: quantity,
        selectedModifiers: modifiers,
        notes: notes,
        isPlaced: false,
      ));
    }

    state = state.copyWith(
      cartItems: updatedCart,
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

    final existingOrder = state.activeOrders[tableId];

    if (existingOrder != null) {
      // Update local state: mark all as placed and update active orders
      for (final item in state.cartItems) {
        item.isPlaced = true;
      }

      final updatedOrder = existingOrder.copyWith(
        items: List.from(state.cartItems),
        status: 'PENDING', // Reset status so kitchen is alerted of new items
      );

      final updatedOrders = Map<String, OrderModel>.from(state.activeOrders);
      updatedOrders[tableId] = updatedOrder;
      state = state.copyWith(
        activeOrders: updatedOrders,
        cartItems: [],
      );

      try {
        final dio = _ref.read(dioProvider);
        final response = await dio.put(
          '/orders/${existingOrder.id}/items',
          data: {
            'items': updatedOrder.items.map((i) => i.toJson()).toList(),
          },
        );

        if (response.statusCode == 200) {
          final authState = _ref.read(authProvider);
          // Dispatch real-time Socket notification with the full updated order
          _socket?.emit('order:create', {
            'restaurantId': authState.user?.restaurantId,
            'orderId': updatedOrder.id,
            'payload': updatedOrder.toSocketJson(),
          });
        }
      } catch (e) {
        // Queue incremental order submission in sync service cache
        await _ref.read(syncServiceProvider).queueMutation(
          '/orders/${existingOrder.id}/items',
          'PUT',
          {
            'items': updatedOrder.items.map((i) => i.toJson()).toList(),
          },
        );
      }
    } else {
      // First-time Order Creation
      for (final item in state.cartItems) {
        item.isPlaced = true;
      }

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
            'payload': newOrder.toSocketJson(),
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

      final authState = _ref.read(authProvider);
      // Dispatch status update socket notification to clear table in other devices
      _socket?.emit('order:update-status', {
        'restaurantId': authState.user?.restaurantId,
        'orderId': order.id,
        'status': 'SETTLED',
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
