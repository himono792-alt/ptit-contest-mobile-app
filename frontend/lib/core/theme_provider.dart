/// Theme mode provider — Phase 2 Sprint 2 Step 1 (2026-05-06).
///
/// State: ThemeMode (system / light / dark).
/// Persist qua SharedPreferences key `theme_mode`.
/// Default: ThemeMode.system (theo OS setting Android/iOS).
///
/// Usage:
/// ```dart
/// final themeMode = ref.watch(themeProvider);
/// MaterialApp(themeMode: themeMode, ...);
///
/// ref.read(themeProvider.notifier).setMode(ThemeMode.dark);
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'theme_mode';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  // Khởi tạo với system, sau đó load từ SharedPreferences async
  ThemeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kThemeModeKey);
    state = _parseMode(raw);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, _serializeMode(mode));
  }

  static ThemeMode _parseMode(String? raw) {
    switch (raw) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _serializeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return 'light';
      case ThemeMode.dark: return 'dark';
      case ThemeMode.system: return 'system';
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

/// Helper: human-readable label cho UI radio.
String themeModeLabel(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system: return 'Theo hệ thống';
    case ThemeMode.light: return 'Sáng';
    case ThemeMode.dark: return 'Tối';
  }
}
