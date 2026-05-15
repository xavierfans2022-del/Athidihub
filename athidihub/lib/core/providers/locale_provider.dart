import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localePreferenceKey = 'selected_app_locale';

final localePreferenceProvider = AsyncNotifierProvider<LocalePreferenceController, Locale?>(
  LocalePreferenceController.new,
);

class LocalePreferenceController extends AsyncNotifier<Locale?> {
  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('te'),
  ];

  @override
  Future<Locale?> build() async {
    final preferences = await SharedPreferences.getInstance();
    final savedCode = preferences.getString(_localePreferenceKey);
    if (savedCode == null || savedCode.isEmpty) {
      return null;
    }

    return _localeFromCode(savedCode);
  }

  Future<void> setLocale(Locale? locale) async {
    final preferences = await SharedPreferences.getInstance();
    if (locale == null) {
      await preferences.remove(_localePreferenceKey);
    } else {
      await preferences.setString(_localePreferenceKey, locale.languageCode);
    }

    state = AsyncData(locale);
  }

  Locale? _localeFromCode(String code) {
    for (final supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == code) {
        return supportedLocale;
      }
    }
    return null;
  }
}