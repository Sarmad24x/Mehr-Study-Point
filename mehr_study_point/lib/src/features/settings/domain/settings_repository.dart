import 'app_settings.dart';

abstract class SettingsRepository {
  /// Fetches the global application settings.
  Future<AppSettings> getSettings();

  /// Updates the global application settings.
  Future<void> updateSettings(AppSettings settings);
}
