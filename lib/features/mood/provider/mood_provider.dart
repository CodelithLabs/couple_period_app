import 'package:couple_period_app/features/auth/provider/auth_provider.dart';
import 'package:couple_period_app/features/mood/model/mood_log.dart';
import 'package:couple_period_app/features/mood/service/mood_service.dart';
import 'package:couple_period_app/features/onboarding/provider/onboarding_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final moodServiceProvider = Provider<MoodService>((ref) {
  return MoodService(ref.watch(firestoreProvider));
});

final moodRecentLogsProvider = StreamProvider<List<MoodLog>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) {
    return Stream.value(const []);
  }
  return ref.watch(moodServiceProvider).watchRecentMoods(userId: uid);
});

final moodTodayProvider = Provider<MoodLog?>((ref) {
  final logs = ref.watch(moodRecentLogsProvider).valueOrNull ?? const [];
  if (logs.isEmpty) {
    return null;
  }
  final now = DateTime.now();
  for (final log in logs) {
    if (log.loggedAt.year == now.year &&
        log.loggedAt.month == now.month &&
        log.loggedAt.day == now.day) {
      return log;
    }
  }
  return null;
});

final moodSupportSuggestionProvider = FutureProvider<String>((ref) async {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) {
    return 'Sign in to get personalized support suggestions.';
  }
  return ref.watch(moodServiceProvider).buildSupportSuggestion(userId: uid);
});

final moodLogControllerProvider =
    StateNotifierProvider<MoodLogController, AsyncValue<void>>((ref) {
      return MoodLogController(ref);
    });

class MoodLogController extends StateNotifier<AsyncValue<void>> {
  MoodLogController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<void> addMood({required String emoji, String? note}) async {
    final uid = _ref.read(authStateProvider).value?.uid;
    if (uid == null) {
      throw Exception('No authenticated user found.');
    }

    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return _ref
          .read(moodServiceProvider)
          .addMood(userId: uid, emoji: emoji, note: note);
    });
    state = result;

    if (result.hasError) {
      throw result.error!;
    }

    _ref.invalidate(moodRecentLogsProvider);
    _ref.invalidate(moodSupportSuggestionProvider);
  }
}
