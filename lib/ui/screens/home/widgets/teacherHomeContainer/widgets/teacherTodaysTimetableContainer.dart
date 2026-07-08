import 'dart:math';

import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/cubits/academics/classesCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/teacherMyTimetableCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/homeContainer/widgets/contentTitleWithViewmoreButton.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/teacherHomeContainer/widgets/roundedBackgroundContainer.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/teacherAddAttendanceSubjectScreen.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/academics/timetableSlotContainer.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// 1. Tambahkan enum untuk status waktu
enum TimeSlotStatus { before, during, after }

class TeacherTodaysTimetableContainer extends StatefulWidget {
  const TeacherTodaysTimetableContainer({super.key});

  @override
  State<TeacherTodaysTimetableContainer> createState() =>
      _TeacherTodaysTimetableContainerState();
}

class _TeacherTodaysTimetableContainerState
    extends State<TeacherTodaysTimetableContainer>
    with TickerProviderStateMixin {
  final int itemsToShowWithoutExpansion = 2;
  int appearDisappearAnimationDurationMilliseconds = 600;

  final ValueNotifier<bool> _isExpanded = ValueNotifier(false);

  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _iconAngleAnimation;

  @override
  void initState() {
    _controller = AnimationController(
      duration:
          Duration(milliseconds: appearDisappearAnimationDurationMilliseconds),
      vsync: this,
    );
    _iconAngleAnimation = Tween<double>(begin: 0, end: 180)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastLinearToSlowEaseIn,
    );

    // Initialize with today's data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // The cubit is now provided by the parent
        context.read<TeacherMyTimetableCubit>().getTeacherMyTimetable();
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _isExpanded.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _toggleContainer() {
    if (_animation.status != AnimationStatus.completed) {
      _controller.forward();
      _isExpanded.value = true;
    } else {
      _controller.animateBack(
        0,
        duration: Duration(
            milliseconds: appearDisappearAnimationDurationMilliseconds),
        curve: Curves.fastLinearToSlowEaseIn,
      );
      _isExpanded.value = false;
    }
  }

  String getClassSectionName(int? classSectionId) {
    if (classSectionId == null) return "-";

    final classState = context.read<ClassesCubit>().state;

    if (classState is ClassesFetchSuccess) {
      try {
        // Check in primary classes first
        final primaryClass = classState.primaryClasses.firstWhere(
          (element) => element.id == classSectionId,
          orElse: () => ClassSection(id: 0, name: "", classId: 0),
        );

        if (primaryClass.id != 0) {
          return primaryClass.name ?? "";
        }

        // Then check in other classes
        final classSection = classState.classes.firstWhere(
          (element) => element.id == classSectionId,
          orElse: () => ClassSection(id: 0, name: "-", classId: 0),
        );

        return classSection.name ?? "";
      } catch (e) {
        return "-";
      }
    }
    return "-";
  }

  bool isCurrentTimeWithinSlot(String startTime, String endTime) {
    DateTime now = DateTime.now();
    DateTime start = DateFormat('HH:mm:ss').parse(startTime);
    DateTime end = DateFormat('HH:mm:ss').parse(endTime);

    // Convert start and end times to today's date
    DateTime todayStart = DateTime(
        now.year, now.month, now.day, start.hour, start.minute, start.second);
    DateTime todayEnd = DateTime(
        now.year, now.month, now.day, end.hour, end.minute, end.second);

    return now.isAfter(todayStart) && now.isBefore(todayEnd);
  }

  bool isCurrentTimeBeforeSlot(String startTime) {
    DateTime now = DateTime.now();
    DateTime start = DateFormat('HH:mm:ss').parse(startTime);

    DateTime todayStart = DateTime(
        now.year, now.month, now.day, start.hour, start.minute, start.second);

    return now.isBefore(todayStart);
  }

  // 2. Tambahkan fungsi untuk mendapatkan status waktu
  TimeSlotStatus getTimeSlotStatus(String startTime, String endTime) {
    DateTime now = DateTime.now();
    DateTime start = DateFormat('HH:mm:ss').parse(startTime);
    DateTime end = DateFormat('HH:mm:ss').parse(endTime);

    DateTime todayStart = DateTime(
        now.year, now.month, now.day, start.hour, start.minute, start.second);
    DateTime todayEnd = DateTime(
        now.year, now.month, now.day, end.hour, end.minute, end.second);

    if (now.isBefore(todayStart)) {
      return TimeSlotStatus.before;
    } else if (now.isAfter(todayEnd)) {
      return TimeSlotStatus.after;
    } else {
      return TimeSlotStatus.during;
    }
  }

  Widget _viewMoreViewLessContainer(
      {required bool isExpanded, required Function() onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomTextContainer(
              textKey: isExpanded ? viewLessKey : viewMoreKey,
              style: GoogleFonts.poppins(
                color: const Color(0xFF800020),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            AnimatedBuilder(
              animation: _iconAngleAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: (pi * _iconAngleAnimation.value) / 180,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF800020),
                    size: 20,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClassesCubit, ClassesState>(
      builder: (context, classState) {
        return BlocBuilder<TeacherMyTimetableCubit, TeacherMyTimetableState>(
          builder: (context, state) {
            if (state is TeacherMyTimetableFetchSuccess) {
              // Always filter for today's date
              final today = DateTime.now();
              final todayDayName = weekDays[today.weekday - 1].toLowerCase();

              // Filter for today's slots and sort by start time
              final slots = state.timeTableSlots.where((element) {
                return element.day?.toLowerCase() == todayDayName;
              }).toList()
                ..sort((a, b) {
                  // Sort by start time
                  final timeA = a.startTime ?? '';
                  final timeB = b.startTime ?? '';
                  return timeA.compareTo(timeB);
                });

              if (slots.isEmpty) {
                return Container(
                  margin: const EdgeInsets.symmetric(
                      vertical: 20.0, horizontal: 16.0),
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 48.0,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12.0),
                      Text(
                        'Tidak Ada Jadwal Hari Ini',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Anda tidak memiliki jadwal mengajar untuk hari ini',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(top: 15),
                child: RoundedBackgroundContainer(
                  child: Column(
                    children: [
                      const ContentTitleWithViewMoreButton(
                          showViewMoreButton: false,
                          contentTitleKey: todaysTimetableKey),
                      const SizedBox(
                        height: 15,
                      ),
                      ...List.generate(
                        slots.length > itemsToShowWithoutExpansion
                            ? itemsToShowWithoutExpansion
                            : slots.length,
                        (index) {
                          final timeTableSlot = slots[index];
                          final isWithinSlot = isCurrentTimeWithinSlot(
                              timeTableSlot.startTime ?? "",
                              timeTableSlot.endTime ?? "");

                          // Update GestureDetector onTap
                          return GestureDetector(
                            onTap: () {
                              if (timeTableSlot.classSectionId != null) {
                                final classState =
                                    context.read<ClassesCubit>().state;
                                if (classState is ClassesFetchSuccess) {
                                  final classSection = [
                                    ...classState.primaryClasses,
                                    ...classState.classes
                                  ].firstWhere(
                                    (element) =>
                                        element.id ==
                                        timeTableSlot.classSectionId,
                                    orElse: () => ClassSection(
                                        id: 0, name: "-", classId: 0),
                                  );

                                  // Navigasi ke mode view-only untuk status before dan after
                                  Get.toNamed(
                                    Routes.teacherAddAttendanceSubjectScreen,
                                    arguments: TeacherAddAttendanceSubjectScreen
                                        .buildArguments(
                                      classSection: classSection,
                                      timeTableSlot: timeTableSlot,
                                    ),
                                  );
                                }
                              } else {
                                Utils.showSnackBar(
                                  message: "Tidak ada ID bagian kelas",
                                  context: context,
                                );
                              }
                            },
                            child: TimetableSlotContainer(
                              note: timeTableSlot.note ?? "",
                              endTime: timeTableSlot.endTime ?? "",
                              startTime: timeTableSlot.startTime ?? "",
                              subjectName: timeTableSlot.subject?.name ?? "-",
                              isForClass: false,
                              classSectionName: getClassSectionName(
                                  timeTableSlot.classSectionId),
                              backgroundColor: isWithinSlot
                                  ? Theme.of(context).scaffoldBackgroundColor
                                  : Colors.grey[300],
                            ),
                          );
                        },
                      ),
                      if (slots.length > itemsToShowWithoutExpansion)
                        SizeTransition(
                          sizeFactor: _animation,
                          axis: Axis.vertical,
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 20,
                              ),
                              ...List.generate(
                                slots.length > itemsToShowWithoutExpansion
                                    ? slots.length - itemsToShowWithoutExpansion
                                    : 0,
                                (index) {
                                  final timeTableSlot = slots[
                                      index + itemsToShowWithoutExpansion];
                                  final isWithinSlot = isCurrentTimeWithinSlot(
                                      timeTableSlot.startTime ?? "",
                                      timeTableSlot.endTime ?? "");

                                  return GestureDetector(
                                    onTap: () {
                                      if (timeTableSlot.classSectionId !=
                                          null) {
                                        final classState =
                                            context.read<ClassesCubit>().state;
                                        if (classState
                                            is ClassesFetchSuccess) {
                                          final classSection = [
                                            ...classState.primaryClasses,
                                            ...classState.classes
                                          ].firstWhere(
                                            (element) =>
                                                element.id ==
                                                timeTableSlot.classSectionId,
                                            orElse: () => ClassSection(
                                                id: 0, name: "-", classId: 0),
                                          );

                                          TimeSlotStatus status =
                                              getTimeSlotStatus(
                                            timeTableSlot.startTime ?? "",
                                            timeTableSlot.endTime ?? "",
                                          );

                                          switch (status) {
                                            case TimeSlotStatus.before:
                                              Utils.showSnackBar(
                                                message:
                                                    "Anda belum memasuki jam pelajaran.",
                                                context: context,
                                              );
                                              break;
                                            case TimeSlotStatus.after:
                                              break;
                                            case TimeSlotStatus.during:
                                              // Lanjutkan ke halaman pengisian
                                              Get.toNamed(
                                                Routes
                                                    .teacherAddAttendanceSubjectScreen,
                                                arguments:
                                                    TeacherAddAttendanceSubjectScreen
                                                        .buildArguments(
                                                  classSection: classSection,
                                                  timeTableSlot: timeTableSlot,
                                                ),
                                              );
                                              return;
                                          }

                                          // Navigasi ke mode view-only untuk status before dan after
                                          Get.toNamed(
                                            Routes
                                                .teacherAddAttendanceSubjectScreen,
                                            arguments:
                                                TeacherAddAttendanceSubjectScreen
                                                    .buildArguments(
                                              classSection: classSection,
                                              timeTableSlot: timeTableSlot,
                                            ),
                                          );
                                        }
                                      } else {
                                        Utils.showSnackBar(
                                          message: "Tidak ada ID bagian kelas",
                                          context: context,
                                        );
                                      }
                                    },
                                    child: TimetableSlotContainer(
                                      note: timeTableSlot.note ?? "",
                                      endTime: timeTableSlot.endTime ?? "",
                                      startTime: timeTableSlot.startTime ?? "",
                                      subjectName:
                                          timeTableSlot.subject?.name ?? "-",
                                      isForClass: false,
                                      classSectionName: getClassSectionName(
                                          timeTableSlot.classSectionId),
                                      backgroundColor: isWithinSlot
                                          ? Theme.of(context)
                                              .scaffoldBackgroundColor
                                          : Colors.grey[300],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      if (slots.length > itemsToShowWithoutExpansion)
                        ValueListenableBuilder(
                          valueListenable: _isExpanded,
                          builder: (context, isExpanded, _) {
                            return _viewMoreViewLessContainer(
                                isExpanded: isExpanded,
                                onTap: () {
                                  _toggleContainer();
                                });
                          },
                        ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox();
          },
        );
      },
    );
  }
}
