import 'package:couple_period_app/features/settings/model/app_settings.dart';

class SettingsService {
  Future<AppSettings> loadSettings() async {
    return const AppSettings(notificationsEnabled: true);
  }
}
