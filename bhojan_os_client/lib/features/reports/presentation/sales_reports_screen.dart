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
    final isMobile = MediaQuery.of(context).size.width < 600;

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
              : _buildReportContent(state.report!, isMobile),
    );
  }

  Widget _buildReportContent(DashboardReport report, bool isMobile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Metrics Cards Row (Responsive)
          _buildMetricsSection(report, isMobile),
          const SizedBox(height: 24),

          // Weekly Trend Bar Chart
          _buildTrendSection(report),
          const SizedBox(height: 24),

          // Side-by-side details layout (Top Items & Payments)
          LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth > 700;
              if (isTablet) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTopSellingSection(report)),
                    const SizedBox(width: 20),
                    Expanded(child: _buildPaymentsSection(report)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildTopSellingSection(report),
                    const SizedBox(height: 24),
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

  Widget _buildMetricsSection(DashboardReport report, bool isMobile) {
    final list = [
      _buildMetricCard(
        title: "Today's Gross Sales",
        value: "Rs. ${report.totalSales.toStringAsFixed(2)}",
        icon: Icons.monetization_on_outlined,
        color: const Color(0xFF2E7D32),
        isMobile: isMobile,
      ),
      _buildMetricCard(
        title: 'Total Orders Placed',
        value: report.ordersCount.toString(),
        icon: Icons.shopping_bag_outlined,
        color: const Color(0xFF003893),
        isMobile: isMobile,
      ),
      _buildMetricCard(
        title: 'Average Order Value',
        value: "Rs. ${report.avgOrderValue.toStringAsFixed(2)}",
        icon: Icons.analytics_outlined,
        color: const Color(0xFFE65100),
        isMobile: isMobile,
      ),
    ];

    if (isMobile) {
      return Column(
        children: list.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: c,
        )).toList(),
      );
    }

    return Row(
      children: list.map((c) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: c,
        ),
      )).toList(),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isMobile,
  }) {
    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Sales Trend',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Gross receipts aggregated daily for the past 7 days.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF003893).withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'LAST 7 DAYS',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF003893)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (index) {
                    return Row(
                      children: [
                        SizedBox(
                          width: 50,
                          child: Text(
                            'Rs. ${(maxAmount * (1 - index / 3)).toInt()}',
                            style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8)),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color(0xFFF1F5F9),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                Positioned.fill(
                  left: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: report.weeklyTrend.map((point) {
                      final ratio = maxAmount > 0 ? point.amount / maxAmount : 0.0;
                      final barHeight = ratio * 160;

                      final parts = point.date.split('-');
                      final dateLabel = parts.length >= 3 ? "${parts[1]}/${parts[2]}" : point.date;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Rs.${point.amount.toInt()}',
                            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 24,
                            height: barHeight > 0 ? barHeight : 4.0,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF003893), Color(0xFF00ACC1)],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dateLabel,
                            style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final item = report.topSellingItems[index];
                final rank = index + 1;
                
                Color rankColor;
                Color rankBgColor;
                if (rank == 1) {
                  rankColor = const Color(0xFFD4AF37);
                  rankBgColor = const Color(0xFFFFFDF0);
                } else if (rank == 2) {
                  rankColor = const Color(0xFFC0C0C0);
                  rankBgColor = const Color(0xFFF8F8F8);
                } else if (rank == 3) {
                  rankColor = const Color(0xFFCD7F32);
                  rankBgColor = const Color(0xFFFFF9F5);
                } else {
                  rankColor = const Color(0xFF64748B);
                  rankBgColor = const Color(0xFFF1F5F9);
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: rankBgColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: rankColor.withAlpha(50), width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$rank',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: rankColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                      ),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Settlement Splits', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          const Text('Breakdown of income collections by payment channels.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 24),
          _buildPaymentProgressRow('CASH', report.payments['CASH'] ?? 0.0, report.totalSales, const Color(0xFF2E7D32)),
          const SizedBox(height: 16),
          _buildPaymentProgressRow('FONEPAY', report.payments['FONEPAY'] ?? 0.0, report.totalSales, const Color(0xFFE65100)),
          const SizedBox(height: 16),
          _buildPaymentProgressRow('CARD', report.payments['CARD'] ?? 0.0, report.totalSales, const Color(0xFF003893)),
          const SizedBox(height: 16),
          _buildPaymentProgressRow('CREDIT', report.payments['CREDIT'] ?? 0.0, report.totalSales, const Color(0xFF8E24AA)),
        ],
      ),
    );
  }

  Widget _buildPaymentProgressRow(String method, double amount, double total, Color indicatorColor) {
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
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
