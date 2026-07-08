import 'package:eschool_saas_staff/data/repositories/system/settingsRepository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeState {
  final ThemeMode themeMode;
  ThemeState(this.themeMode);
}

class ThemeCubit extends Cubit<ThemeState> {
  final SettingsRepository _settingsRepository;

  ThemeCubit(this._settingsRepository)
      : super(ThemeState(_getThemeModeFromValue(_settingsRepository.getThemeMode())));

  static ThemeMode _getThemeModeFromValue(String value) {
    if (value == "light") {
      return ThemeMode.light;
    }
    if (value == "dark") {
      return ThemeMode.dark;
    }
    return ThemeMode.system;
  }

  void changeTheme(ThemeMode themeMode) {
    String value = "system";
    if (themeMode == ThemeMode.light) {
      value = "light";
    } else if (themeMode == ThemeMode.dark) {
      value = "dark";
    }
    _settingsRepository.setThemeMode(value);
    emit(ThemeState(themeMode));
  }

  bool isDarkMode() {
    return state.themeMode == ThemeMode.dark;
  }
}
