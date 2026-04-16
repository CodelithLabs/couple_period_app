import 'package:couple_period_app/features/cycle/model/cycle_snapshot.dart';
import 'package:couple_period_app/features/cycle/service/cycle_service.dart';
import 'package:couple_period_app/features/auth/provider/auth_provider.dart';
import 'package:couple_period_app/features/onboarding/provider/onboarding_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cycleServiceProvider = Provider<CycleService>((ref) {
  return CycleService(ref.watch(firestoreProvider));
});

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.uid;
});

final cycleSnapshotProvider = FutureProvider<CycleSnapshot>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    throw Exception('No authenticated user found.');
  }
  return ref.watch(cycleServiceProvider).getCycleSnapshot(userId: userId);
});

final cycleLogControllerProvider =
    StateNotifierProvider<CycleLogController, AsyncValue<void>>((ref) {
      return CycleLogController(ref);
    });

class CycleLogController extends StateNotifier<AsyncValue<void>> {
  CycleLogController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<void> logPeriod({
    required DateTime startDate,
    DateTime? endDate,
    required int painLevel,
    required String flowLevel,
    String? note,
  }) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      throw Exception('No authenticated user found.');
    }

    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return _ref
          .read(cycleServiceProvider)
          .logPeriodEntry(
            userId: userId,
            startDate: startDate,
            endDate: endDate,
            painLevel: painLevel,
            flowLevel: flowLevel,
            note: note,
          );
    });
    state = result;

    if (result.hasError) {
      throw result.error!;
    }

    _ref.invalidate(cycleSnapshotProvider);
  }
}
