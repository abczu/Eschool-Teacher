import 'package:eschool_saas_staff/data/models/student/studentAttendance.dart';
import 'package:eschool_saas_staff/data/models/student/studentDetails.dart';
import 'package:eschool_saas_staff/ui/widgets/student/studentAttendanceItemContainer.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentAttendanceContainer extends StatefulWidget {
  final List<StudentAttendance> studentAttendances;
  final List<StudentAttendance>?
      allStudentAttendances; // New parameter for all students (for accurate statistics)
  final bool isForAddAttendance;
  final bool isReadOnly;
  final bool showSummary; // New parameter to control summary visibility
  final Function(
      List<({StudentAttendanceStatus status, int studentId})>
          attendanceStatuses)? onStatusChanged;

  const StudentAttendanceContainer({
    super.key,
    required this.isForAddAttendance,
    required this.studentAttendances,
    this.allStudentAttendances, // Optional, defaults to studentAttendances
    this.onStatusChanged,
    this.isReadOnly = false,
    this.showSummary = true, // Default to showing summary
  });

  @override
  State<StudentAttendanceContainer> createState() =>
      _StudentAttendanceContainerState();
}

class _StudentAttendanceContainerState extends State<StudentAttendanceContainer>
    with SingleTickerProviderStateMixin {
  late Map<int, StudentAttendanceStatus> studentStatusesMap = {};

  // Colors for the maroon theme to match teacherAddAttendanceSubjectScreen.dart
  final Color _maroonPrimary = const Color(0xFF800020);
  final Color _maroonLight = const Color(0xFFAA6976);

  // Animation controller for interactive elements
  late AnimationController _animationController;

  // Track stats for summary
  Map<StudentAttendanceStatus, int> _attendanceStats = {};

  @override
  void initState() {
    _initializeStatuses();

    if (widget.onStatusChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _reportStatusesToParent();
        }
      });
    }

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.forward();

    // Calculate initial stats
    _updateAttendanceStats();

    super.initState();
  }

  void _initializeStatuses() {
    final students = widget.allStudentAttendances ?? widget.studentAttendances;
    studentStatusesMap = {
      for (var e in students)
        (e.studentDetails?.id ?? e.studentId ?? 0): _getStatusFromAttendance(e)
    };
  }

  StudentAttendanceStatus _getStatusFromAttendance(StudentAttendance e) {
    if (e.isPresent()) return StudentAttendanceStatus.present;
    if (e.isAbsent()) return StudentAttendanceStatus.absent;
    if (e.isSick()) return StudentAttendanceStatus.sick;
    if (e.isPermission()) return StudentAttendanceStatus.permission;
    if (e.isAlpa()) return StudentAttendanceStatus.alpa;
    return StudentAttendanceStatus.absent;
  }

  void _reportStatusesToParent() {
    if (widget.onStatusChanged != null) {
      final students = widget.allStudentAttendances ?? widget.studentAttendances;
      widget.onStatusChanged!(
        students.map((student) {
          final id = student.studentDetails?.id ?? student.studentId ?? 0;
          return (
            status: studentStatusesMap[id] ?? StudentAttendanceStatus.present,
            studentId: id,
          );
        }).toList(),
      );
    }
  }

  @override
  void didUpdateWidget(covariant StudentAttendanceContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if the actual list of students changed (not just reference)
    final oldStudents = oldWidget.allStudentAttendances ?? oldWidget.studentAttendances;
    final newStudents = widget.allStudentAttendances ?? widget.studentAttendances;
    
    bool studentsChanged = oldStudents.length != newStudents.length;
    if (!studentsChanged) {
      for (int i = 0; i < oldStudents.length; i++) {
        final oldId = oldStudents[i].studentDetails?.id ?? oldStudents[i].studentId ?? 0;
        final newId = newStudents[i].studentDetails?.id ?? newStudents[i].studentId ?? 0;
        if (oldId != newId) {
          studentsChanged = true;
          break;
        }
      }
    }

    if (studentsChanged) {
      _initializeStatuses();
      _updateAttendanceStats();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _reportStatusesToParent();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Calculate attendance statistics
  void _updateAttendanceStats() {
    _attendanceStats = {
      StudentAttendanceStatus.present: 0,
      StudentAttendanceStatus.absent: 0,
      StudentAttendanceStatus.sick: 0,
      StudentAttendanceStatus.permission: 0,
      StudentAttendanceStatus.alpa: 0,
    };

    for (var status in studentStatusesMap.values) {
      if (_attendanceStats.containsKey(status)) {
        _attendanceStats[status] = (_attendanceStats[status] ?? 0) + 1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update stats when building
    _updateAttendanceStats();

    // Calculate percentages for present students using all students for accurate statistics
    int totalStudents =
        (widget.allStudentAttendances ?? widget.studentAttendances).length;
    double presentPercentage = totalStudents > 0
        ? (_attendanceStats[StudentAttendanceStatus.present] ?? 0) /
            totalStudents *
            100
        : 0;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBgColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final Color borderColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200;
    final Color progressTrackColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200;
    final Color labelTextColor = isDark ? Colors.grey[300]! : Colors.grey[700]!;

    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        children: [
          // Attendance Summary Card - New Addition
          if ((widget.allStudentAttendances ?? widget.studentAttendances)
                  .isNotEmpty &&
              widget.showSummary)
            Container(
              margin: const EdgeInsets.fromLTRB(0, 16, 0, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [cardBgColor, cardBgColor]
                      : [Colors.white, const Color(0xFFF8F9FA)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with icon
                  Row(
                    children: [
                      Icon(
                        Icons.insert_chart_rounded,
                        color: isDark ? Colors.white : _maroonPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ringkasan Kehadiran',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : _maroonPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Present percentage indicator
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Kehadiran',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: labelTextColor,
                            ),
                          ),
                          Text(
                            '${presentPercentage.toStringAsFixed(1)}%',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: presentPercentage > 80
                                  ? Colors.green[700]
                                  : presentPercentage > 50
                                      ? Colors.orange[700]
                                      : Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Progress bar
                      Stack(
                        children: [
                          // Background
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: progressTrackColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          // Fill
                          Container(
                            height: 8,
                            width: MediaQuery.of(context).size.width *
                                (presentPercentage / 100) *
                                0.7, // Adjusted for container width
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: presentPercentage > 80
                                    ? [
                                        Colors.green.shade400,
                                        Colors.green.shade700
                                      ]
                                    : presentPercentage > 50
                                        ? [
                                            Colors.orange.shade400,
                                            Colors.orange.shade700
                                          ]
                                        : [
                                            Colors.red.shade400,
                                            Colors.red.shade700
                                          ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 400.ms).slideX(
                          begin: -0.2,
                          end: 0,
                          duration: 600.ms,
                          curve: Curves.easeOutQuad),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Status count indicators
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusBadge(
                          context,
                          'Hadir',
                          _attendanceStats[StudentAttendanceStatus.present] ??
                              0,
                          Colors.green),
                      _buildStatusBadge(
                          context,
                          'Sakit',
                          _attendanceStats[StudentAttendanceStatus.sick] ?? 0,
                          Colors.blue),
                      _buildStatusBadge(
                          context,
                          'Izin',
                          _attendanceStats[
                                  StudentAttendanceStatus.permission] ??
                              0,
                          Colors.orange),
                      _buildStatusBadge(
                          context,
                          'Alpa',
                          _attendanceStats[StudentAttendanceStatus.alpa] ?? 0,
                          Colors.red),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).scale(
                begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0)),

          // Header
          Container(
            width: MediaQuery.of(context).size.width,
            margin: const EdgeInsets.fromLTRB(
                0, 16, 0, 0), // Removed horizontal margins
            decoration: BoxDecoration(
              color: _maroonPrimary,
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _maroonPrimary,
                  const Color(0xFF9A1E3C),
                  _maroonLight,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _maroonPrimary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 13), // Increased horizontal padding
              child: Row(
                children: [
                  // No section - fixed width to match item container
                  SizedBox(
                    width: 32,
                    child: Center(
                      child: Text(
                        'No',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Name section with icon - expanded with flex 5
                  Expanded(
                    flex: 5,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Utils.getTranslatedLabel(nameKey),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status section with icon - expanded with flex 4
                  Expanded(
                    flex: 4,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.how_to_reg_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Utils.getTranslatedLabel(statusKey),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

          // Student list
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children:
                  List.generate(widget.studentAttendances.length, (index) {
                final student = widget.studentAttendances[index];
                final studentId = student.studentDetails?.id ?? student.studentId ?? 0;
                final currentStatus = studentStatusesMap[studentId] ?? StudentAttendanceStatus.present;

                return AbsorbPointer(
                  absorbing: widget.isReadOnly,
                  child: StudentAttendanceItemContainer(
                    studentDetails: student.studentDetails ?? StudentDetails.fromJson({}),
                    showStatusPicker: widget.isForAddAttendance,
                    isPresent: currentStatus == StudentAttendanceStatus.present,
                    isSick: currentStatus == StudentAttendanceStatus.sick,
                    isPermission: currentStatus == StudentAttendanceStatus.permission,
                    isAlpa: currentStatus == StudentAttendanceStatus.alpa,
                    onChangeAttendance: (StudentAttendanceStatus status) {
                      if (!widget.isReadOnly) {
                        // Update the internal map of statuses using studentId
                        setState(() {
                          studentStatusesMap[studentId] = status;
                        });

                        // Notify the parent with the updated full list
                        _reportStatusesToParent();

                        // Provide visual feedback
                        _animationController.forward(from: 0);
                      }
                    },
                    index: index,
                  ),
                );
              }),
            ),
          ),

          // Empty state message if no students
          if (widget.studentAttendances.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.people_alt_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada siswa untuk ditampilkan',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Silakan pilih kelas untuk melihat daftar siswa',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms),

          // Bottom padding
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Helper method to build status badges for the summary
  Widget _buildStatusBadge(
      BuildContext context, String label, int count, Color color) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color labelTextColor = isDark ? Colors.white70 : Colors.grey[800]!;
    final Color countBgColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: labelTextColor,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: countBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
