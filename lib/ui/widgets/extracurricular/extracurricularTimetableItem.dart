import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool_saas_staff/data/models/extracurricular/extracurricularTimetable.dart';
import 'package:eschool_saas_staff/data/models/extracurricular/extracurricularTimetableEntry.dart';
import 'package:eschool_saas_staff/data/models/extracurricular/extracurricular.dart';
import 'package:eschool_saas_staff/ui/screens/extracurricular/createExtracurricularTimetableScreen.dart';
import 'package:eschool_saas_staff/cubits/extracurricularTimetable/extracurricularTimetableCubit.dart';
import 'package:eschool_saas_staff/data/repositories/extracurricular/extracurricularTimetableRepository.dart';
import 'package:eschool_saas_staff/data/repositories/extracurricular/extracurricularRepository.dart';

class ExtracurricularTimetableItem extends StatelessWidget {
  final ExtracurricularTimetable item;
  final String selectedDay;
  final VoidCallback? onRefresh;

  const ExtracurricularTimetableItem({
    super.key,
    required this.item,
    required this.selectedDay,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final schedule = item.getScheduleForDay(selectedDay) ?? '-';
    debugPrint('🔍 Raw schedule data: "$schedule"');
    final timeData = _parseScheduleTime(schedule);
    debugPrint('🔍 Parsed timeData: $timeData');
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = isDark ? const Color(0xFFE53935) : const Color(0xFF8B1F41);

    return Container(
      margin: const EdgeInsets.only(top: 10.0, bottom: 10.0),
      height: 150,
      child: Row(
        children: [
          // Time section (20% width)
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimeText(timeData['startTime'] ?? '', context),
                Container(
                  height: 60,
                  width: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                _buildTimeText(timeData['endTime'] ?? '', context),
              ],
            ),
          ),

          SizedBox(width: MediaQuery.of(context).size.width * 0.05),

          // Content section (75% width)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).cardColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with title and actions
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ekstrakurikuler',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.extracurricularName ?? 'Unnamed',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Action menu (three dots)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: isDark ? Colors.white70 : Colors.grey.shade600,
                          size: 20,
                        ),
                        offset: const Offset(-10, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                        color: isDark ? Theme.of(context).cardColor : Colors.white,
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editTimetable(context);
                          } else if (value == 'delete') {
                            _showDeleteConfirmation(context);
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.edit_rounded,
                                  color: Colors.blue,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Edit Jadwal',
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.grey.shade800,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete_rounded,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Hapus Jadwal',
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.grey.shade800,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Schedule info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Theme.of(context).cardColor : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark 
                            ? Colors.white.withValues(alpha: 0.08) 
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      '${timeData['startTime']} - ${timeData['endTime']}',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeText(String time, BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        time.isEmpty ? '-' : _formatTimeString(time),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : Colors.grey.shade700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatTimeString(String time) {
    debugPrint('🕐 Formatting time: "$time"');
    try {
      // Handle different time formats
      if (time.contains(':')) {
        final parts = time.split(':');
        debugPrint('🕐 Time parts: $parts');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);

          // Format as HH:MM
          final formatted =
              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
          debugPrint('🕐 Formatted result: "$formatted"');
          return formatted;
        }
      }
      debugPrint('🕐 No colon found, returning original: "$time"');
      return time;
    } catch (e) {
      debugPrint('❌ Error formatting time: $time, error: $e');
      return time;
    }
  }

  void _editTimetable(BuildContext context) async {
    // Fetch fresh extracurricular data
    List<Extracurricular>? extracurriculars;

    try {
      final extracurricularRepo = ExtracurricularRepository();
      extracurriculars = await extracurricularRepo.getExtracurriculars();
      debugPrint('✅ Fetched ${extracurriculars.length} extracurriculars for edit');
    } catch (e) {
      debugPrint('❌ Error fetching extracurriculars for edit: $e');
      // Create a single extracurricular from current item as fallback
      extracurriculars = [
        Extracurricular(
          id: item.id ?? 0,
          name: item.extracurricularName ?? 'Unnamed',
          description: '',
          coachId: 0,
          coachName: '',
          createdAt: '',
          updatedAt: '',
        )
      ];
    }

    // Create ExtracurricularTimetableEntry from current item
    final schedule = item.getScheduleForDay(selectedDay) ?? '-';
    final timeData = _parseScheduleTime(schedule);

    final entry = ExtracurricularTimetableEntry(
      id: item.id,
      extracurricularId: item.id?.toString(),
      extracurricularName: item.extracurricularName,
      day: selectedDay,
      startTime: timeData['startTime'] ?? '',
      endTime: timeData['endTime'] ?? '',
    );

    final result = await Get.to(() => BlocProvider(
          create: (context) => ExtracurricularTimetableCubit(
            ExtracurricularTimetableRepository(),
          ),
          child: CreateExtracurricularTimetableScreen(
            existingEntry: entry,
            extracurriculars: extracurriculars,
          ),
        ));

    if (result == true && onRefresh != null) {
      onRefresh!();
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryMaroon = isDark ? const Color(0xFFE53935) : const Color(0xffd22f3c);
    final Color lightMaroon = isDark ? const Color(0xFFEF5350) : const Color(0xffd22f3c);
    const Color softCream = Color(0xFFF5E6D3);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Theme.of(context).cardColor,
                      Theme.of(context).cardColor,
                    ]
                  : [
                      Colors.white,
                      softCream.withValues(alpha: 0.3),
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primaryMaroon.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryMaroon, lightMaroon],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryMaroon.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Hapus Jadwal',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryMaroon,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tindakan ini tidak dapat dibatalkan',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.03) : softCream.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryMaroon.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.school_rounded,
                                color: primaryMaroon,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ekstrakurikuler',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.extracurricularName ?? 'Unnamed',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: primaryMaroon,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                color: primaryMaroon,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getDayInIndonesian(selectedDay),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Apakah Anda yakin ingin menghapus jadwal ini secara permanen?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: TextButton.styleFrom(
                            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                            foregroundColor: isDark ? Colors.white : Colors.grey.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Delete button
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryMaroon, lightMaroon],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: primaryMaroon.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(dialogContext);
                              _resetTimetable(context, true);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: const Center(
                              child: Text(
                                'Hapus',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetTimetable(BuildContext context, bool permanent) async {
    if (item.id != null) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Use repository directly instead of cubit
        final repository = ExtracurricularTimetableRepository();
        await repository.resetTimetableEntry(item.id!, permanent: permanent);

        // Close loading dialog
        if (context.mounted) {
          Navigator.pop(context);
        }

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(permanent
                  ? 'Jadwal berhasil dihapus permanen'
                  : 'Jadwal berhasil direset'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Refresh the list
        if (onRefresh != null) {
          onRefresh!();
        }
      } catch (e) {
        // Close loading dialog if still open
        if (context.mounted) {
          Navigator.pop(context);
        }

        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getDayInIndonesian(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return 'Senin';
      case 'tuesday':
        return 'Selasa';
      case 'wednesday':
        return 'Rabu';
      case 'thursday':
        return 'Kamis';
      case 'friday':
        return 'Jumat';
      case 'saturday':
        return 'Sabtu';
      case 'sunday':
        return 'Minggu';
      default:
        return day;
    }
  }

  Map<String, String> _parseScheduleTime(String schedule) {
    debugPrint('🕐 Parsing schedule: "$schedule"');

    if (schedule == '-' || schedule.isEmpty || schedule == 'null') {
      return {'startTime': '', 'endTime': ''};
    }

    try {
      // Remove any extra whitespace and normalize
      schedule = schedule.trim();

      // Handle various separators and formats
      List<String> separators = [' - ', '-', ' – ', '–', ' to ', ' TO '];

      for (String separator in separators) {
        if (schedule.contains(separator)) {
          final parts = schedule.split(separator);
          if (parts.length >= 2) {
            String startTime = parts[0].trim();
            String endTime = parts[1].trim();

            // Clean and validate times
            startTime = _extractAndCleanTime(startTime);
            endTime = _extractAndCleanTime(endTime);

            if (startTime.isNotEmpty && endTime.isNotEmpty) {
              debugPrint('✅ Parsed times: start="$startTime", end="$endTime"');
              return {
                'startTime': startTime,
                'endTime': endTime,
              };
            }
          }
        }
      }

      // Try to extract time patterns directly
      RegExp timeRegex = RegExp(r'\b(\d{1,2}):(\d{2})\b');
      Iterable<Match> matches = timeRegex.allMatches(schedule);

      if (matches.length >= 2) {
        List<Match> timeMatches = matches.toList();
        String startTime =
            '${timeMatches[0].group(1)}:${timeMatches[0].group(2)}';
        String endTime =
            '${timeMatches[1].group(1)}:${timeMatches[1].group(2)}';

        debugPrint(
            '✅ Extracted times from pattern: start="$startTime", end="$endTime"');
        return {
          'startTime': startTime,
          'endTime': endTime,
        };
      }
    } catch (e) {
      debugPrint('❌ Error parsing schedule: $e');
    }

    debugPrint('❌ Could not parse schedule: "$schedule"');
    return {'startTime': '', 'endTime': ''};
  }

  String _extractAndCleanTime(String timeStr) {
    debugPrint('🧹 Cleaning time: "$timeStr"');

    // Remove extra whitespace
    timeStr = timeStr.trim();

    // Extract time pattern HH:MM or H:MM
    RegExp timePattern = RegExp(r'(\d{1,2}):(\d{2})');
    Match? match = timePattern.firstMatch(timeStr);

    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);

      // Validate hour and minute ranges
      if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
        String cleaned =
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        debugPrint('🧹 Cleaned result: "$cleaned"');
        return cleaned;
      }
    }

    debugPrint('🧹 Could not clean time: "$timeStr"');
    return '';
  }
}
