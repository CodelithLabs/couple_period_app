import 'package:couple_period_app/features/insights/model/insight_summary.dart';
import 'package:couple_period_app/features/insights/service/insights_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final insightsServiceProvider = Provider<InsightsService>(
  (_) => InsightsService(),
);

final insightsProvider = FutureProvider<List<InsightSummary>>((ref) async {
  return ref.watch(insightsServiceProvider).loadInsights();
});
