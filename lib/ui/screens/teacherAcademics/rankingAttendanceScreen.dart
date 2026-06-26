import 'package:eschool_saas_staff/cubits/teacherAcademics/attendence/attendanceRankingCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/classSectionsAndSubjects.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/gradeLevelCubit.dart';
import 'package:eschool_saas_staff/data/models/student/attendanceRanking.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/models/academic/gradeLevel.dart';
import 'package:eschool_saas_staff/ui/widgets/student/attendanceRankingContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/filterSelectionBottomsheet.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';
import 'package:eschool_saas_staff/cubits/academics/classesAndSessionYearsCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/sessionYear.dart';

class RankingAttendanceScreen extends StatefulWidget {
  static Widget getRouteInstance() {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AttendanceRankingCubit(),
        ),
        BlocProvider(
          create: (context) => ClassSectionsAndSubjectsCubit(),
        ),
        BlocProvider(
          create: (context) => GradeLevelCubit(),
        ),
        BlocProvider(
          create: (context) => ClassesAndSessionYearsCubit(),
        ),
      ],
      child: const RankingAttendanceScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  const RankingAttendanceScreen({super.key});

  @override
  State<RankingAttendanceScreen> createState() =>
      _RankingAttendanceScreenState();
}

class _RankingAttendanceScreenState extends State<RankingAttendanceScreen>
    with TickerProviderStateMixin {
  ClassSection? _selectedClassSection;
  GradeLevel? _selectedGradeLevel;

  // Color scheme for maroon theme matching recapAttendanceSubjectScreen
  final Color _maroonPrimary = const Color(0xFF800020);
  final Color _maroonLight = const Color(0xFFAA6976);

  // Animation controllers
  late AnimationController _fabAnimationController;
  final ScrollController _scrollController = ScrollController();

  // Search functionality
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Cache for class levels to keep filter always available
  List<String> _cachedClassLevels = [];
  AttendanceRanking? _cachedAttendanceData;
  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _scrollController
        .addListener(_scrollListener); // Initialize class sections data
    // Listen to classes and session years to get the default session year
    context.read<ClassesAndSessionYearsCubit>().stream.listen((state) {
      if (state is ClassesAndSessionYearsFetchSuccess) {
        final defaultSessionYear = state.sessionYears.cast<SessionYear?>().firstWhere((e) => e?.isThisDefault() ?? false, orElse: () => null);
        if (defaultSessionYear != null) {
          debugPrint("RankingAttendanceScreen: Found default session year: ${defaultSessionYear.id}");
          context.read<AttendanceRankingCubit>().getAttendanceRanking(sessionYearId: defaultSessionYear.id);
        } else {
          debugPrint("RankingAttendanceScreen: No default session year found, fetching without ID");
          context.read<AttendanceRankingCubit>().getAttendanceRanking();
        }
      } else if (state is ClassesAndSessionYearsFetchFailure) {
        debugPrint("RankingAttendanceScreen: Failed to load session years, fetching without ID");
        context.read<AttendanceRankingCubit>().getAttendanceRanking();
      }
    });

    Future.delayed(Duration.zero, () {
      if (mounted) {
        debugPrint(
            "RankingAttendanceScreen: Initializing class sections data...");
        context
            .read<ClassesAndSessionYearsCubit>()
            .getClassesAndSessionYears();
        // Initialize grade levels
        context.read<GradeLevelCubit>().getGradeLevels();
      }
    }); // Listen to attendance ranking state changes to cache class levels
    context.read<AttendanceRankingCubit>().stream.listen((state) {
      if (state is AttendanceRankingFetchSuccess) {
        debugPrint(
            "RankingAttendanceScreen: Caching attendance data and class levels");
        _cachedAttendanceData = state.attendanceRanking;
        _cachedClassLevels = getClassLevels(state.attendanceRanking);
        debugPrint(
            "RankingAttendanceScreen: Cached ${_cachedClassLevels.length} class levels: $_cachedClassLevels");
      } else if (state is AttendanceRankingFetchFailure) {
        debugPrint(
            "RankingAttendanceScreen: Failed to load attendance data - ${state.errorMessage}");
      } else if (state is AttendanceRankingInProgress) {
        debugPrint("RankingAttendanceScreen: Loading attendance data...");
      }
    });

    // Initialize cache from current state if already loaded
    final currentAttendanceState = context.read<AttendanceRankingCubit>().state;
    if (currentAttendanceState is AttendanceRankingFetchSuccess) {
      _cachedAttendanceData = currentAttendanceState.attendanceRanking;
      _cachedClassLevels =
          getClassLevels(currentAttendanceState.attendanceRanking);
      debugPrint(
          "RankingAttendanceScreen: Initial cache from current state - ${_cachedClassLevels.length} class levels");
    }
  }

  void _scrollListener() {
    if (_scrollController.offset > 50) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _fabAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<String> getClassLevels(AttendanceRanking data) {
    return (data.groupedByClassLevel ?? [])
        .map((e) => e.classLevel ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }

  List<String> getAvailableClassLevels() {
    // First try cached data
    if (_cachedClassLevels.isNotEmpty) {
      return _cachedClassLevels;
    }

    // Then try current state
    final currentState = context.read<AttendanceRankingCubit>().state;
    if (currentState is AttendanceRankingFetchSuccess) {
      final levels = getClassLevels(currentState.attendanceRanking);
      _cachedClassLevels = levels; // Update cache
      return levels;
    }

    // Return empty if no data available
    return [];
  }

  void changeSelectedClassSection(ClassSection? classSection) {
    if (_selectedClassSection != classSection) {
      _selectedClassSection = classSection;
      setState(() {});
      // Don't refresh data - filtering is done client side
      // context.read<AttendanceRankingCubit>().getAttendanceRanking();
    }
  }

  void changeSelectedGradeLevel(GradeLevel? gradeLevel) {
    if (_selectedGradeLevel != gradeLevel) {
      _selectedGradeLevel = gradeLevel;

      // Reset selected class section when grade level changes
      _selectedClassSection = null;

      setState(() {});

      // Re-fetch classes for the selected grade level to filter them
      if (_selectedGradeLevel != null) {
        context
            .read<ClassSectionsAndSubjectsCubit>()
            .getClassSectionsAndSubjects(gradeLevelId: _selectedGradeLevel!.id);
      } else {
        // If no grade level selected, show all classes
        context
            .read<ClassSectionsAndSubjectsCubit>()
            .getClassSectionsAndSubjects();
      }

      // Don't refresh attendance data - filtering is done client side
      // context.read<AttendanceRankingCubit>().getAttendanceRanking();
    }
  }

  Widget _buildRecapTable(AttendanceRanking attendanceRankings) {
    // 1. Update cache for diagnostics
    _cachedAttendanceData = attendanceRankings;
    _cachedClassLevels = getClassLevels(attendanceRankings);

    // 2. Initial data
    AttendanceRanking filteredData = attendanceRankings;

    // 3. Simple Grade Level Filter
    if (_selectedGradeLevel != null && _selectedGradeLevel!.name != null) {
      final String targetGrade = _selectedGradeLevel!.name!.toLowerCase().trim();
      
      filteredData = AttendanceRanking(
        groupedByClassLevel: attendanceRankings.groupedByClassLevel?.where((gl) {
          final level = (gl.classLevel ?? "").toLowerCase();
          return level.contains(targetGrade) || targetGrade.contains(level);
        }).toList(),
        allStudents: attendanceRankings.allStudents?.where((s) {
          final sClass = (s.className ?? "").toLowerCase();
          final sLevel = (s.classLevel ?? "").toLowerCase();
          return sClass.contains(targetGrade) || sLevel.contains(targetGrade);
        }).toList(),
      );
    }

    // 4. Robust Class Section Filter
    if (_selectedClassSection != null && _selectedClassSection!.name != null) {
      // Normalize target name: remove spaces, dashes, and to lowercase (e.g., "Kelas 2 - E" -> "kelas2e")
      final String targetNormalized = _selectedClassSection!.name!
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), "");

      debugPrint("DEBUG: Filtering by Class: $targetNormalized");

      filteredData = AttendanceRanking(
        groupedByClassLevel: filteredData.groupedByClassLevel, // Keep the same groups
        allStudents: filteredData.allStudents?.where((s) {
          final String sClass = (s.className ?? "").toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), "");
          
          // Debug matching
          final bool isMatch = sClass.contains(targetNormalized) || targetNormalized.contains(sClass);
          if (isMatch) debugPrint("DEBUG: Match found for student ${s.studentName} in class $sClass");
          
          return isMatch;
        }).toList(),
      );
    }

    // 5. Recovery Logic: If allStudents is empty, try to populate from grouped data
    if ((filteredData.allStudents == null || filteredData.allStudents!.isEmpty) &&
        (filteredData.groupedByClassLevel != null && filteredData.groupedByClassLevel!.isNotEmpty)) {
      List<AllStudents> recList = [];
      for (var group in filteredData.groupedByClassLevel!) {
        for (var top in (group.topStudents ?? [])) {
          recList.add(AllStudents(
            studentId: top.studentId,
            studentName: top.studentName,
            classLevel: group.classLevel,
            className: top.className,
            jumlahJpSum: top.jumlahJpSum,
            point: top.point,
            alphaCount: top.alphaCount,
          ));
        }
      }
      // Sort Descending
      recList.sort((a, b) {
        double pA = double.tryParse(a.point?.toString() ?? '0') ?? 0;
        double pB = double.tryParse(b.point?.toString() ?? '0') ?? 0;
        return pB.compareTo(pA);
      });

      filteredData = AttendanceRanking(
        groupedByClassLevel: filteredData.groupedByClassLevel,
        allStudents: recList,
      );
    }

    // 6. Check Empty State
    final bool isEmpty = (filteredData.allStudents?.isEmpty ?? true) &&
                         (filteredData.groupedByClassLevel?.isEmpty ?? true);

    if (isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text("Tidak ada data peringkat kehadiran", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    return AttendanceRankingContainer(
      attendanceRankings: filteredData,
      showAllStudents: true,
      searchQuery: _searchQuery,
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildAppBar() {
    return CustomModernAppBar(
      title: "Peringkat Kehadiran",
      icon: Icons.trending_up_rounded,
      fabAnimationController: _fabAnimationController,
      primaryColor: _maroonPrimary,
      lightColor: _maroonLight,
      onBackPressed: () => Navigator.pop(context),
      height: 150, // Increased height to accommodate tab filters
      showArchiveButton: true,
      onArchivePressed: _toggleSearch, // Search button next to title
      archiveIcon: _isSearchActive
          ? Icons.close_rounded
          : Icons.search_rounded, // Dynamic search icon
      tabBuilder: (context) {
        // Custom tab content for filters with 2 filters: Grade Level and Class Section
        return Row(
          children: [
            // Grade Level filter
            Expanded(
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _showGradeLevelFilter,
                  highlightColor: Colors.white.withValues(alpha: 0.1),
                  splashColor: Colors.white.withValues(alpha: 0.2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _selectedGradeLevel?.name ?? 'Semua Tingkatan',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Vertical divider
            Container(
              height: 24,
              width: 1.5,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.4),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),

            // Class Section filter
            Expanded(
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _showClassSectionFilter,
                  highlightColor: Colors.white.withValues(alpha: 0.1),
                  splashColor: Colors.white.withValues(alpha: 0.2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.class_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _selectedClassSection?.name ?? 'Semua Kelas',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper method for class section filter
  void _showClassSectionFilter() {
    final currentState = context.read<ClassSectionsAndSubjectsCubit>().state;

    if (currentState is ClassSectionsAndSubjectsFetchSuccess) {
      // Filter classes based on selected grade level if any
      List<ClassSection> availableClasses = currentState.classSections;

      // If a grade level is selected, filter classes by grade level
      if (_selectedGradeLevel != null) {
        availableClasses = currentState.classSections
            .where((classSection) =>
                classSection.gradeLevelId == _selectedGradeLevel!.id)
            .toList();
      }

      if (availableClasses.isEmpty) {
        final message = _selectedGradeLevel != null
            ? "Tidak ada kelas yang tersedia untuk tingkatan ${_selectedGradeLevel!.name}"
            : "Tidak ada kelas yang tersedia";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: _maroonPrimary,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
        return;
      }

      HapticFeedback.lightImpact();

      // Create list with "Semua Kelas" option using filtered classes
      List<String> classNames = [
        "Semua Kelas",
        ...availableClasses.map((e) => e.name ?? "")
      ];

      Utils.showBottomSheet(
          child: FilterSelectionBottomsheet<String>(
            onSelection: (value) {
              if (value != null) {
                if (value == "Semua Kelas") {
                  changeSelectedClassSection(null);
                } else {
                  // Find the corresponding ClassSection from filtered classes
                  final selectedClass = availableClasses
                      .firstWhere((classSection) => classSection.name == value);
                  changeSelectedClassSection(selectedClass);
                }
                Get.back();
              }
            },
            selectedValue: _selectedClassSection?.name ?? "Semua Kelas",
            values: classNames,
            titleKey: "Pilih Kelas",
          ),
          context: context);
    } else if (currentState is ClassSectionsAndSubjectsFetchInProgress) {
      // Show loading message if data is currently loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text("Sedang memuat data kelas..."),
            ],
          ),
          backgroundColor: _maroonPrimary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    } else if (currentState is ClassSectionsAndSubjectsFetchFailure) {
      // Show error message and retry option
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Gagal memuat data kelas. Coba lagi."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          action: SnackBarAction(
            label: "Retry",
            textColor: Colors.white,
            onPressed: () {
              context
                  .read<ClassSectionsAndSubjectsCubit>()
                  .getClassSectionsAndSubjects();
            },
          ),
        ),
      );
    } else {
      // Initial state - trigger data loading
      context
          .read<ClassSectionsAndSubjectsCubit>()
          .getClassSectionsAndSubjects();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text("Memuat data kelas..."),
            ],
          ),
          backgroundColor: _maroonPrimary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }

  // Helper method for grade level filter
  void _showGradeLevelFilter() {
    final currentState = context.read<GradeLevelCubit>().state;

    if (currentState is GradeLevelFetchSuccess) {
      if (currentState.gradeLevels.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Tidak ada tingkatan yang tersedia"),
            backgroundColor: _maroonPrimary,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
        return;
      }

      HapticFeedback.lightImpact();

      // Create list with "Semua Tingkatan" option
      List<String> gradeLevelNames = [
        "Semua Tingkatan",
        ...currentState.gradeLevels.map((e) => e.name ?? "")
      ];

      Utils.showBottomSheet(
        child: FilterSelectionBottomsheet<String>(
          onSelection: (value) {
            if (value != null) {
              if (value == "Semua Tingkatan") {
                changeSelectedGradeLevel(null);
              } else {
                // Find the corresponding GradeLevel
                final selectedGradeLevel = currentState.gradeLevels
                    .firstWhere((gradeLevel) => gradeLevel.name == value);
                changeSelectedGradeLevel(selectedGradeLevel);
              }
              Get.back();
            }
          },
          selectedValue: _selectedGradeLevel?.name ?? "Semua Tingkatan",
          titleKey: gradeLevelKey,
          values: gradeLevelNames,
        ),
        context: context,
      );
    } else if (currentState is GradeLevelFetchInProgress) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text("Sedang memuat tingkatan..."),
            ],
          ),
          backgroundColor: _maroonPrimary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    } else if (currentState is GradeLevelFetchFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Gagal memuat tingkatan. Coba lagi."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          action: SnackBarAction(
            label: "Retry",
            textColor: Colors.white,
            onPressed: () {
              context.read<GradeLevelCubit>().getGradeLevels();
            },
          ),
        ),
      );
    } else {
      // Initial state - trigger data loading
      context.read<GradeLevelCubit>().getGradeLevels();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text("Memuat tingkatan..."),
            ],
          ),
          backgroundColor: _maroonPrimary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }

  // Helper method for search toggle
  void _toggleSearch() {
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (!_isSearchActive) {
        _searchController.clear();
        _searchQuery = "";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // This container will hold the content (search is now in the AppBar)
          Padding(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top +
                    150), // Adjusted for increased CustomModernAppBar height
            child: Column(
              children: [
                // Search field appears when search is active
                if (_isSearchActive)
                  Container(
                    height: 56,
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Cari nama siswa...',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey.shade500,
                          fontSize: 16,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: _maroonPrimary,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      autofocus: true,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: -0.2, end: 0),

                // Content area - now with correct layout constraints
                Expanded(
                  child: BlocBuilder<ClassSectionsAndSubjectsCubit,
                      ClassSectionsAndSubjectsState>(
                    builder: (context, classSectionState) {
                      return BlocBuilder<AttendanceRankingCubit,
                          AttendanceRankingState>(
                        builder: (context, attendanceState) {
                          debugPrint(
                              "Current attendance state: ${attendanceState.runtimeType}");

                          if (attendanceState is AttendanceRankingInProgress) {
                            return const Center(
                                child: SkeletonAttendanceRankingScreen(
                                    itemCount: 4));
                          } else if (attendanceState
                              is AttendanceRankingFetchFailure) {
                            return CustomErrorWidget(
                              message: attendanceState.errorMessage,
                              onRetry: () {
                                context
                                    .read<AttendanceRankingCubit>()
                                    .getAttendanceRanking();
                              },
                              retryButtonText: "Coba Lagi",
                              primaryColor: _maroonPrimary,
                              title: "Gagal Memuat Data Ranking",
                            );
                          } else if (attendanceState
                              is AttendanceRankingFetchSuccess) {
                            return SingleChildScrollView(
                              child: _buildRecapTable(
                                  attendanceState.attendanceRanking),
                            );
                          }

                          // Handle initial state - show cached data if available
                          if (_cachedAttendanceData != null) {
                            return SingleChildScrollView(
                              child: _buildRecapTable(_cachedAttendanceData!),
                            );
                          }

                          // Show loading state
                          return const Center(
                              child: SkeletonAttendanceRankingScreen(
                                  itemCount: 6));
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          _buildAppBar(),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabAnimationController.value,
            child: FloatingActionButton(
              onPressed: () {
                debugPrint("Manual refresh triggered via FAB");
                HapticFeedback.lightImpact();
                context.read<GradeLevelCubit>().getGradeLevels();
                context
                    .read<ClassSectionsAndSubjectsCubit>()
                    .getClassSectionsAndSubjects();
                context.read<AttendanceRankingCubit>().getAttendanceRanking();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text("Memuat ulang data..."),
                      ],
                    ),
                    backgroundColor: _maroonPrimary,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );
              },
              backgroundColor: _maroonPrimary,
              tooltip: "Refresh Data",
              child: const Icon(Icons.refresh_rounded, color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  bool _hasNoSearchResults(AttendanceRanking filteredData) {
    if (_searchQuery.isEmpty) return false;

    // Filter all students by search query
    final filteredStudents = (filteredData.allStudents ?? [])
        .where((student) => (student.studentName?.toLowerCase() ?? '')
            .contains(_searchQuery.toLowerCase()))
        .toList();
    return filteredStudents.isEmpty;
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated search icon with modern styling
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _maroonPrimary.withValues(alpha: 0.1),
                    _maroonLight.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _maroonPrimary.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 64,
                color: _maroonPrimary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),

            // Main message
            Text(
              'Tidak Ada Hasil',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _maroonPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Search query display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _maroonPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: _maroonPrimary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search,
                    size: 18,
                    color: _maroonPrimary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '"$_searchQuery"',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _maroonPrimary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Description
            Text(
              'Tidak ditemukan siswa yang sesuai dengan pencarian Anda.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba gunakan nama yang berbeda atau periksa ejaan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // Clear search button with modern design
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: _maroonPrimary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = "";
                    _isSearchActive = false;
                  });
                },
                icon: const Icon(Icons.clear_rounded, size: 20),
                label: Text(
                  'Hapus Pencarian',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _maroonPrimary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for decorative elements
class AppBarDecorationPainter extends CustomPainter {
  final Color color;

  AppBarDecorationPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw decorative circles
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.2), 30, paint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.8), 20, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.15), 15, paint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.7), 10, paint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.4), 8, paint);

    // Draw arc
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final arcRect = Rect.fromLTRB(size.width * 0.1, size.height * 0.2,
        size.width * 0.6, size.height * 0.6);
    canvas.drawArc(arcRect, 0.2, 1.5, false, arcPaint);

    // Draw another arc
    final arcRect2 = Rect.fromLTRB(size.width * 0.5, size.height * 0.4,
        size.width * 0.9, size.height * 0.8);
    canvas.drawArc(arcRect2, 3, 1.5, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
