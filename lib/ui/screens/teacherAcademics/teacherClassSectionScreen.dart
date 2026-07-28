import 'dart:ui';
import 'dart:math';
import 'package:eschool_saas_staff/cubits/teacherAcademics/teacherClassSectionDetailsCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/gradeLevelCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/subjectTeacher.dart';
import 'package:eschool_saas_staff/data/models/academic/gradeLevel.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/ui/widgets/system/no_search_results_widget.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/filterSelectionBottomsheet.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';

class TeacherClassSectionScreen extends StatefulWidget {
  const TeacherClassSectionScreen({super.key});

  static Widget getRouteInstance() {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => TeacherClassSectionDetailsCubit(),
        ),
        BlocProvider(
          create: (context) => GradeLevelCubit(),
        ),
      ],
      child: const TeacherClassSectionScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  @override
  State<TeacherClassSectionScreen> createState() =>
      _TeacherClassSectionScreenState();
}

class _TeacherClassSectionScreenState extends State<TeacherClassSectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _fabAnimationController;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  GradeLevel? _selectedGradeLevel;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..forward();

    _fabAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    _scrollController.addListener(_scrollListener);

    // Load class section details when screen initializes
    getClassSectionDetails();

    // Load grade levels for filter
    context.read<GradeLevelCubit>().getGradeLevels();
  }

  @override
  void dispose() {
    _controller.dispose();
    _fabAnimationController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void getClassSectionDetails() async {
    context
        .read<TeacherClassSectionDetailsCubit>()
        .getTeacherClassSectionDetails(gradeLevelId: _selectedGradeLevel?.id);
  }

  void changeSelectedGradeLevel(GradeLevel? gradeLevel) {
    if (_selectedGradeLevel != gradeLevel) {
      _selectedGradeLevel = gradeLevel;
      setState(() {});

      // Refresh class sections when grade level changes
      getClassSectionDetails();
    }
  }

  void _scrollListener() {
    if (_scrollController.offset > 100 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 100 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        backgroundColor: AppColorPalette.primaryMaroon,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildGradeLevelFilter() {
    return BlocBuilder<GradeLevelCubit, GradeLevelState>(
      builder: (context, gradeLevelState) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (gradeLevelState is GradeLevelFetchSuccess) {
                if (gradeLevelState.gradeLevels.isEmpty) {
                  _showSnackBar("Tidak ada tingkatan yang tersedia");
                  return;
                }
                HapticFeedback.lightImpact();
                Utils.showBottomSheet(
                  child: FilterSelectionBottomsheet<GradeLevel>(
                    onSelection: (value) {
                      if (value != null) {
                        changeSelectedGradeLevel(value);
                        Navigator.pop(context);
                      }
                    },
                    selectedValue: _selectedGradeLevel ??
                        gradeLevelState.gradeLevels.first,
                    titleKey: "Tingkatan",
                    values: gradeLevelState.gradeLevels,
                  ),
                  context: context,
                );
              }
            },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColorPalette.primaryMaroon,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColorPalette.primaryMaroon.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedGradeLevel?.name ?? "Pilih Tingkatan",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_drop_down_rounded,
                      color: Colors.white, size: 28),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColorPalette.primaryMaroon,
              secondary: AppColorPalette.secondaryMaroon,
              surface: isDark ? Theme.of(context).cardColor : Colors.white,
            ),
      ),
      child: Scaffold(
        backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
        appBar: CustomModernAppBar(
          title: Utils.getTranslatedLabel(classSectionKey),
          icon: Icons.class_outlined,
          fabAnimationController: _fabAnimationController,
          primaryColor: AppColorPalette.primaryMaroon,
          lightColor: AppColorPalette.secondaryMaroon,
          height: 180, // Increased height for better modern filter display
          onBackPressed: () => Navigator.of(context).pop(),
          showHelperButton: true,
          helperIcon: Icons.search_rounded,
          onHelperPressed: () {
            setState(() {
              _isSearchActive = !_isSearchActive;
              if (!_isSearchActive) {
                _searchController.clear();
                _searchQuery = "";
              }
            });
          },
          tabBuilder: (context) => _buildGradeLevelFilter(),
        ),
        body: Stack(
          children: [
            // Enhanced Animated Background Pattern
            AnimatedPositioned(
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOut,
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height,
              child: AnimatedOpacity(
                duration: const Duration(seconds: 1),
                opacity: 0.15,
                child: Stack(
                  children: [
                    CustomPaint(
                      painter: BackgroundPatternPainter(
                        color: AppColorPalette.primaryMaroon,
                      ),
                    ),
                    // Decorative particles for modern look
                    ...List.generate(10, (index) {
                      return Positioned(
                        top: Random().nextDouble() *
                            MediaQuery.of(context).size.height,
                        left: Random().nextDouble() *
                            MediaQuery.of(context).size.width,
                        child: AnimatedContainer(
                          duration: Duration(seconds: 2 + index),
                          width: 4 + Random().nextDouble() * 8,
                          height: 4 + Random().nextDouble() * 8,
                          decoration: BoxDecoration(
                            color:
                                AppColorPalette.primaryMaroon.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Main Content with Enhanced Animation
            SafeArea(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - _controller.value) * 30),
                    child: Opacity(
                      opacity: _controller.value,
                      child: BlocBuilder<TeacherClassSectionDetailsCubit,
                          TeacherClassSectionDetailsState>(
                        builder: (context, state) {
                          if (state is TeacherClassSectionDetailsFetchSuccess) {
                            if (state.classSectionDetails.isEmpty) {
                              return _buildEmptyState(context);
                            }
                            return _buildSuccessState(context, state);
                          }

                          if (state is TeacherClassSectionDetailsFetchFailure) {
                            return _buildErrorState(context, state);
                          }

                          return _buildLoadingState(context);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            // Enhanced Search Bar
            _buildSearchBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _isSearchActive ? 56 : 0,
        curve: Curves.easeInOut,
        child: _isSearchActive
            ? Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                decoration: BoxDecoration(
                  color: isDark ? Theme.of(context).cardColor : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Cari kelas...',
                    hintStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColorPalette.secondaryMaroon),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close,
                          color: AppColorPalette.secondaryMaroon),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = "";
                          _isSearchActive = false;
                        });
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Premium Animated Icon Container
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColorPalette.primaryMaroon.withValues(alpha: isDark ? 0.08 : 0.05),
                  border: Border.all(
                    color: AppColorPalette.primaryMaroon.withValues(alpha: isDark ? 0.2 : 0.1),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColorPalette.primaryMaroon.withValues(alpha: isDark ? 0.15 : 0.08),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Inner glowing circle
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColorPalette.primaryMaroon.withValues(alpha: isDark ? 0.25 : 0.15),
                              AppColorPalette.primaryMaroon.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                       .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2.seconds),
                      
                      Icon(
                        Icons.school_outlined,
                        size: 80,
                        color: (isDark ? const Color(0xFFE53935) : AppColorPalette.primaryMaroon).withValues(alpha: isDark ? 0.95 : 0.8),
                      ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Main Message
              Text(
                "Tidak Ada Data Kelas",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE53935) : AppColorPalette.primaryMaroon,
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 12),
              
              // Descriptive text
              Text(
                "Daftar bagian kelas belum tersedia untuk tingkatan ini. Silakan coba tingkatan lain atau tekan tombol muat ulang.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 40),
              
              // Modern Capsule Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColorPalette.primaryMaroon.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    getClassSectionDetails();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 22, color: Colors.white),
                  label: Text(
                    "Muat Ulang Data",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorPalette.primaryMaroon,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState(
      BuildContext context, TeacherClassSectionDetailsFetchSuccess state) {
    // Filter classes based on search query and selected grade level
    List<ClassSection> filteredClasses = state.classSectionDetails;

    // Filter by search query if active
    if (_searchQuery.isNotEmpty) {
      filteredClasses = filteredClasses
          .where((classSection) => (classSection.name ?? "")
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Filter by selected grade level if any
    if (_selectedGradeLevel != null) {
      filteredClasses = filteredClasses
          .where((classSection) =>
              classSection.gradeLevelId == _selectedGradeLevel!.id)
          .toList();
    }

    return AnimationLimiter(
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: _isSearchActive ? 60 : 16, // Adjust for search bar
                bottom: 16,
                left: appContentHorizontalPadding,
                right: appContentHorizontalPadding,
              ),
              child: filteredClasses.isEmpty &&
                      (_searchQuery.isNotEmpty || _selectedGradeLevel != null)
                  ? Padding(
                      padding: const EdgeInsets.only(
                        top: 40, // Added top padding to give some space
                        left: 16,
                        right: 16,
                        bottom: 16,
                      ),
                      child: NoSearchResultsWidget(
                        searchQuery: _searchQuery.isEmpty
                            ? (_selectedGradeLevel?.name ?? "")
                            : _searchQuery,
                        onClearSearch: () {
                          setState(() {
                            _searchQuery = "";
                            _searchController.clear();
                            _isSearchActive = false;
                            _selectedGradeLevel = null;
                          });
                        },
                        primaryColor: AppColorPalette.primaryMaroon,
                        accentColor: AppColorPalette.secondaryMaroon,
                        title: 'Kelas Tidak Ditemukan',
                        description: _searchQuery.isNotEmpty
                            ? 'Tidak ditemukan kelas yang sesuai dengan pencarian Anda. Coba gunakan kata kunci yang berbeda.'
                            : 'Tidak ditemukan kelas untuk tingkatan yang dipilih.',
                        icon: Icons.school_outlined,
                      ).animate().fadeIn(delay: 300.ms),
                    )
                  : _buildEnhancedHeaderCard(context),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 600),
                  child: SlideAnimation(
                    horizontalOffset: 50.0,
                    child: FadeInAnimation(
                      curve: Curves.easeOut,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildEnhancedClassCard(
                            context, filteredClasses[index], index),
                      ),
                    ),
                  ),
                ),
                childCount: filteredClasses.length,
              ),
            ),
          ),
          // Add some bottom padding for better scroll experience
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeaderCard(BuildContext context) {
    return Hero(
      tag: 'class_list_title',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Stack(
          children: [
            // Enhanced Main Card with Improved Frosted Glass Effect
            Card(
              elevation: 16,
              shadowColor: AppColorPalette.primaryMaroon.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColorPalette.primaryMaroon.withValues(alpha: 0.9),
                          AppColorPalette.secondaryMaroon.withValues(alpha: 0.9),
                        ],
                        stops: const [0.2, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColorPalette.primaryMaroon.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Enhanced Top Section with Title and Icon
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CustomTextContainer(
                                        textKey: classListKey,
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 60,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.class_outlined,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Enhanced Decorative Elements
            Positioned(
              right: -25,
              bottom: -15,
              child: Icon(
                Icons.school,
                size: 100,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),

            // Enhanced Decorative Elements
            ...List.generate(4, (index) {
              return Positioned(
                left: 15 + (index * 15),
                top: 15 + (index * 10),
                child: Container(
                  width: 30 - (index * 5),
                  height: 30 - (index * 5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1 - (index * 0.02)),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedClassCard(
      BuildContext context, ClassSection classSection, int index) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isEven = index.isEven;
    final cardGradient = [
      isDark ? Theme.of(context).cardColor : Colors.white,
      isDark ? Theme.of(context).cardColor : Colors.white,
    ];

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0.96, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Utils.showBottomSheet(
                      child: _buildEnhancedBottomSheet(
                          classSection.subjectTeachers ?? []),
                      context: context);
                },
                borderRadius: BorderRadius.circular(24),
                splashColor: AppColorPalette.primaryMaroon.withValues(alpha: 0.2),
                highlightColor: AppColorPalette.primaryMaroon.withValues(alpha: 0.1),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: cardGradient,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.1)
                          : AppColorPalette.primaryMaroon.withValues(alpha: 0.2),
                      width: isDark ? 1.0 : 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildEnhancedCardHeader(context, classSection, isEven),
                      _buildEnhancedCardBody(context, classSection, isEven),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedCardHeader(
      BuildContext context, ClassSection details, bool isEven) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.1)
                : AppColorPalette.primaryMaroon.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        gradient: LinearGradient(
          begin: isEven ? Alignment.centerLeft : Alignment.centerRight,
          end: isEven ? Alignment.centerRight : Alignment.centerLeft,
          colors: [
            AppColorPalette.primaryMaroon.withValues(alpha: isDark ? 0.25 : 0.15),
            AppColorPalette.secondaryMaroon.withValues(alpha: isDark ? 0.12 : 0.08),
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details.name ?? 'Class Section',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColorPalette.primaryMaroon,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedCardBody(
      BuildContext context, ClassSection details, bool isEven) {
    // For class teacher names
    final classTeacherNames = details.getClassTeacherNames();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildEnhancedInfoRow(
              context, 'Guru Kelas', classTeacherNames, Icons.person_outline,
              gradient: [
                AppColorPalette.primaryMaroon.withValues(alpha: 0.08),
                AppColorPalette.secondaryMaroon.withValues(alpha: 0.02),
              ]),

          const SizedBox(height: 16),
          _buildEnhancedInfoRow(context, 'Jumlah Mata Pelajaran',
              '${details.subjectCount ?? details.subjectTeachers?.length ?? 0}',
              Icons.book_outlined,
              gradient: [
                AppColorPalette.primaryMaroon.withValues(alpha: 0.08),
                AppColorPalette.secondaryMaroon.withValues(alpha: 0.02),
              ]),

          // Add spacing before button
          const SizedBox(height: 20),

          // Smaller Selengkapnya button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Utils.showBottomSheet(
                    child: _buildEnhancedBottomSheet(
                        details.subjectTeachers ?? []),
                    context: context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorPalette.primaryMaroon,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Selengkapnya",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add this method to get current teacher ID from your authentication system
  int getCurrentTeacherId() {
    // Implement this to return the current teacher's ID
    // Example:
    // return AuthService.getCurrentUser()?.teacherId ?? 0;
    return 0; // Temporary return value
  }

  Widget _buildEnhancedInfoRow(
      BuildContext context, String label, String value, IconData icon,
      {required List<Color> gradient}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      margin:
          const EdgeInsets.symmetric(horizontal: 6), // Tambahkan margin horizontal
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColorPalette.primaryMaroon.withValues(alpha: isDark ? 0.2 : 0.12),
            AppColorPalette.secondaryMaroon.withValues(alpha: isDark ? 0.1 : 0.08),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.08)
              : AppColorPalette.primaryMaroon.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColorPalette.primaryMaroon,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColorPalette.primaryMaroon.withValues(alpha: isDark ? 0.4 : 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColorPalette.lightMaroon : AppColorPalette.secondaryMaroon,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColorPalette.primaryMaroon,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedBottomSheet(List<SubjectTeacher> subjectTeachers) {
    return ClassSubjectsBottomsheet(subjectTeachers: subjectTeachers);
  }

  Widget _buildErrorState(
      BuildContext context, TeacherClassSectionDetailsFetchFailure state) {
    return CustomErrorWidget(
      message: state.errorMessage,
      onRetry: () => getClassSectionDetails(),
      retryButtonText: "Coba Lagi",
      primaryColor: AppColorPalette.primaryMaroon,
      title:
          "Tidak dapat terhubung ke server, mohon periksa koneksi internet Anda dan coba lagi.",
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              child: _buildEnhancedHeaderCard(context),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const SkeletonClassSectionCard(),
                childCount: 6, // Show 6 skeleton cards
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }
}

class ClassSubjectsBottomsheet extends StatelessWidget {
  final List<SubjectTeacher> subjectTeachers;
  const ClassSubjectsBottomsheet({super.key, required this.subjectTeachers});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomBottomsheet(
      titleLabelKey: classSubjectsKey,
      child: Column(
        children: [
          // Elegant header with subtle gradient
          Container(
            margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  isDark ? AppColorPalette.primaryMaroon : AppColorPalette.primaryMaroon.withValues(alpha: 0.9),
                  isDark ? AppColorPalette.secondaryMaroon : AppColorPalette.primaryMaroon.withValues(alpha: 0.85),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withValues(alpha: 0.3)
                      : AppColorPalette.shadowColor.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daftar Mata Pelajaran',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      height: 2,
                      width: 40,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${subjectTeachers.length} mata pelajaran',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Elegant subject list with minimalist design
          AnimationLimiter(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                  horizontal:
                      16), // Tambahkan margin horizontal untuk subjek kelas
              itemCount: subjectTeachers.length,
              itemBuilder: (context, index) {
                // Get subject name and teacher
                final subject =
                    subjectTeachers[index].subject?.getSybjectNameWithType() ??
                        '';
                final teacher =
                    subjectTeachers[index].teacher?.firstName ?? '-';

                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 450),
                  child: SlideAnimation(
                    horizontalOffset: 50,
                    child: FadeInAnimation(
                      child: Container(
                        margin: const EdgeInsets.only(
                            bottom: 16,
                            left: 4,
                            right:
                                4), // Tambahkan margin horizontal kanan dan kiri
                        decoration: BoxDecoration(
                          color: isDark ? Theme.of(context).cardColor : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark 
                                ? Colors.white.withValues(alpha: 0.08)
                                : AppColorPalette.primaryMaroon.withValues(alpha: 0.15),
                            width: isDark ? 1.0 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                              blurRadius: 15,
                              spreadRadius: 1,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                              },
                              splashColor: AppColorPalette.primaryMaroon
                                  .withValues(alpha: 0.1),
                              highlightColor: AppColorPalette.primaryMaroon
                                  .withValues(alpha: 0.05),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Subject title
                                    Text(
                                      subject,
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : AppColorPalette.primaryMaroon,
                                      ),
                                    ),

                                    // Divider line
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12.0),
                                      child: Container(
                                        height: 1,
                                        color: isDark
                                            ? AppColorPalette.primaryMaroon.withValues(alpha: 0.2)
                                            : AppColorPalette.primaryMaroon
                                                .withValues(alpha: 0.1),
                                      ),
                                    ),

                                    // Teacher info - elegant and simple
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person_outline,
                                          size: 18,
                                          color: isDark ? AppColorPalette.lightMaroon : AppColorPalette.secondaryMaroon,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            teacher,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: isDark ? AppColorPalette.lightMaroon : AppColorPalette.secondaryMaroon,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FilterBackgroundPainter extends CustomPainter {
  final Color color;

  FilterBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Create floating geometric shapes
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.2),
      8,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.8),
      6,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.3),
      4,
      paint,
    );

    // Add subtle connecting lines
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.3),
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BackgroundPatternPainter extends CustomPainter {
  final Color color;

  BackgroundPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Main wave
    final path = Path()
      ..moveTo(0, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.05,
        size.width * 0.5,
        size.height * 0.15,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.25,
        size.width,
        size.height * 0.2,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, paint);

    // Secondary decorative waves
    final path2 = Path()
      ..moveTo(0, size.height * 0.45)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.4,
        size.width * 0.6,
        size.height * 0.55,
        size.width,
        size.height * 0.47,
      )
      ..lineTo(size.width, size.height * 0.45)
      ..lineTo(0, size.height * 0.45)
      ..close();

    canvas.drawPath(
      path2,
      Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EnhancedCurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);

    path.quadraticBezierTo(
      size.width * 0.1,
      size.height,
      size.width * 0.3,
      size.height - 25,
    );

    path.quadraticBezierTo(
      size.width * 0.5,
      size.height - 50,
      size.width * 0.7,
      size.height - 25,
    );

    path.quadraticBezierTo(
      size.width * 0.9,
      size.height,
      size.width,
      size.height - 40,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class AppColorPalette {
  static const Color primaryMaroon = Color(0xFF8B1F41);
  static const Color secondaryMaroon = Color(0xFFA84B5C);
  static const Color lightMaroon = Color(0xFFE7C8CD);
  static const Color accentPink = Color(0xFFF4D0D9);
  static const Color warmBeige = Color(0xFFF5E6E8);
  static const Color shadowColor = Color(0x298B1F41);
}
