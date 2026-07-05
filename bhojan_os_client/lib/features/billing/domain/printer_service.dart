import 'dart:convert';
import 'package:flutter/material.dart';

class PrinterService {
  List<int> generateEscPosReceipt({
    required String brandName,
    required String address,
    required String phone,
    required String panNumber,
    required List<ReceiptItem> items,
    required double subTotal,
    required double serviceCharge,
    required double vat,
    required double grandTotal,
    required String paymentMethod,
    required String cashierName,
  }) {
    final bytes = <int>[];

    // 1. Initialize printer: ESC @
    bytes.addAll([0x1B, 0x40]);

    // 2. Alignment Centered: ESC a 1
    bytes.addAll([0x1B, 0x61, 0x01]);

    // 3. Double-height text for brand name: ESC ! 16
    bytes.addAll([0x1B, 0x21, 0x10]);
    bytes.addAll(utf8.encode("$brandName\n"));

    // Normal text size: ESC ! 0
    bytes.addAll([0x1B, 0x21, 0x00]);
    bytes.addAll(utf8.encode("$address\n"));
    bytes.addAll(utf8.encode("Tel: $phone\n"));
    bytes.addAll(utf8.encode("PAN: $panNumber\n"));
    bytes.addAll(utf8.encode("--------------------------------\n"));

    // 4. Left alignment for items: ESC a 0
    bytes.addAll([0x1B, 0x61, 0x00]);
    bytes.addAll(utf8.encode("QTY  ITEM                 PRICE\n"));
    bytes.addAll(utf8.encode("--------------------------------\n"));

    for (final item in items) {
      final nameStr = item.name.length > 18
          ? item.name.substring(0, 18)
          : item.name.padRight(18);
      final qtyStr = item.quantity.toString().padRight(4);
      final priceStr = item.totalPrice.toStringAsFixed(2).padLeft(8);
      bytes.addAll(utf8.encode("$qtyStr $nameStr $priceStr\n"));
    }

    bytes.addAll(utf8.encode("--------------------------------\n"));

    // 5. Right alignment for totals summary: ESC a 2
    bytes.addAll([0x1B, 0x61, 0x02]);
    bytes.addAll(utf8.encode("Subtotal: Rs.${subTotal.toStringAsFixed(2)}\n"));
    bytes.addAll(utf8.encode(
        "Service Charge (10%): Rs.${serviceCharge.toStringAsFixed(2)}\n"));
    bytes.addAll(utf8.encode("VAT (13%): Rs.${vat.toStringAsFixed(2)}\n"));
    bytes.addAll(
        utf8.encode("Grand Total: Rs.${grandTotal.toStringAsFixed(2)}\n"));
    bytes.addAll(utf8.encode("--------------------------------\n"));

    // 6. Centered footer: ESC a 1
    bytes.addAll([0x1B, 0x61, 0x01]);
    bytes.addAll(utf8.encode("Payment: $paymentMethod\n"));
    bytes.addAll(utf8.encode("Cashier: $cashierName\n"));
    bytes.addAll(utf8.encode("Thank you for dining with us!\n\n\n"));

    // 7. Cut paper: GS V 1
    bytes.addAll([0x1D, 0x56, 0x01]);

    return bytes;
  }

  void showPrintPreviewDialog(
    BuildContext context, {
    required String brandName,
    required String address,
    required String phone,
    required String panNumber,
    required List<ReceiptItem> items,
    required double subTotal,
    required double serviceCharge,
    required double vat,
    required double grandTotal,
    required String paymentMethod,
    required String cashierName,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.print_outlined, color: Color(0xFF003893)),
            SizedBox(width: 8),
            Text('Thermal Receipt Ticket Preview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Container(
          width: 320,
          color: const Color(0xFFFFFFE0),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(brandName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'monospace')),
                Text(address,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                Text("Tel: $phone",
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                Text("PAN: $panNumber",
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                const Text("--------------------------------",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'monospace')),
                const Text("QTY  ITEM                 PRICE",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        fontSize: 12)),
                const Text("--------------------------------",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'monospace')),
                ...items.map((item) {
                  final nameStr = item.name.length > 18
                      ? item.name.substring(0, 18)
                      : item.name.padRight(18);
                  final qtyStr = item.quantity.toString().padRight(4);
                  final priceStr =
                      item.totalPrice.toStringAsFixed(2).padLeft(8);
                  return Text("$qtyStr $nameStr $priceStr",
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 12));
                }),
                const Text("--------------------------------",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'monospace')),
                Text("Subtotal: Rs.${subTotal.toStringAsFixed(2)}",
                    textAlign: TextAlign.right,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                Text(
                    "Service Charge (10%): Rs.${serviceCharge.toStringAsFixed(2)}",
                    textAlign: TextAlign.right,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                Text("VAT (13%): Rs.${vat.toStringAsFixed(2)}",
                    textAlign: TextAlign.right,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                Text("Grand Total: Rs.${grandTotal.toStringAsFixed(2)}",
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                const Text("--------------------------------",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'monospace')),
                Text("Payment: $paymentMethod",
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                Text("Cashier: $cashierName",
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                const Text("Thank you for dining with us!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class ReceiptItem {
  final String name;
  final int quantity;
  final double totalPrice;

  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.totalPrice,
  });
}
