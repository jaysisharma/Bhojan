import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shift_notifier.dart';

class ShiftManagementScreen extends ConsumerStatefulWidget {
  const ShiftManagementScreen({super.key});

  @override
  ConsumerState<ShiftManagementScreen> createState() => _ShiftManagementScreenState();
}

class _ShiftManagementScreenState extends ConsumerState<ShiftManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _openFormKey = GlobalKey<FormState>();
  final _closeFormKey = GlobalKey<FormState>();
  
  final _openingCashController = TextEditingController(text: '0.00');
  final _actualCashController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Refresh shift list on startup
    Future.microtask(() {
      ref.read(shiftProvider.notifier).fetchActiveShift();
      ref.read(shiftProvider.notifier).fetchShiftHistory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _openingCashController.dispose();
    _actualCashController.dispose();
    super.dispose();
  }

  void _handleOpenShift() async {
    if (_openFormKey.currentState!.validate()) {
      final amt = double.tryParse(_openingCashController.text) ?? 0.0;
      final success = await ref.read(shiftProvider.notifier).openShift(amt);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift started and Cash Drawer opened successfully.')),
        );
      }
    }
  }

  void _handleCloseShift() async {
    if (_closeFormKey.currentState!.validate()) {
      final amt = double.tryParse(_actualCashController.text) ?? 0.0;
      final success = await ref.read(shiftProvider.notifier).closeShift(amt);
      if (mounted && success) {
        _actualCashController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift ended and Cash Drawer closed successfully.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shiftState = ref.watch(shiftProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Shift & Cash Drawer', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003893))),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF003893),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF003893),
          tabs: const [
            Tab(text: 'Current Shift', icon: Icon(Icons.wallet_outlined)),
            Tab(text: 'Shift Ledger History', icon: Icon(Icons.history_toggle_off_outlined)),
          ],
        ),
      ),
      body: shiftState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActiveShiftTab(shiftState),
                _buildHistoryTab(shiftState),
              ],
            ),
    );
  }

  Widget _buildActiveShiftTab(ShiftState state) {
    final active = state.activeShift;

    if (active == null) {
      // Drawer is closed, prompt opening shift
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Form(
              key: _openFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.no_accounts_outlined, size: 64, color: Color(0xFFC8102E)),
                  const SizedBox(height: 16),
                  const Text(
                    'Cash Drawer is Closed',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'To log orders and print invoice settlements, cashier must open a new work shift and record starting drawer cash balance.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _openingCashController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Opening Cash Balance (NPR) *',
                      prefixIcon: const Icon(Icons.money_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter starting cash amount';
                      if (double.tryParse(val) == null) return 'Enter a valid numeric value';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  if (state.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: Color(0xFFC8102E), fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ElevatedButton(
                    onPressed: _handleOpenShift,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003893),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Open Drawer & Start Shift', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Active shift dashboard
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Form(
            key: _closeFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_open, color: Color(0xFF2E7D32), size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Shift Active & Open', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                          Text('Cash drawer transactions permitted.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildInfoRow('Opened By', active.openedByName ?? 'Unknown'),
                const Divider(),
                _buildInfoRow('Opened At', active.openedAt.toLocal().toString().substring(0, 16)),
                const Divider(),
                _buildInfoRow('Starting Cash', 'NPR ${active.openingCash.toStringAsFixed(2)}'),
                const SizedBox(height: 32),
                const Text(
                  'End Shift Operations',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Before closing the cash drawer, please count the total physical cash in register drawer and record below.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _actualCashController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Actual Drawer Closing Cash (NPR) *',
                    prefixIcon: const Icon(Icons.wallet_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter closing counted cash';
                    if (double.tryParse(val) == null) return 'Enter valid decimal value';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Color(0xFFC8102E), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ElevatedButton(
                  onPressed: _handleCloseShift,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8102E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Close Drawer & End Shift', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(ShiftState state) {
    final history = state.history;

    if (history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_outlined, size: 64, color: Color(0xFF94A3B8)),
            SizedBox(height: 16),
            Text('No shift history ledger records found.', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final shift = history[index];
        final isMatch = (shift.cashDiff ?? 0.0) == 0.0;
        final diffColor = isMatch ? const Color(0xFF2E7D32) : const Color(0xFFC8102E);

        return Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: shift.status == 'OPEN' ? const Color(0xFFE8F5E9) : const Color(0xFFECEFF1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    shift.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: shift.status == 'OPEN' ? const Color(0xFF2E7D32) : const Color(0xFF455A64),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Opened: ${shift.openedAt.toLocal().toString().substring(0, 16)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Cashier: ${shift.openedByName ?? "Unknown"}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildHistoryDetailsRow('Opening Cash', 'NPR ${shift.openingCash.toStringAsFixed(2)}'),
                    _buildHistoryDetailsRow('Expected Cash', 'NPR ${(shift.expectedCash ?? 0.0).toStringAsFixed(2)}'),
                    _buildHistoryDetailsRow('Actual Closing Cash', 'NPR ${(shift.actualCash ?? 0.0).toStringAsFixed(2)}'),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Cash Difference', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        Text(
                          '${(shift.cashDiff ?? 0.0) >= 0 ? "+" : ""}NPR ${(shift.cashDiff ?? 0.0).toStringAsFixed(2)}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: diffColor),
                        ),
                      ],
                    ),
                    if (shift.closedAt != null) ...[
                      const SizedBox(height: 12),
                      _buildHistoryDetailsRow('Closed By', shift.closedByName ?? 'Unknown'),
                      _buildHistoryDetailsRow('Closed At', shift.closedAt!.toLocal().toString().substring(0, 16)),
                    ]
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryDetailsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
