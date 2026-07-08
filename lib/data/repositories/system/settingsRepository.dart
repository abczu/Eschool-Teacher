import 'package:eschool_saas_staff/data/models/system/holiday.dart';
import 'package:eschool_saas_staff/utils/system/api.dart';
import 'package:eschool_saas_staff/utils/system/appLanguages.dart';
import 'package:eschool_saas_staff/utils/system/hiveBoxKeys.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsRepository {
  Future<void> setOnBoardingScreen(bool value) async {
    Hive.box(settingsBoxKey).put(showOnBoardingScreenKey, value);
  }

  // Future<List<SystemSettingData>> getSystemSettings() async {
  //   try {
  //     final result =
  //         await Api.get(url: Api.getSystemSettings, useAuthToken: false);
  //     return ((result['data'] ?? []) as List)
  //         .map((systemSetting) =>
  //             SystemSettingData.fromJson(Map.from(systemSetting ?? {})))
  //         .toList();
  //   } catch (e) {
  //     throw ApiException(e.toString());
  //   }
  // }

  bool getOnBoardingScreen() {
    return Hive.box(settingsBoxKey).get(showOnBoardingScreenKey) ?? true;
  }

  Future<void> setCurrentLanguageCode(String value) async {
    Hive.box(settingsBoxKey).put(currentLanguageCodeKey, value);
  }

  String getCurrentLanguageCode() {
    return Hive.box(settingsBoxKey).get(currentLanguageCodeKey) ??
        defaultLanguageCode;
  }

  Future<void> setVibrationEnabled(bool value) async {
    Hive.box(settingsBoxKey).put(vibrationEnabledKey, value);
  }

  bool getVibrationEnabled() {
    return Hive.box(settingsBoxKey).get(vibrationEnabledKey) ?? true;
  }

  Future<void> setThemeMode(String value) async {
    Hive.box(settingsBoxKey).put(themeModeKey, value);
  }

  String getThemeMode() {
    return Hive.box(settingsBoxKey).get(themeModeKey) ?? "system";
  }

  Future<List<Holiday>> getHolidays() async {
    try {
      final result = await Api.get(url: Api.getHolidays);

      return ((result['data'] ?? []) as List)
          .map((holiday) => Holiday.fromJson(holiday ?? {}))
          .toList();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<String> getSetting(String type) async {
    try {
      final response =
          await Api.get(url: Api.getSettings, queryParameters: {"type": type});

      final result = response['data'];
      if (result is Map && result.containsKey('value')) {
        return result['value'].toString();
      }
      return result.toString();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> getAppSettings() async {
    try {
      final result = await Api.get(
          url: Api.getSettings, queryParameters: {"type": "app_settings"});
      return Map.from(result['data'] ?? {});
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}

