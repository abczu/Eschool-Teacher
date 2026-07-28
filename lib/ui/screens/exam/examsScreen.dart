import 'package:eschool_saas_staff/cubits/academics/sessionYearsAndMediumsCubit.dart';
import 'package:eschool_saas_staff/cubits/exam/offlineExamsCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/medium.dart';
import 'package:eschool_saas_staff/data/models/exam/offlineExam.dart';
import 'package:eschool_saas_staff/data/models/academic/sessionYear.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';
import 'package:eschool_saas_staff/ui/widgets/system/filterSelectionBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:eschool_saas_staff/ui/screens/widgets/offlineExamTimetableBottomsheet.dart';

class ExamsScreen extends StatefulWidget {
  static Widget getRouteInstance() {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SessionYearsAndMediumsCubit(),
        ),
        BlocProvider(
          create: (context) => OfflineExamsCubit(),
        ),
      ],
      child: const ExamsScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen>
    with TickerProviderStateMixin {
  SessionYear? _selectedSessionYear;
  Medium? _selectedMedium;
  late AnimationController _controller;
  final ScrollController _scrollController = ScrollController();
  late ConfettiController _confettiController;

  String _filterStatus = "Semua"; // New variable for status filter
  bool _isFiltering = false;
  DateTime? _startDate; // For date range filtering
  DateTime? _endDate; // For date range filtering

  // Refined elegant maroon-based color palette
  final Color primaryColor = const Color(0xFF8B2635); // Deep maroon primary
  final Color accentColor = const Color(0xFFD4A59A); // Soft rose accent
  final Color completedColor =
      const Color(0xFF7D3C50); // Elegant maroon - sophisticated and modern
  final Color ongoingColor =
      const Color(0xFF7D3C50); // Navy blue - deeper and more elegant
  final Color upcomingColor =
      const Color(0xFF7D3C50); // Burgundy red - less harsh
  final Color cardBackgroundColor = const Color(0xFFFAF3F0); // Cream background
  final Color cardBorderColor = const Color(0xFFE7D8D1); // Soft border color
  final Color cardTextPrimary = const Color(0xFF3F3F3F); // Dark gray for text
  final Color cardTextSecondary =
      const Color(0xFF6D6D6D); // Medium gray for secondary text

  final bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _controller.forward();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    // Fetch session years and mediums
    Future.delayed(Duration.zero, () {
      if (mounted) {
        context.read<SessionYearsAndMediumsCubit>().getSessionYearsAndMediums();

        // Immediately fetch exams without waiting for filters
        // This will load all exams with default parameters
        getExams();
      }
    });

    // Play confetti when the page loads
    Future.delayed(const Duration(milliseconds: 500), () {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _confettiController.dispose();

    super.dispose();
  }

  void changeSelectedSessionYear(SessionYear sessionYear) {
    setState(() {
      _selectedSessionYear = sessionYear;
    });
  }

  void changeSelectedMedium(Medium medium) {
    setState(() {
      _selectedMedium = medium;
    });
  }

  Future<void> getExams() async {
    context.read<OfflineExamsCubit>().getOfflineExams(
        status: 3,
        mediumId: _selectedMedium?.id,
        sessionYearId: _selectedSessionYear?.id);
  }

  List<OfflineExam> _filterExams(List<OfflineExam> exams) {
    if (_filterStatus == "Semua" && _startDate == null && _endDate == null) {
      return exams;
    }

    return exams.where((exam) {
      // Filter by status
      if (_filterStatus != "Semua") {
        final statusKey = exam.getOfflineStatusKey().toLowerCase();
        if (_filterStatus == "Selesai" && statusKey != 'completed') {
          return false;
        }
        if (_filterStatus == "Sedang Berlangsung" && statusKey != 'ongoing') {
          return false;
        }
        if (_filterStatus == "Akan Datang" && statusKey != 'upcoming') {
          return false;
        }
      }

      // Filter by date range
      if (_startDate != null || _endDate != null) {
        try {
          if (exam.examStartingDate == null || exam.examStartingDate!.isEmpty) {
            return false;
          }

          final examDate = DateTime.parse(exam.examStartingDate!);

          if (_startDate != null && examDate.isBefore(_startDate!)) {
            return false;
          }

          if (_endDate != null) {
            // Add one day to include the end date fully
            final endDatePlusOne = _endDate!.add(const Duration(days: 1));
            if (examDate.isAfter(endDatePlusOne)) {
              return false;
            }
          }
        } catch (e) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _showFilterBottomSheet(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow the modal to take up more space
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final bool isDark = Theme.of(context).brightness == Brightness.dark;
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(top: 8, bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Title
                    Text(
                      'Filter Ujian',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Date Range Filter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: modalContext,
                                initialDate: _startDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  _startDate = picked;
                                });
                                setState(() {
                                  _startDate = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _startDate != null
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(_startDate!)
                                    : 'Dari',
                                style: TextStyle(
                                    fontSize: 16, color: isDark ? Colors.white70 : Colors.grey[800]),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '-',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: modalContext,
                                initialDate: _endDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  _endDate = picked;
                                });
                                setState(() {
                                  _endDate = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _endDate != null
                                    ? DateFormat('dd/MM/yyyy').format(_endDate!)
                                    : 'Sampai',
                                style: TextStyle(
                                    fontSize: 16, color: isDark ? Colors.white70 : Colors.grey[800]),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Status Filter Options - wrap in Container with fixed height
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: RadioGroup<String>(
                        groupValue: _filterStatus,
                        onChanged: (value) {
                          setModalState(() {
                            _filterStatus = value ?? 'Semua';
                          });
                          setState(() {
                            _filterStatus = value ?? 'Semua';
                          });
                        },
                        child: ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildFilterOption('Semua', setModalState),
                            _buildFilterOption('Selesai', setModalState),
                            _buildFilterOption('Akan Datang', setModalState),
                            _buildFilterOption(
                                'Sedang Berlangsung', setModalState),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Apply Filter Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isFiltering = true;
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFFE53935) : primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Terapkan Filter'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Reset Filter Button
                    if (_filterStatus != "Semua" ||
                        _startDate != null ||
                        _endDate != null)
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            setModalState(() {
                              _filterStatus = "Semua";
                              _startDate = null;
                              _endDate = null;
                            });
                            setState(() {
                              _filterStatus = "Semua";
                              _startDate = null;
                              _endDate = null;
                              _isFiltering = false;
                            });
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor:
                                isDark ? const Color(0xFFE53935) : primaryColor, // Changed to maroon/bright red color
                          ),
                          child: const Text(
                            'Reset Filter',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterOption(String label, StateSetter setModalState) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        InkWell(
          onTap: () {
            setModalState(() {
              _filterStatus = label;
            });
            setState(() {
              _filterStatus = label;
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.grey[800]),
                ),
                Radio<String>(
                  value: label,
                  activeColor: isDark ? const Color(0xFFE53935) : primaryColor,
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[300]),
      ],
    );
  }

  Map<String, List<OfflineExam>> _groupExamsByMonth(List<OfflineExam> exams) {
    final Map<String, List<OfflineExam>> grouped = {};

    // Sort exams by date first
    final sortedExams = exams.toList()
      ..sort((a, b) {
        try {
          // Safely parse dates with null checks
          final DateTime dateA =
              a.examStartingDate != null && a.examStartingDate!.isNotEmpty
                  ? DateTime.parse(a.examStartingDate!)
                  : DateTime.now();
          final DateTime dateB =
              b.examStartingDate != null && b.examStartingDate!.isNotEmpty
                  ? DateTime.parse(b.examStartingDate!)
                  : DateTime.now();
          return dateA.compareTo(dateB);
        } catch (e) {
          // Handle parse errors by returning 0 (equal)
          return 0;
        }
      });

    for (var exam in sortedExams) {
      // Skip if date is missing or empty
      if (exam.examStartingDate == null || exam.examStartingDate!.isEmpty) {
        continue;
      }
      try {
        final dateTime = DateTime.parse(exam.examStartingDate!);
        final monthYear =
            "${Utils.getMonthFullName(dateTime.month)} ${dateTime.year}";

        if (!grouped.containsKey(monthYear)) {
          grouped[monthYear] = [];
        }

        grouped[monthYear]!.add(exam);
      } catch (e) {
        // Skip this exam if date parsing fails
        continue;
      }
    }

    return grouped;
  }

  Widget _buildExamItem(OfflineExam exam, int index) {
    // Check if timetable is still loading or has items
    final bool isLoading = exam.timetableSlots == null;
    final bool hasTimetable = isLoading ||
        exam.timetableSlots!
            .isNotEmpty; // Consider as having timetable if it's loading
    DateTime? examDate;
    String dayString = "";
    String monthString = ""; // Parse and format date safely
    if (exam.examStartingDate != null && exam.examStartingDate!.isNotEmpty) {
      try {
        examDate = DateTime.parse(exam.examStartingDate!);
        dayString = examDate.day.toString();
        monthString = Utils.getMonthName(examDate.month);
      } catch (e) {
        // Keep default values if parsing fails
      }
    }

    final statusKey = exam.getOfflineStatusKey().toLowerCase();
    final isCompleted = statusKey == 'completed';

    final isOngoing = statusKey == 'ongoing';

    final statusColor = _getStatusColor(statusKey);

    // Define header colors to match page header
    final headerStartColor = primaryColor; // 0xFF8B2635
    const headerEndColor =
        Color(0xFF5A2223); // Deeper shade matching page header

    // Generate random angle for the background pattern
    final randomAngle = (index * 37) % 360;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color displayStatusColor = isDark ? const Color(0xFFE53935) : statusColor;

    return Hero(
        tag: 'exam-${exam.id}',
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              splashColor: displayStatusColor.withValues(alpha: 0.15),
              highlightColor: displayStatusColor.withValues(alpha: 0.08),
              onTap: () {
                if (hasTimetable) {
                  HapticFeedback.mediumImpact();
                  Utils.showBottomSheet(
                    child: OfflineExamTimetableBottomsheet(
                      timetableSlots: exam.timetableSlots,
                      primaryColor: primaryColor,
                      exam: exam,
                      isLoading: isLoading,
                    ),
                    context: context,
                  );
                }
              },
              child: Stack(
                children: [
                  // Background pattern
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CustomPaint(
                        painter: ExamCardBackgroundPainter(
                          color: displayStatusColor.withValues(alpha: isDark ? 0.06 : 0.06),
                          angle: randomAngle.toDouble(),
                        ),
                      ),
                    ),
                  ),

                  // Main card content
                  Container(
                    padding: const EdgeInsets.all(0),
                    decoration: BoxDecoration(
                      color: isDark ? Theme.of(context).cardColor : Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: displayStatusColor.withValues(alpha: isDark ? 0.15 : 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.5),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header with status & date - Updated to match page header gradient
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    headerStartColor,
                                    headerEndColor,
                                  ],
                                ),
                              ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            child: Row(
                              children: [
                                // Status indicator with icon
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isCompleted
                                        ? Icons.check_circle
                                        : isOngoing
                                            ? Icons.access_time_filled
                                            : Icons.event_available,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _getStatusText(statusKey),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                // Date display
                                if (examDate != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _getDayName(examDate.weekday),
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Main content
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Day container - Updated to match page header gradient
                              Container(
                                width: 65,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      headerStartColor,
                                      headerEndColor,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: headerStartColor.withValues(
                                          alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(2, 3),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    // Background pattern
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Opacity(
                                          opacity: 0.15,
                                          child: CustomPaint(
                                            painter: CirclePatternPainter(
                                                color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Content
                                    Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            dayString,
                                            style: GoogleFonts.poppins(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            monthString,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white
                                                  .withValues(alpha: 0.85),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Exam details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exam.name ?? "-",
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color:
                                            displayStatusColor.withValues(alpha: isDark ? 0.15 : 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: displayStatusColor.withValues(
                                              alpha: isDark ? 0.3 : 0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.groups_rounded,
                                            size: 16,
                                            color: displayStatusColor.withValues(
                                                alpha: isDark ? 0.9 : 0.7),
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              Utils().cleanClassName(
                                                  exam.className ?? "-"),
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ), // Footer with timetable indicator - always show, with loading state when needed
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: displayStatusColor.withValues(alpha: isDark ? 0.08 : 0.05),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            border: Border(
                              top: BorderSide(
                                color: displayStatusColor.withValues(alpha: isDark ? 0.15 : 0.1),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 16,
                                    color: displayStatusColor.withValues(alpha: isDark ? 0.9 : 0.7),
                                  ),
                                  const SizedBox(width: 8),
                                  // Show loading indicator if timetableSlots is null
                                  exam.timetableSlots == null
                                      ? Row(
                                          children: [
                                            SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: displayStatusColor,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "Memuat...",
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          "${exam.timetableSlots!.length} Mata Pelajaran",
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                                          ),
                                        ),
                                ],
                              ),
                              Text(
                                "Selengkapnya",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: displayStatusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate(delay: (80 * index).ms)
              .fadeIn(duration: 600.ms, curve: Curves.easeOut)
              .slideY(
                  begin: 0.2,
                  end: 0,
                  duration: 800.ms,
                  curve: Curves.easeOutQuint)
              .scale(
                  begin: const Offset(0.97, 0.97),
                  end: const Offset(1.0, 1.0),
                  duration: 800.ms,
                  curve: Curves.easeOutQuint),
        ));
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return upcomingColor;
      case 'ongoing':
        return ongoingColor;
      case 'completed':
        return completedColor;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return "Akan Datang";
      case 'ongoing':
        return "Sedang Berlangsung";
      case 'completed':
        return "Selesai";
      default:
        return "Tidak Diketahui";
    }
  }

  String _getDayName(int weekday) {
    const days = [
      '',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    return days[weekday];
  }

  Widget _buildEmptyState() {
    String emptyMessage;
    IconData emptyIcon;

    // Determine the appropriate message and icon based on filters
    if (_filterStatus == "Semua" && _startDate == null && _endDate == null) {
      emptyMessage = "Belum ada jadwal ujian tersedia";
      emptyIcon = Icons.event_note_outlined;
    } else {
      // Generate specific messages based on active filters
      if (_filterStatus == "Akan Datang") {
        emptyMessage = "Tidak ada ujian yang akan datang";
        emptyIcon = Icons.schedule_outlined;
      } else if (_filterStatus == "Sedang Berlangsung") {
        emptyMessage = "Tidak ada ujian yang sedang berlangsung";
        emptyIcon = Icons.play_circle_outline;
      } else if (_filterStatus == "Selesai") {
        emptyMessage = "Tidak ada ujian yang telah selesai";
        emptyIcon = Icons.check_circle_outline;
      } else if (_startDate != null || _endDate != null) {
        emptyMessage = "Tidak ada ujian pada rentang tanggal yang dipilih";
        emptyIcon = Icons.date_range_outlined;
      } else {
        emptyMessage = "Tidak ditemukan hasil pencarian";
        emptyIcon = Icons.search_off_outlined;
      }
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color iconColor = isDark ? const Color(0xFFE53935) : primaryColor;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon with subtle animation
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              emptyIcon,
              size: 64,
              color: iconColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            emptyMessage,
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: isDark ? Colors.white : primaryColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Coba ubah filter atau refresh halaman",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Reset filter button (if filters are active)
              if (_filterStatus != "Semua" ||
                  _startDate != null ||
                  _endDate != null)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _filterStatus = "Semua";
                        _startDate = null;
                        _endDate = null;
                      });
                      getExams();
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text("Reset Filter"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(
                          color: primaryColor.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              // Refresh button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: getExams,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text("Refresh"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 600.ms).scale(
        begin: const Offset(0.8, 0.8),
        end: const Offset(1.0, 1.0),
        duration: 600.ms,
        curve: Curves.easeOutQuint);
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) {
        return const SkeletonExamCard();
      },
    );
  }

  Widget _buildHeader() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return SlideInDown(
      duration: const Duration(milliseconds: 800),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 10),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Title with modern styling
                  Expanded(
                    child: Text(
                      "Jadwal Ujian",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : primaryColor,
                      ),
                    ),
                  ),
                ],
              ),

              // Filter indicator chips - show applied filters
              if (_isFiltering)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  height: 40,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (_filterStatus != "Semua")
                          _buildFilterChip(
                            label: _filterStatus,
                            color: _getFilterStatusColor(_filterStatus),
                          ),
                        if (_startDate != null && _endDate != null)
                          _buildFilterChip(
                            label:
                                "${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}",
                            color: primaryColor,
                          )
                        else if (_startDate != null)
                          _buildFilterChip(
                            label:
                                "Dari ${DateFormat('dd/MM/yyyy').format(_startDate!)}",
                            color: primaryColor,
                          )
                        else if (_endDate != null)
                          _buildFilterChip(
                            label:
                                "Sampai ${DateFormat('dd/MM/yyyy').format(_endDate!)}",
                            color: primaryColor,
                          ),
                        if (_isFiltering)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _filterStatus = "Semua";
                                _startDate = null;
                                _endDate = null;
                                _isFiltering = false;
                              });
                              getExams();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(
                                    alpha:
                                        0.1), // Changed to maroon with opacity
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: primaryColor.withValues(
                                      alpha:
                                          0.5), // Changed to maroon with opacity
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.close,
                                      color: primaryColor,
                                      size: 16), // Changed to maroon color
                                  const SizedBox(width: 4),
                                  Text(
                                    "Reset",
                                    style: TextStyle(
                                      color:
                                          primaryColor, // Changed to maroon color
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(
                    begin: -0.2,
                    end: 0,
                    duration: 300.ms,
                    curve: Curves.easeOut),

              // Show filters row - Session Years and Medium filters remain
              if (_showFilters)
                Container(
                  margin: const EdgeInsets.only(top: 16, bottom: 8),
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterOptionChip(
                        label: _selectedSessionYear?.name ?? "Tahun Ajaran",
                        icon: Icons.calendar_today_outlined,
                        onTap: () {
                          if (context.read<SessionYearsAndMediumsCubit>().state
                              is SessionYearsAndMediumsFetchSuccess) {
                            final state = context
                                .read<SessionYearsAndMediumsCubit>()
                                .state as SessionYearsAndMediumsFetchSuccess;

                            Utils.showBottomSheet(
                              context: context,
                              child: FilterSelectionBottomsheet(
                                titleKey: "Pilih Tahun Ajaran",
                                values: state.sessionYears
                                    .map((e) => {
                                          "id": e.id,
                                          "title": e.name,
                                        })
                                    .toList(),
                                selectedValue: _selectedSessionYear?.id,
                                onSelection: (selectedItem) {
                                  final sessionYear =
                                      state.sessionYears.firstWhere(
                                    (element) =>
                                        element.id ==
                                        (selectedItem
                                            as Map<String, dynamic>)['id'],
                                  );
                                  changeSelectedSessionYear(sessionYear);
                                  getExams();
                                },
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                      _buildFilterOptionChip(
                        label: _selectedMedium?.name ?? "Bahasa",
                        icon: Icons.language_rounded,
                        onTap: () {
                          if (context.read<SessionYearsAndMediumsCubit>().state
                              is SessionYearsAndMediumsFetchSuccess) {
                            final state = context
                                .read<SessionYearsAndMediumsCubit>()
                                .state as SessionYearsAndMediumsFetchSuccess;

                            Utils.showBottomSheet(
                              context: context,
                              child: FilterSelectionBottomsheet(
                                titleKey: "Pilih Bahasa",
                                values: state.mediums
                                    .map((e) => {
                                          "id": e.id,
                                          "title": e.name,
                                        })
                                    .toList(),
                                selectedValue: _selectedMedium?.id,
                                onSelection: (selectedItem) {
                                  final medium = state.mediums.firstWhere(
                                    (element) =>
                                        element.id ==
                                        (selectedItem
                                            as Map<String, dynamic>)['id'],
                                  );
                                  changeSelectedMedium(medium);
                                  getExams();
                                },
                              ),
                            );
                          }
                        },
                      ),
                      if (_selectedSessionYear != null ||
                          _selectedMedium != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: _buildFilterOptionChip(
                            label: "Reset Filter",
                            icon: Icons.refresh_rounded,
                            onTap: () {
                              setState(() {
                                _selectedSessionYear = null;
                                _selectedMedium = null;
                              });
                              getExams();
                            },
                          ),
                        ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(
                    begin: -0.2,
                    end: 0,
                    duration: 300.ms,
                    curve: Curves.easeOut),
            ],
          ),
        ),
      ),
    );
  }

  Color _getFilterStatusColor(String status) {
    switch (status) {
      case "Selesai":
        return completedColor;
      case "Sedang Berlangsung":
        return ongoingColor;
      case "Akan Datang":
        return upcomingColor;
      default:
        return primaryColor;
    }
  }

  Widget _buildFilterChip({
    required String label,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFilterOptionChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final bool isResetFilter = label == "Reset";

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: isResetFilter
                ? primaryColor
                : Colors.white, // Changed for Reset Filter
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isResetFilter
                    ? Colors.white
                    : primaryColor, // Changed for Reset Filter
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isResetFilter
                        ? Colors.white
                        : Colors.grey[800], // Changed for Reset Filter
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: isResetFilter
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.grey[600], // Changed for Reset Filter
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomModernAppBar(
        title: "Jadwal Ujian Offline",
        icon: Icons.assignment_rounded,
        fabAnimationController: _controller,
        primaryColor: primaryColor,
        lightColor: accentColor,
        onBackPressed: () => Navigator.pop(context),
        showFilterButton: true,
        onFilterPressed: () => _showFilterBottomSheet(context),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: BlocBuilder<OfflineExamsCubit, OfflineExamsState>(
              builder: (context, state) {
                if (state is OfflineExamsFetchSuccess) {
                  final filteredExams = _filterExams(state.offlineExams);
                  final groupedExams = _groupExamsByMonth(filteredExams);

                  if (filteredExams.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
                    itemCount: groupedExams.length,
                    itemBuilder: (context, index) {
                      final monthYear = groupedExams.keys.elementAt(index);
                      final exams = groupedExams[monthYear]!;

                      final bool isDark = Theme.of(context).brightness == Brightness.dark;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 20, bottom: 10),
                            child: Text(
                              monthYear,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white.withValues(alpha: 0.9) : primaryColor,
                              ),
                            ),
                          ),
                          ...exams.asMap().entries.map((entry) =>
                              _buildExamItem(entry.value, entry.key)),
                        ],
                      );
                    },
                  );
                } else if (state is OfflineExamsFetchInProgress) {
                  return _buildLoadingShimmer();
                } else {
                  return CustomErrorWidget(
                    onRetry: getExams,
                    message: "Gagal memuat data ujian",
                    primaryColor: primaryColor,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
