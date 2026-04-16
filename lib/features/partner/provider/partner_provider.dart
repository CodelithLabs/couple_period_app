import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_period_app/features/auth/provider/auth_provider.dart';
import 'package:couple_period_app/features/partner/model/partner_summary.dart';
import 'package:couple_period_app/features/onboarding/provider/onboarding_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final partnerSummaryProvider = StreamProvider<PartnerSummary?>((ref) async* {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) {
    yield null;
    return;
  }

  final firestore = ref.watch(firestoreProvider);
  final userDocStream = firestore.collection('users').doc(uid).snapshots();

  await for (final userDoc in userDocStream) {
    final userData = userDoc.data();
    final partnerId = userData?['partnerId'] as String?;
    if (partnerId == null || partnerId.trim().isEmpty) {
      yield null;
      continue;
    }

    final partnerDoc = await firestore.collection('users').doc(partnerId).get();
    final partnerData = partnerDoc.data();
    final partnerName = partnerData?['name'] as String?;

    String? partnerMood;
    try {
      final moodLog = await firestore
          .collection('users')
          .doc(partnerId)
          .collection('moods')
          .doc('journal')
          .collection('logs')
          .orderBy('loggedAt', descending: true)
          .limit(1)
          .get();
      if (moodLog.docs.isNotEmpty) {
        partnerMood = moodLog.docs.first.data()['emoji'] as String?;
      }
    } catch (_) {
      partnerMood = null;
    }

    String? partnerPhase;
    try {
      final cycleSettings = await firestore
          .collection('users')
          .doc(partnerId)
          .collection('cycles')
          .doc('settings')
          .get();
      if (cycleSettings.exists) {
        final data = cycleSettings.data();
        final cycleLength = (data?['cycleLength'] as int?) ?? 28;
        final periodDuration = (data?['periodDuration'] as int?) ?? 5;
        final ts = data?['lastPeriodDate'] as Timestamp?;
        if (ts != null) {
          final lastPeriod = ts.toDate().toLocal();
          final now = DateTime.now();
          final day = DateTime(now.year, now.month, now.day);
          final base = DateTime(
            lastPeriod.year,
            lastPeriod.month,
            lastPeriod.day,
          );
          final cycleDay = day.difference(base).inDays % cycleLength;
          if (cycleDay < periodDuration) {
            partnerPhase = 'Menstrual';
          } else if (cycleDay >= cycleLength - 6) {
            partnerPhase = 'Luteal';
          } else {
            partnerPhase = 'Follicular/Ovulation';
          }
        }
      }
    } catch (_) {
      partnerPhase = null;
    }

    final supportTip = _buildSupportTip(partnerMood, partnerPhase);

    yield PartnerSummary(
      partnerId: partnerId,
      partnerName: partnerName,
      currentPhase: partnerPhase,
      latestMoodEmoji: partnerMood,
      supportTip: supportTip,
    );
  }
});

final partnerVisibilityProvider = StreamProvider<Map<String, bool>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) {
    return Stream.value({'shareCyclePhase': true, 'shareMood': true});
  }
  return ref
      .watch(partnerInviteServiceProvider)
      .watchPartnerVisibility(userId: uid);
});

final partnerActionsControllerProvider =
    StateNotifierProvider<PartnerActionsController, AsyncValue<void>>((ref) {
      return PartnerActionsController(ref);
    });

class PartnerActionsController extends StateNotifier<AsyncValue<void>> {
  PartnerActionsController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<void> disconnectCouple() async {
    final uid = _ref.read(authStateProvider).value?.uid;
    if (uid == null) {
      throw Exception('No authenticated user found.');
    }
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return _ref
          .read(partnerInviteServiceProvider)
          .disconnectCouple(userId: uid);
    });
    state = result;
    if (result.hasError) {
      throw result.error!;
    }
    _ref.invalidate(partnerSummaryProvider);
  }

  Future<void> updateVisibility({
    required bool shareCyclePhase,
    required bool shareMood,
  }) async {
    final uid = _ref.read(authStateProvider).value?.uid;
    if (uid == null) {
      throw Exception('No authenticated user found.');
    }

    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return _ref
          .read(partnerInviteServiceProvider)
          .setPartnerVisibility(
            userId: uid,
            shareCyclePhase: shareCyclePhase,
            shareMood: shareMood,
          );
    });
    state = result;
    if (result.hasError) {
      throw result.error!;
    }
    _ref.invalidate(partnerVisibilityProvider);
  }
}

String _buildSupportTip(String? mood, String? phase) {
  if (mood == '😢' || mood == '😭' || mood == '😞') {
    return 'Your partner may need comfort today. Send a kind check-in and offer practical help.';
  }
  if (mood == '😰' || mood == '😡') {
    return 'Keep communication gentle today. Ask what support would feel most helpful.';
  }
  if (phase == 'Menstrual' || phase == 'Luteal') {
    return 'This phase can feel heavy. Small acts of care (warm drink, rest reminders) can help a lot.';
  }
  return 'Stay connected with a short supportive message today.';
}
