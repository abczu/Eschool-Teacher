import 'package:eschool_saas_staff/data/models/system/holiday.dart';
import 'package:eschool_saas_staff/data/models/leave/leaveDetails.dart';
import 'package:eschool_saas_staff/data/models/auth/permissionDetails.dart';
import 'package:eschool_saas_staff/data/models/auth/userDetails.dart';
import 'package:eschool_saas_staff/data/repositories/leave/leaveRepository.dart';
import 'package:eschool_saas_staff/data/repositories/auth/permissionRepository.dart';
import 'package:eschool_saas_staff/data/repositories/system/settingsRepository.dart';
import 'package:eschool_saas_staff/data/repositories/system/statisticsRepository.dart';
import 'package:eschool_saas_staff/data/repositories/teacherRepository.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

abstract class HomeScreenDataState {}

class HomeScreenDataInitial extends HomeScreenDataState {}

class HomeScreenDataFetchInProgress extends HomeScreenDataState {}

class HomeScreenDataFetchSuccess extends HomeScreenDataState {
  final int totalStudents;
  final int totalStaffs;
  final int totalTeachers;
  final int totalLeaveRequests;
  final List<UserDetails> teachers;
  final List<LeaveDetails> todaysLeave;
  final List<LeaveDetails> tomorrowLeave;
  final List<LeaveDetails> upcomingLeave;
  final List<PermissionDetails> todaysPermission;
  final List<Holiday> holidays;

  HomeScreenDataFetchSuccess({
    required this.totalLeaveRequests,
    required this.teachers,
    required this.totalTeachers,
    required this.totalStaffs,
    required this.holidays,
    required this.totalStudents,
    required this.todaysLeave,
    required this.tomorrowLeave,
    required this.upcomingLeave,
    required this.todaysPermission,
  });

  HomeScreenDataFetchSuccess copyWith({
    int? totalLeaveRequests,
    int? totalStaffs,
    int? totalTeachers,
    int? totalStudents,
    List<UserDetails>? teachers,
    List<LeaveDetails>? todaysLeave,
    List<LeaveDetails>? tomorrowLeave,
    List<LeaveDetails>? upcomingLeave,
    List<PermissionDetails>? todaysPermission,
    List<Holiday>? holidays,
  }) {
    return HomeScreenDataFetchSuccess(
      totalLeaveRequests: totalLeaveRequests ?? this.totalLeaveRequests,
      teachers: teachers ?? this.teachers,
      totalTeachers: totalTeachers ?? this.totalTeachers,
      totalStaffs: totalStaffs ?? this.totalStaffs,
      holidays: holidays ?? this.holidays,
      totalStudents: totalStudents ?? this.totalStudents,
      todaysLeave: todaysLeave ?? this.todaysLeave,
      tomorrowLeave: tomorrowLeave ?? this.tomorrowLeave,
      upcomingLeave: upcomingLeave ?? this.upcomingLeave,
      todaysPermission: todaysPermission ?? this.todaysPermission,
    );
  }
}

class HomeScreenDataFetchFailure extends HomeScreenDataState {
  final String errorMessage;

  HomeScreenDataFetchFailure(this.errorMessage);
}

class HomeScreenDataCubit extends Cubit<HomeScreenDataState> {
  final StatisticsRepository _statisticsRepository = StatisticsRepository();
  final TeacherRepository _teacherRepository = TeacherRepository();
  final LeaveRepository _leaveRepository = LeaveRepository();
  final PermissionRepository _permissionRepository = PermissionRepository();
  final SettingsRepository _settingsRepository = SettingsRepository();

  HomeScreenDataCubit() : super(HomeScreenDataInitial());

