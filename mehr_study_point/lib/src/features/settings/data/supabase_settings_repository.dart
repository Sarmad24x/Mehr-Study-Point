import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

class SupabaseSettingsRepository implements SettingsRepository {
  final SupabaseClient _client;
  final String _table = 'app_settings';

  SupabaseSettingsRepository(this._client);

  @override
  Future<AppSettings> getSettings() async {
    try {
      final response = await _client.from(_table).select().eq('id', 1).single();
      return AppSettings.fromMap(response);
    } catch (e) {
      throw Exception('Failed to fetch settings: $e');
    }
  }

  @override
  Future<void> updateSettings(AppSettings settings) async {
    try {
      await _client.from(_table).update(settings.toMap()).eq('id', 1);
    } catch (e) {
      throw Exception('Failed to update settings: $e');
    }
  }
}
