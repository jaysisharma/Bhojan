import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

class DashboardReport {
  final double totalSales;
  final int ordersCount;
  final double avgOrderValue;
  final Map<String, double> payments;
  final List<TopSellingItem> topSellingItems;
  final List<TrendPoint> weeklyTrend;

  DashboardReport({
    required this.totalSales,
    required this.ordersCount,
    required this.avgOrderValue,
    required this.payments,
    required this.topSellingItems,
    required this.weeklyTrend,
  });

  factory DashboardReport.fromJson(Map<String, dynamic> json) {
    final payData = json['payments'] as Map<String, dynamic>;
    final payments =
        payData.map((key, val) => MapEntry(key, double.parse(val.toString())));

    final topData = json['topSellingItems'] as List<dynamic>;
    final topSellingItems = topData
        .map((x) => TopSellingItem.fromJson(x as Map<String, dynamic>))
        .toList();

    final trendData = json['weeklyTrend'] as List<dynamic>;
    final weeklyTrend = trendData
        .map((x) => TrendPoint.fromJson(x as Map<String, dynamic>))
        .toList();

    return DashboardReport(
      totalSales: double.parse(json['totalSales'].toString()),
      ordersCount: json['ordersCount'] as int,
      avgOrderValue: double.parse(json['avgOrderValue'].toString()),
      payments: payments,
      topSellingItems: topSellingItems,
      weeklyTrend: weeklyTrend,
    );
  }
}

class TopSellingItem {
  final String name;
  final int quantity;

  TopSellingItem({required this.name, required this.quantity});

  factory TopSellingItem.fromJson(Map<String, dynamic> json) {
    return TopSellingItem(
      name: json['name'] as String,
      quantity: json['quantity'] as int,
    );
  }
}

class TrendPoint {
  final String date;
  final double amount;

  TrendPoint({required this.date, required this.amount});

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      date: json['date'] as String,
      amount: double.parse(json['amount'].toString()),
    );
  }
}

class ReportsState {
  final DashboardReport? report;
  final bool isLoading;
  final String? errorMessage;

  ReportsState({
    this.report,
    required this.isLoading,
    this.errorMessage,
  });

  ReportsState copyWith({
    DashboardReport? Function()? report,
    bool? isLoading,
    String? Function()? errorMessage,
  }) {
    return ReportsState(
      report: report != null ? report() : this.report,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class ReportsNotifier extends StateNotifier<ReportsState> {
  final Ref _ref;

  ReportsNotifier(this._ref) : super(ReportsState(isLoading: false)) {
    fetchDashboardReport();
  }

  Future<void> fetchDashboardReport() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final response = await _ref.read(dioProvider).get('/reports/dashboard');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final r = DashboardReport.fromJson(data as Map<String, dynamic>);
        state = state.copyWith(report: () => r, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final reportsProvider =
    StateNotifierProvider<ReportsNotifier, ReportsState>((ref) {
  return ReportsNotifier(ref);
});
