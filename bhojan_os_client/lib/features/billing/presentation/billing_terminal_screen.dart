import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../order/presentation/order_notifier.dart';
import '../../table/presentation/table_notifier.dart';
import '../../table/domain/table_model.dart';
import '../../order/domain/order_model.dart';
import '../domain/printer_service.dart';

class BillingTerminalScreen extends ConsumerStatefulWidget {
  const BillingTerminalScreen({super.key});

  @override
  ConsumerState<BillingTerminalScreen> createState() => _BillingTerminalScreenState();
}

class _BillingTerminalScreenState extends ConsumerState<BillingTerminalScreen> {
  String? _selectedTableId;
  double _discountPercentage = 0.0;
  String _selectedPaymentMethod = 'CASH';
  bool _mobileShowCheckout = false;

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final tables = ref.watch(tableProvider);

    // Filter tables that have active orders (status OCCUPIED or BILLING)
    final billingTables = tables.where((t) => t.status == 'OCCUPIED' || t.status == 'BILLING').toList();

    final isTablet = MediaQuery.of(context).size.width > 600;

    // Reset selected table id if it is no longer in billingTables list (e.g. checked out)
    if (_selectedTableId != null && !billingTables.any((t) => t.id == _selectedTableId)) {
      _selectedTableId = null;
      _mobileShowCheckout = false;
    }

    // Select the first billing table by default on tablet if none selected
    if (isTablet && _selectedTableId == null && billingTables.isNotEmpty) {
      _selectedTableId = billingTables.first.id;
    }

    final selectedTable = _selectedTableId != null
        ? tables.firstWhere((t) => t.id == _selectedTableId, orElse: () => billingTables.first)
        : null;

