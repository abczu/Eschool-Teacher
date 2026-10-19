import 'package:eschool_saas_staff/data/models/leave/leaveSettings.dart';
import 'package:eschool_saas_staff/data/models/academic/sessionYear.dart';
import 'package:eschool_saas_staff/data/models/system/holiday.dart';
import 'package:eschool_saas_staff/data/repositories/academics/academicRepository.dart';
import 'package:eschool_saas_staff/data/repositories/leave/leaveRepository.dart';
import 'package:eschool_saas_staff/data/repositories/system/settingsRepository.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

abstract class LeaveSettingsAndSessionYearsState {}

/// Nama hari berbahasa Indonesia (index 0 = Senin), dipakai untuk judul
/// libur mingguan supaya tidak muncul "Sunday" dari daftar `weekDays`.
const List<String> _idWeekDayNames = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

class LeaveSettingsAndSessionYearsInitial
    extends LeaveSettingsAndSessionYearsState {}

class LeaveSettingsAndSessionYearsFetchInProgress
    extends LeaveSettingsAndSessionYearsState {}

class LeaveSettingsAndSessionYearsFetchSuccess
    extends LeaveSettingsAndSessionYearsState {
  final LeaveSettings leaveSettings;
  final List<SessionYear> sessionYears;
  final List<Holiday> holidays;

  LeaveSettingsAndSessionYearsFetchSuccess(
      {required this.leaveSettings,
      required this.sessionYears,
      this.holidays = const []});
}

class LeaveSettingsAndSessionYearsFetchFailure
    extends LeaveSettingsAndSessionYearsState {
  final String errorMessage;

  LeaveSettingsAndSessionYearsFetchFailure(this.errorMessage);
}

class LeaveSettingsAndSessionYearsCubit
    extends Cubit<LeaveSettingsAndSessionYearsState> {
  final LeaveRepository _leaveRepository = LeaveRepository();
  final AcademicRepository _settingsRepository = AcademicRepository();
  final SettingsRepository _systemRepository = SettingsRepository();

  LeaveSettingsAndSessionYearsCubit()
      : super(LeaveSettingsAndSessionYearsInitial());

  void getLeaveSettingsAndSessionYears() async {
    emit(LeaveSettingsAndSessionYearsFetchInProgress());
    try {
      final sessionYears = await _settingsRepository.getSessionYears();
      final leaveSettings = await _leaveRepository.getLeaveSettings();
      // Holidays API (tanggal merah) bersifat opsional: jangan blokir form
      // jika gagal, cukup pakai libur mingguan dari leave-settings.
      List<Holiday> holidays = [];
      try {
        holidays = await _systemRepository.getHolidays();
      } catch (_) {
        holidays = [];
      }
      emit(LeaveSettingsAndSessionYearsFetchSuccess(
          sessionYears: sessionYears,
          leaveSettings: leaveSettings,
          holidays: holidays));
    } catch (e) {
      // Gunakan ErrorMessageUtils untuk mengkonversi error teknis menjadi pesan yang ramah
      final userFriendlyMessage = ErrorMessageUtils.getReadableErrorMessage(e);
      emit(LeaveSettingsAndSessionYearsFetchFailure(userFriendlyMessage));

      // Log technical error untuk debugging (hanya untuk development)
      debugPrint(
          'Technical error in getLeaveSettingsAndSessionYears: ${ErrorMessageUtils.getTechnicalErrorMessage(e)}');
    }
  }

  SessionYear getCurrentSessionYear() {
    if (state is LeaveSettingsAndSessionYearsFetchSuccess) {
      return (state as LeaveSettingsAndSessionYearsFetchSuccess)
          .sessionYears
          .firstWhere((element) => element.isThisDefault());
    }
    return SessionYear.fromJson({});
  }

  ///[It will get the day number of the holiday Ex. if sunday and staurday is holiday then it will return 6,7 ]
  List<int> getHolidayWeekDays() {
    if (state is LeaveSettingsAndSessionYearsFetchSuccess) {
      List<String> holidayDays =
          (state as LeaveSettingsAndSessionYearsFetchSuccess)
                  .leaveSettings
                  .holiday
                  ?.split(",") ??
              <String>[];
      List<int> holidayWeekDays = [];
      for (var holidayDay in holidayDays) {
        holidayWeekDays.add(weekDays.indexOf(holidayDay.trim()) + 1);
      }

      return holidayWeekDays;
    }
    return [];
  }

  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime? _tryParseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final raw = value.trim();
    // Format utama BE: YYYY-MM-DD (WIB), dukung juga DD-MM-YYYY & ISO.
    try {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(raw)) {
        final normalized = raw.substring(0, 10);
        final parts = normalized.split('-');
        return DateTime(
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  /// Expand holidays API (start_date..end_date) menjadi tanggal + judul.
  Map<DateTime, String> getHolidayDatesWithTitle() {
    if (state is! LeaveSettingsAndSessionYearsFetchSuccess) return {};
    final holidays =
        (state as LeaveSettingsAndSessionYearsFetchSuccess).holidays;
    final Map<DateTime, String> result = {};
    for (final holiday in holidays) {
      final start = _tryParseDate(holiday.startDate);
      final end = _tryParseDate(holiday.endDate) ?? start;
      if (start == null || end == null) continue;
      final title = (holiday.title ?? '').trim().isEmpty
          ? 'Hari Libur'
          : holiday.title!.trim();
      DateTime cursor = _normalizeDate(start);
      final last = _normalizeDate(end);
      int guard = 0;
      while (!cursor.isAfter(last) && guard < 370) {
        result.putIfAbsent(cursor, () => title);
        cursor = cursor.add(const Duration(days: 1));
        guard++;
      }
    }
    return result;
  }

  bool isHolidayDate(DateTime date) {
    final normalized = _normalizeDate(date);
    if (getHolidayWeekDays().contains(normalized.weekday)) return true;
    return getHolidayDatesWithTitle().containsKey(normalized);
  }

  /// Judul libur untuk tanggal tersebut (nasional/sekolah dari API,
  /// atau "Libur Akhir Pekan (Hari)" untuk libur mingguan).
  String? getHolidayTitle(DateTime date) {
    final normalized = _normalizeDate(date);
    final fromApi = getHolidayDatesWithTitle()[normalized];
    if (fromApi != null) return fromApi;
    if (getHolidayWeekDays().contains(normalized.weekday)) {
      final dayName = _idWeekDayNames[normalized.weekday - 1];
      return 'Libur Akhir Pekan ($dayName)';
    }
    return null;
  }
}
