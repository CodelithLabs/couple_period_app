import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_period_app/features/auth/provider/auth_provider.dart';
import 'package:couple_period_app/features/onboarding/model/onboarding_profile.dart';
import 'package:couple_period_app/features/onboarding/service/onboarding_service.dart';
import 'package:couple_period_app/features/partner/service/partner_invite_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreProvider = Provider<FirebaseFirestore>((_) {
  return FirebaseFirestore.instance;
});

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService(ref.watch(firestoreProvider));
});

final partnerInviteServiceProvider = Provider<PartnerInviteService>((ref) {
  return PartnerInviteService(ref.watch(firestoreProvider));
});

final onboardingDraftProvider =
    StateNotifierProvider<OnboardingDraftNotifier, OnboardingProfile>((_) {
      return OnboardingDraftNotifier();
    });

final onboardingStepProvider = StateProvider<int>((_) => 0);

final onboardingCompletionProvider = StreamProvider.family<bool, String>((
  ref,
  userId,
) {
  return ref.watch(onboardingServiceProvider).watchCompletion(userId);
});

final onboardingSaveControllerProvider =
    StateNotifierProvider<OnboardingSaveController, AsyncValue<void>>((ref) {
      return OnboardingSaveController(ref);
    });

class OnboardingDraftNotifier extends StateNotifier<OnboardingProfile> {
  OnboardingDraftNotifier() : super(OnboardingProfile.initial());

  void setName(String name) => state = state.copyWith(name: name.trim());

  void setGender(AppGender gender) => state = state.copyWith(gender: gender);

  void setMode(AppMode mode) => state = state.copyWith(mode: mode);

  void setRelationshipStatus(String value) {
    final trimmed = value.trim();
    state = state.copyWith(
      relationshipStatus: trimmed.isEmpty ? null : trimmed,
    );
  }

  void setLastPeriodDate(DateTime date) {
    state = state.copyWith(lastPeriodDate: date);
  }

  void setCycleLength(int value) {
    state = state.copyWith(cycleLength: value.clamp(20, 45));
  }

  void setPeriodDuration(int value) {
    state = state.copyWith(periodDuration: value.clamp(2, 10));
  }

  void setSymptomsEnabled(bool value) {
    state = state.copyWith(symptomsEnabled: value);
  }

  void setMoodEnabled(bool value) {
    state = state.copyWith(moodEnabled: value);
  }

  void setNotificationsEnabled(bool value) {
    state = state.copyWith(notificationsEnabled: value);
  }

  void setPartnerId(String? partnerId) {
    state = state.copyWith(partnerId: partnerId);
  }

  void setGeneratedInviteCode(String? inviteCode) {
    state = state.copyWith(generatedInviteCode: inviteCode);
  }
}

class OnboardingSaveController extends StateNotifier<AsyncValue<void>> {
  OnboardingSaveController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<void> save(String userId) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final firebaseUser = _ref.read(authStateProvider).value;
      if (firebaseUser == null) {
        throw Exception('No authenticated user found.');
      }

      final profile = _ref
          .read(onboardingDraftProvider)
          .copyWith(onboardingCompleted: true);

      await _ref
          .read(onboardingServiceProvider)
          .saveProfile(
            userId: userId,
            email: firebaseUser.email ?? '',
            profile: profile,
          );
    });
  }
}
