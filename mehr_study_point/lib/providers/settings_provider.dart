import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_providers.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, Map<String, dynamic>>((ref) {
  return SettingsNotifier(ref);
});

class SettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  final Ref _ref;
  SettingsNotifier(this._ref) : super({
    'opening_time': '08:00 AM',
    'closing_time': '10:00 PM',
    'fine_rate': 50,
  }) {
    _loadSettings();
  }

  static const _boxName = 'settingsBox';

  Future<void> _loadSettings() async {
    final box = _ref.read(hiveServiceProvider).getBox(_boxName);
    final opening = box.get('opening_time', defaultValue: '08:00 AM');
    final closing = box.get('closing_time', defaultValue: '10:00 PM');
    final fineRate = box.get('fine_rate', defaultValue: 50);
    state = {
      'opening_time': opening,
      'closing_time': closing,
      'fine_rate': fineRate,
    };
  }

  Future<void> updateOperatingHours(String opening, String closing) async {
    final box = _ref.read(hiveServiceProvider).getBox(_boxName);
    await box.put('opening_time', opening);
    await box.put('closing_time', closing);
    state = {
      ...state,
      'opening_time': opening,
      'closing_time': closing,
    };
  }

  Future<void> updateFineRate(int rate) async {
    final box = _ref.read(hiveServiceProvider).getBox(_boxName);
    await box.put('fine_rate', rate);
    state = {
      ...state,
      'fine_rate': rate,
    };
  }
}