  void getHomeScreenData({
    required bool listTeacherTimetablePermission,
    required bool isTeacher,
    required bool holidayModuleEnabled,
    required bool staffLeaveModuleEnabled,
    bool isSilent = false,
  }) async {
    try {
      if (!isSilent) {
        emit(HomeScreenDataFetchInProgress());
      }

      // Fetch statistics defensively
      var totalLeaveRequests = 0;
      var totalTeachers = 0;
      var totalStaffs = 0;
      var totalStudents = 0;
      try {
        final statisticsDetails =
            await _statisticsRepository.getSystemStatistics();
        totalLeaveRequests = statisticsDetails.totalLeaveRequests;
        totalTeachers = statisticsDetails.totalTeachers;
        totalStaffs = statisticsDetails.totalStaffs;
        totalStudents = statisticsDetails.totalStudents;
        debugPrint("✅ Statistics fetched: L:$totalLeaveRequests, T:$totalTeachers, S:$totalStaffs, Std:$totalStudents");
      } catch (e) {
        debugPrint("❌ Statistics fetch failed: $e");
      }

      // Fetch teachers defensively
      List<UserDetails> teachers = [];
      if (listTeacherTimetablePermission) {
        try {
          teachers = await _teacherRepository.getTeachers();
          debugPrint("✅ Teachers fetched successfully: ${teachers.length}");
          // Prioritaskan jumlah dari daftar asli jika berhasil dimuat
          if (teachers.isNotEmpty) {
            totalTeachers = teachers.length;
          }
        } catch (e) {
          debugPrint("❌ Teachers fetch failed: $e");
        }
      }

      // Proactively fetch pending leave requests count if it's 0 but module is enabled
      if (staffLeaveModuleEnabled && totalLeaveRequests == 0) {
        try {
          final pendingLeaves = await _leaveRepository.getLeaveRequests();
          totalLeaveRequests = pendingLeaves.length;
          debugPrint("✅ Pending leaves fetched as fallback: $totalLeaveRequests");
        } catch (e) {
          debugPrint("❌ Pending leaves fetch failed: $e");
        }
      }

      // Fetch leaves defensively - Today
      List<LeaveDetails> todaysLeave = [];
      if (staffLeaveModuleEnabled) {
        try {
          todaysLeave = await _leaveRepository.getLeaves(
              leaveDayType: LeaveDayType.today);
          debugPrint("✅ Today's leaves fetched successfully");
        } catch (e) {
          debugPrint("❌ Today's leaves fetch failed: $e");
        }
      }

      // Fetch leaves defensively - Tomorrow
      List<LeaveDetails> tomorrowLeave = [];
      if (staffLeaveModuleEnabled) {
        try {
          tomorrowLeave = await _leaveRepository.getLeaves(
              leaveDayType: LeaveDayType.tomorrow);
          debugPrint("✅ Tomorrow's leaves fetched successfully");
        } catch (e) {
          debugPrint("❌ Tomorrow's leaves fetch failed: $e");
        }
      }

      // Fetch leaves defensively - Upcoming
      List<LeaveDetails> upcomingLeave = [];
      if (staffLeaveModuleEnabled) {
        try {
          upcomingLeave = await _leaveRepository.getLeaves(
              leaveDayType: LeaveDayType.upcoming);
          debugPrint("✅ Upcoming leaves fetched successfully");
        } catch (e) {
          debugPrint("❌ Upcoming leaves fetch failed: $e");
        }
      }

      // Fetch permissions defensively
      List<PermissionDetails> todaysPermission = [];
      if (staffLeaveModuleEnabled) {
        try {
          todaysPermission = await _permissionRepository.getPermission(
              leaveDayType: LeaveDayType.today);
          debugPrint("✅ Today's permissions fetched successfully");
        } catch (e) {
          debugPrint("❌ Today's permissions fetch failed: $e");
        }
      }

      // Fetch holidays defensively
      List<Holiday> holidays = [];
      if (holidayModuleEnabled) {
        try {
          holidays = await _settingsRepository.getHolidays();
          debugPrint("✅ Holidays fetched successfully");
        } catch (e) {
          debugPrint("❌ Holidays fetch failed: $e");
        }
      }

      emit(HomeScreenDataFetchSuccess(
          holidays: holidays,
          todaysLeave: todaysLeave,
          tomorrowLeave: tomorrowLeave,
          upcomingLeave: upcomingLeave,
          todaysPermission: todaysPermission,
          teachers: teachers,
          totalLeaveRequests: totalLeaveRequests,
          totalTeachers: totalTeachers,
          totalStaffs: totalStaffs,
          totalStudents: totalStudents));
    } catch (e) {
      debugPrint("⛔ [HomeScreenDataCubit] UNEXPECTED ERROR: $e");
      emit(HomeScreenDataFetchFailure(e.toString()));
    }
  }

  int getTotalStudents() {
    if (state is HomeScreenDataFetchSuccess) {
      return (state as HomeScreenDataFetchSuccess).totalStudents;
    }
    return 0;
  }

  void updateLeaveRequest({required int totalLeaveRequests}) {
    if (state is HomeScreenDataFetchSuccess) {
      emit((state as HomeScreenDataFetchSuccess)
          .copyWith(totalLeaveRequests: totalLeaveRequests));
    }
  }

  int getTotalLeaveRequests() {
    if (state is HomeScreenDataFetchSuccess) {
      return (state as HomeScreenDataFetchSuccess).totalLeaveRequests;
    }
    return 0;
  }

  int getTotalStaffs() {
    if (state is HomeScreenDataFetchSuccess) {
      return (state as HomeScreenDataFetchSuccess).totalStaffs;
    }
    return 0;
  }

  int getTotalTeachers() {
    if (state is HomeScreenDataFetchSuccess) {
      return (state as HomeScreenDataFetchSuccess).totalTeachers;
    }
    return 0;
  }

  List<UserDetails> getTeachers() {
    if (state is HomeScreenDataFetchSuccess) {
      return (state as HomeScreenDataFetchSuccess).teachers;
    }
    return [];
  }

  List<LeaveDetails> getTodayLeaves() {
    if (state is HomeScreenDataFetchSuccess) {
      return (state as HomeScreenDataFetchSuccess).todaysLeave;
    }
    return [];
  }

  List<LeaveDetails> getTomorrowLeaves() {
    if (state is HomeScreenDataFetchSuccess) {
      return (state as HomeScreenDataFetchSuccess).tomorrowLeave;
    }
    return [];
  }

  List<LeaveDetails> getUpcomingLeaves() {
    if (state is HomeScreenDataFetchSuccess) {
      return (state as HomeScreenDataFetchSuccess).upcomingLeave;
    }
    return [];
  }

  List<PermissionDetails> getTodayPermission() {
    if (state is HomeScreenDataFetchSuccess) {
      return (state as HomeScreenDataFetchSuccess).todaysPermission;
    }
    return [];
  }

  List<Holiday> getHolidays() {
    if (state is HomeScreenDataFetchSuccess) {
      return (state as HomeScreenDataFetchSuccess).holidays;
    }
    return [];
  }
}