    final activeOrder = selectedTable != null ? orderState.activeOrders[selectedTable.id] : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        leading: (!isTablet && _mobileShowCheckout)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _mobileShowCheckout = false;
                  });
                },
              )
            : null,
        title: Text(
          (!isTablet && _mobileShowCheckout && selectedTable != null)
              ? 'Billing: Table ${selectedTable.tableNumber}'
              : 'Cashier Billing Terminal',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
        ),
      ),
      body: billingTables.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_outlined, size: 64, color: Color(0xFF94A3B8)),
                  SizedBox(height: 16),
                  Text(
                    'No tables pending billing/checkout.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            )
          : (!isTablet && _mobileShowCheckout)
              ? (activeOrder != null && selectedTable != null
                  ? _buildCheckoutForm(context, selectedTable, activeOrder)
                  : const Center(child: Text('Order details not found.')))
              : Row(
                  children: [
                    // Left pane: Table Selector (On Tablet, it's the master pane. On Mobile, it's full screen)
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              color: const Color(0xFFF8F9FA),
                              child: Text(
                                'Active Tables (${billingTables.length})',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: billingTables.length,
                                itemBuilder: (context, index) {
                                  final table = billingTables[index];
                                  final isSelected = table.id == _selectedTableId;
                                  final tableOrder = orderState.activeOrders[table.id];
                                  return _buildTableCard(table, tableOrder, isSelected, isTablet);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Right pane: Checkout details (Only on Tablet side-by-side)
                    if (isTablet)
                      Expanded(
                        flex: 2,
                        child: activeOrder != null && selectedTable != null
                            ? _buildCheckoutForm(context, selectedTable, activeOrder)
                            : const Center(
                                child: Text(
                                  'Select an active table from the list to begin checkout.',
                                  style: TextStyle(color: Color(0xFF64748B)),
                                ),
                              ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildTableCard(TableModel table, OrderModel? order, bool isSelected, bool isTablet) {
    final hasBillingStatus = table.status == 'BILLING';
    final accentColor = hasBillingStatus ? const Color(0xFFE65100) : const Color(0xFF003893);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTableId = table.id;
            _discountPercentage = 0.0;
            if (!isTablet) {
              _mobileShowCheckout = true;
            }
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? accentColor.withAlpha(20) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? accentColor : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 6,
                    color: accentColor,
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        table.tableNumber,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Table ${table.tableNumber}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order != null
                              ? '${order.items.length} items • NPR ${order.subtotal.toStringAsFixed(2)}'
                              : 'No active items',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasBillingStatus
                            ? const Color(0xFFFFF3E0)
                            : const Color(0xFFEBF3FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        table.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutForm(BuildContext context, TableModel table, OrderModel order) {
    final double subtotal = order.subtotal;
    final double discountAmount = subtotal * (_discountPercentage / 100);
    final double taxableSubtotal = subtotal - discountAmount;
    final double serviceCharge = taxableSubtotal * 0.10; // 10% Service Charge
    final double vatAmount = (taxableSubtotal + serviceCharge) * 0.13; // 13% VAT
    final double grandTotal = taxableSubtotal + serviceCharge + vatAmount;

    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selected Table Bill Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Checkout: Table ${table.tableNumber}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Order: ${order.id.split('_').last} • Date: ${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _mockPrintReceipt(table, order, subtotal, discountAmount, serviceCharge, vatAmount, grandTotal),
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: const Text('Print Receipt'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE65100),
                    side: const BorderSide(color: Color(0xFFE65100)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          // Items List Summary (Receipt Card style)
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      color: const Color(0xFFF8F9FA),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('ITEM DESCRIPTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          Text('AMOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: order.items.length,
                        separatorBuilder: (context, index) => const Divider(
                          color: Color(0xFFF1F5F9),
                          thickness: 1,
                        ),
                        itemBuilder: (context, index) {
                          final item = order.items[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item.quantity} x ${item.menuItem.name}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (item.selectedModifiers.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          item.selectedModifiers.map((m) => m.name).join(', '),
                                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      if (item.notes.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Note: "${item.notes}"',
                                          style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Color(0xFFC8102E)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'NPR ${item.itemTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
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
            ),
          ),
          // Invoice summary & payment configuration
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    const Text('Discount:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildDiscountButton(0.0),
                        _buildDiscountButton(10.0),
                        _buildDiscountButton(15.0),
                        _buildCustomDiscountButton(),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                _buildSummaryLine('Subtotal', 'NPR ${subtotal.toStringAsFixed(2)}'),
                if (discountAmount > 0)
                  _buildSummaryLine(
                    'Discount (${_discountPercentage.toStringAsFixed(0)}%)',
                    '- NPR ${discountAmount.toStringAsFixed(2)}',
                    textColor: const Color(0xFFC8102E),
                  ),
                _buildSummaryLine('Service Charge (10%)', 'NPR ${serviceCharge.toStringAsFixed(2)}'),
                _buildSummaryLine('VAT (13%)', 'NPR ${vatAmount.toStringAsFixed(2)}'),
                const Divider(height: 16),
                _buildSummaryLine(
                  'Grand Total',
                  'NPR ${grandTotal.toStringAsFixed(2)}',
                  isBold: true,
                  fontSize: 18,
                  textColor: const Color(0xFFE65100),
                ),
                const SizedBox(height: 12),
                const Text('Payment Method:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPaymentMethodButton('CASH', Icons.money),
                    const SizedBox(width: 8),
                    _buildPaymentMethodButton('FONEPAY', Icons.qr_code),
                    const SizedBox(width: 8),
                    _buildPaymentMethodButton('CARD', Icons.credit_card),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _settleBill(table.id, grandTotal),
                  child: Text(
                    'Confirm & Settle NPR ${grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String title, String val, {bool isBold = false, double fontSize = 13, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color: textColor ?? const Color(0xFF64748B),
            ),
          ),
          Text(
            val,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.bold,
              fontSize: fontSize,
              color: textColor ?? const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountButton(double pct) {
    final isSelected = _discountPercentage == pct;
    return ChoiceChip(
      label: Text('${pct.toStringAsFixed(0)}%'),
      selected: isSelected,
      selectedColor: const Color(0xFFE65100),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF64748B),
        fontSize: 11,
      ),
      onSelected: (_) {
        setState(() {
          _discountPercentage = pct;
        });
      },
    );
  }

  Widget _buildCustomDiscountButton() {
    final hasCustom = _discountPercentage != 0.0 && _discountPercentage != 10.0 && _discountPercentage != 15.0;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: hasCustom ? Colors.white : const Color(0xFF64748B),
        backgroundColor: hasCustom ? const Color(0xFFE65100) : null,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        side: BorderSide(color: hasCustom ? const Color(0xFFE65100) : const Color(0xFFCBD5E1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: () => _promptManagerPin(),
      child: Text(
        hasCustom ? '${_discountPercentage.toStringAsFixed(0)}% (Custom)' : 'Custom',
        style: const TextStyle(fontSize: 11),
      ),
    );
  }

  void _promptManagerPin() {
    String pin = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manager PIN Override Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter Manager/Owner PIN to apply custom discounts.'),
            const SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              onChanged: (val) => pin = val,
              decoration: const InputDecoration(
                hintText: 'Enter 4-Digit PIN',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100)),
            onPressed: () {
              if (pin == '1111') {
                Navigator.pop(context);
                _applyCustomDiscountDialog();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid Manager PIN.')),
                );
              }
            },
            child: const Text('Authorize', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _applyCustomDiscountDialog() {
    double selectedPct = 0.0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Custom Discount %'),
        content: TextField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'e.g. 20', border: OutlineInputBorder()),
          onChanged: (val) {
            selectedPct = double.tryParse(val) ?? 0.0;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedPct >= 0 && selectedPct <= 100) {
                setState(() {
                  _discountPercentage = selectedPct;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodButton(String method, IconData icon) {
    final isSelected = _selectedPaymentMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF3E0) : Colors.white,
            border: Border.all(
              color: isSelected ? const Color(0xFFE65100) : const Color(0xFFCBD5E1),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFFE65100) : const Color(0xFF64748B)),
              const SizedBox(height: 4),
              Text(
                method,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: isSelected ? const Color(0xFFE65100) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _settleBill(String tableId, double total) {
    ref.read(orderProvider.notifier).settleOrder(tableId);
    setState(() {
      _selectedTableId = null;
      _mobileShowCheckout = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Table checked out successfully! Amount settled: NPR ${total.toStringAsFixed(2)}'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );
  }

  void _mockPrintReceipt(
    TableModel table,
    OrderModel order,
    double sub,
    double disc,
    double sc,
    double vat,
    double grand,
  ) {
    final receiptItems = order.items
        .map((i) => ReceiptItem(
              name: i.menuItem.name,
              quantity: i.quantity,
              totalPrice: i.itemTotal,
            ))
        .toList();

    PrinterService().showPrintPreviewDialog(
      context,
      brandName: "KATHMANDU CAFE & DINER",
      address: "Durbarmarg, Kathmandu",
      phone: "01-4412345",
      panNumber: "601234567",
      items: receiptItems,
      subTotal: sub - disc, // net subtotal
      serviceCharge: sc,
      vat: vat,
      grandTotal: grand,
      paymentMethod: _selectedPaymentMethod,
      cashierName: "Cashier Terminal",
    );
  }
}
