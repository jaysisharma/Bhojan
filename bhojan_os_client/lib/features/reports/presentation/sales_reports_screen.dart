import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'reports_notifier.dart';

class SalesReportsScreen extends ConsumerStatefulWidget {
  const SalesReportsScreen({super.key});

  @override
  ConsumerState<SalesReportsScreen> createState() => _SalesReportsScreenState();
}

class _SalesReportsScreenState extends ConsumerState<SalesReportsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(reportsProvider.notifier).fetchDashboardReport());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Sales & Reports', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003893))),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          IconButton(
            onPressed: () => ref.read(reportsProvider.notifier).fetchDashboardReport(),
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: state.isLoading && state.report == null
          ? const Center(child: CircularProgressIndicator())
          : state.report == null
              ? const Center(
                  child: Text('Failed to load reports data.', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
                )
              : _buildReportContent(state.report!),
    );
  }

  Widget _buildReportContent(DashboardReport report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Metrics Cards Row
          _buildMetricsSection(report),
          const SizedBox(height: 32),

          // Weekly Trend Bar Chart
          _buildTrendSection(report),
          const SizedBox(height: 32),

          // Side-by-side details layout (Top Items & Payments)
          LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth > 700;
              if (isTablet) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTopSellingSection(report)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildPaymentsSection(report)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildTopSellingSection(report),
                    const SizedBox(height: 32),
                    _buildPaymentsSection(report),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection(DashboardReport report) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: "Today's Gross Sales",
            value: "NPR ${report.totalSales.toStringAsFixed(2)}",
            icon: Icons.monetization_on_outlined,
            color: const Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: 'Total Orders Placed',
            value: report.ordersCount.toString(),
            icon: Icons.shopping_bag_outlined,
            color: const Color(0xFF003893),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: 'Average Order Value',
            value: "NPR ${report.avgOrderValue.toStringAsFixed(2)}",
            icon: Icons.analytics_outlined,
            color: const Color(0xFFE65100),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              Icon(icon, color: color, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendSection(DashboardReport report) {
    final maxAmount = report.weeklyTrend.fold<double>(1.0, (prev, point) => point.amount > prev ? point.amount : prev);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly Sales Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          const Text('Total gross receipts aggregated daily for the past 7 days.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: report.weeklyTrend.map((point) {
                final ratio = point.amount / maxAmount;
                final barHeight = ratio * 150; // Cap at max height
                
                // Date formatting (MM/DD)
                final parts = point.date.split('-');
                final dateLabel = parts.length >= 3 ? "${parts[1]}/${parts[2]}" : point.date;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Rs.${point.amount.toInt()}',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 32,
                      height: barHeight > 0 ? barHeight : 4.0, // Minimum bar height to show active indicator
                      decoration: BoxDecoration(
                        color: const Color(0xFF003893),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateLabel,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                    ),
                  ],
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTopSellingSection(DashboardReport report) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Selling Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          const Text('Highest frequency dishes ordered today.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 24),
          if (report.topSellingItems.isEmpty)
            const Text('No orders processed yet today.', style: TextStyle(color: Color(0xFF64748B)))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: report.topSellingItems.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = report.topSellingItems[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${item.quantity} orders',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentsSection(DashboardReport report) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Settlement Splits', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          const Text('Breakdown of income collections by payment channels.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 24),
          _buildPaymentProgressRow('CASH', report.payments['CASH'] ?? 0.0, report.totalSales),
          const SizedBox(height: 16),
          _buildPaymentProgressRow('FONEPAY', report.payments['FONEPAY'] ?? 0.0, report.totalSales),
          const SizedBox(height: 16),
          _buildPaymentProgressRow('CARD', report.payments['CARD'] ?? 0.0, report.totalSales),
          const SizedBox(height: 16),
          _buildPaymentProgressRow('CREDIT', report.payments['CREDIT'] ?? 0.0, report.totalSales),
        ],
      ),
    );
  }

  Widget _buildPaymentProgressRow(String method, double amount, double total) {
    final ratio = total > 0 ? amount / total : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(method, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            Text('Rs.${amount.toStringAsFixed(2)} (${(ratio * 100).toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF003893)),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
