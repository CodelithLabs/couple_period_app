import 'package:couple_period_app/features/settings/model/app_settings.dart';
import 'package:couple_period_app/features/settings/model/backend_health_report.dart';
import 'package:couple_period_app/features/settings/service/backend_health_service.dart';
import 'package:couple_period_app/features/settings/service/settings_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsServiceProvider = Provider<SettingsService>(
  (_) => SettingsService(),
);

final settingsProvider = FutureProvider<AppSettings>((ref) async {
  return ref.watch(settingsServiceProvider).loadSettings();
});

final backendHealthServiceProvider = Provider<BackendHealthService>((ref) {
  return BackendHealthService(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

final backendHealthControllerProvider =
    StateNotifierProvider<
      BackendHealthController,
      AsyncValue<BackendHealthReport?>
    >((ref) {
      return BackendHealthController(ref);
    });

class BackendHealthController
    extends StateNotifier<AsyncValue<BackendHealthReport?>> {
  BackendHealthController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<void> runChecks() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return _ref.read(backendHealthServiceProvider).runChecks();
    });
  }
}
