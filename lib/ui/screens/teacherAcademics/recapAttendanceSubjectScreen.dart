import 'package:eschool_saas_staff/ui/widgets/student/recapAttendanceContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/student/downloadAttendanceRecapDialog.dart';
import 'package:eschool_saas_staff/utils/system/api.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool_saas_staff/cubits/academics/classesCubit.dart';
import 'package:eschool_saas_staff/cubits/authentication/authCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/data/repositories/auth/authRepository.dart';
import 'package:get/get.dart' as getx;

class RecapAttendanceSubjectScreen extends StatefulWidget {
  static Widget getRouteInstance() {
    return BlocProvider(
      create: (context) => ClassesCubit()..getClasses(),
      child: const RecapAttendanceSubjectScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  const RecapAttendanceSubjectScreen({super.key});

  @override
  State<RecapAttendanceSubjectScreen> createState() =>
      _RecapAttendanceSubjectScreenState();
}

class _RecapAttendanceSubjectScreenState
    extends State<RecapAttendanceSubjectScreen> with TickerProviderStateMixin {
  int _selectedYear = DateTime.now().year;
  int? _selectedMonth;
  ClassSection? _selectedClassSection;
  List<ClassSection> _filteredClassSections = [];
  int? teacherId;
  int? schoolId;
  String? email;

  final Color _maroonPrimary = const Color(0xFF800020);
  final Color _maroonLight = const Color(0xFFAA6976);

  late AnimationController _fabAnimationController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _scrollController.addListener(_scrollListener);
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
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadClassTeacherData();
  }

  void _loadClassTeacherData() {
    final userDetails = context.read<AuthCubit>().getUserDetails();

    setState(() {
      teacherId = userDetails.id;
      // Fallback: ambil schoolId dari userDetails.school?.id jika schoolId null
      schoolId = userDetails.schoolId ?? userDetails.school?.id;
      email = userDetails.email ?? "";
    });
    debugPrint('[RecapSubject] Loaded teacher data: teacherId=$teacherId, schoolId=$schoolId (from schoolId=${userDetails.schoolId}, school.id=${userDetails.school?.id})');
    context.read<ClassesCubit>().getClasses();
  }

  void getRecap({int? type}) {
    if (_selectedClassSection == null || _selectedMonth == null) {
      return;
    }
    // Add your logic here to fetch data based on selected year and month
    debugPrint('Getting recap for Year: $_selectedYear, Month: $_selectedMonth');
  }

  void _showMonthYearPicker() {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Bulan & Tahun',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _maroonPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Modern Year Selector - More compact to fix overflow
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: _maroonPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.chevron_left, color: _maroonPrimary, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setModalState(() => _selectedYear--);
                                },
                              ),
                              GestureDetector(
                                onTap: () {
                                  final TextEditingController yearController =
                                      TextEditingController(text: '$_selectedYear');
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Tahun'),
                                      content: TextField(
                                        controller: yearController,
                                        keyboardType: TextInputType.number,
                                        autofocus: true,
                                        decoration: const InputDecoration(
                                          hintText: 'Contoh: 2024',
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Batal'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            final int? newYear =
                                                int.tryParse(yearController.text);
                                            if (newYear != null && newYear > 1900 && newYear < 2100) {
                                              setModalState(() {
                                                _selectedYear = newYear;
                                              });
                                              Navigator.pop(context);
                                            }
                                          },
                                          child: const Text('Simpan'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    '$_selectedYear',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: _maroonPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.chevron_right, color: _maroonPrimary, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setModalState(() => _selectedYear++);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(),

                  // Month Grid
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.0,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final monthIndex = index + 1;
                        final isSelected = _selectedMonth == monthIndex;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedMonth = monthIndex;
                            });
                            Navigator.pop(context);
                            getRecap();
                          },
                          borderRadius: BorderRadius.circular(15),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected ? _maroonPrimary : Colors.grey[100],
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: _maroonPrimary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ] : [],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              months[index],
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : Colors.grey[700],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Action Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Tutup',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void navigateToRecap(int classId, int classSectionId, int month,
      {bool isDownload = false, int? passedSchoolId}) async {
    final user = AuthRepository.getUserDetails();
    final bool isStaff = (user.staff != null && user.staff!.id != null) ||
        user.getRoles().toLowerCase().contains("staff");

    final String token = AuthRepository.getAuthToken();
    final String apiToken = token.split("|").last;
    final String userSchoolId = user.schoolId.toString();

    // Jika staff, gunakan staff!.id, jika guru gunakan teacher!.id
    final String userParam = isStaff
        ? "staff_id=${user.staff?.id ?? user.id}"
        : "teacher_id=${user.teacher?.id ?? user.id}";

    // Gunakan passedSchoolId jika ada, jika tidak gunakan userSchoolId
    final effectiveSchoolId = (passedSchoolId?.toString()) ?? userSchoolId;

    debugPrint(
        "[RecapSubject] navigateToRecap called: effectiveSchoolId=$effectiveSchoolId, classId=$classId, classSectionId=$classSectionId, month=$month, year=$_selectedYear, download=$isDownload");

    if (effectiveSchoolId.isEmpty) {
      debugPrint("[RecapSubject] Navigate aborted: schoolId is empty");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Gagal navigasi: ID Sekolah tidak ditemukan. Silakan login ulang.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final String url = "${Api.recapDownload}?"
        "school_id=$effectiveSchoolId"
        "&token=$token"
        "&api_token=$apiToken"
        "&$userParam"
        "&month=$month"
        "&year=$_selectedYear"
        "&class_id=$classId"
        "&class_section_id=$classSectionId"
        "&type=api"
        "&gm=1"
        "${isDownload ? '&download=1' : ''}";

    if (isDownload) {
      debugPrint("[RecapSubject] Showing download dialog for: $url");
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => DownloadAttendanceRecapDialog(
          url: url,
          fileName: "Rekap-Absensi-$month-$_selectedYear",
          isPreview: false,
        ),
      );
    } else {
      debugPrint("[RecapSubject] Showing preview dialog for: $url");
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => DownloadAttendanceRecapDialog(
          url: url,
          fileName: "Preview-Rekap-Absensi-$month-$_selectedYear",
          isPreview: true,
        ),
      );
    }
  }

  void filterClassSections(List<ClassSection> classSections, int teacherId) {
    _filteredClassSections = classSections.where((classSection) {
      if (classSection.classTeachers == null ||
          classSection.classTeachers!.isEmpty) {
        return false;
      }

      for (var classTeacher in classSection.classTeachers!) {
        if (classTeacher.teacher?.id == teacherId &&
            classTeacher.teacherId == teacherId &&
            classTeacher.classSectionId == classSection.id) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  String _getMonthName(int month) {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return months[month - 1];
  }

  Widget _buildRecapTable(List<ClassSection> classes) {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        // Adjust top padding to position content below the app bar
        top: 180, // Reduced padding to minimize white space
        bottom: 25,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recap attendance container
          RecapAttendanceContainer(
            classSections: classes,
            selectedYear: _selectedYear,
            selectedMonth: _selectedMonth,
            email: email,
            schoolId: schoolId,
            onDownload: (classSection, month) {
              debugPrint('[RecapSubject] onDownload callback: class=${classSection.name}, classId=${classSection.classDetails?.id ?? classSection.classId}, classSectionId=${classSection.id}, schoolId=${classSection.schoolId}, month=$month');
              final classId =
                  classSection.classDetails?.id ?? classSection.classId ?? 0;
              final classSectionId = classSection.id ?? 0;
              navigateToRecap(classId, classSectionId, month, 
                  isDownload: true, passedSchoolId: classSection.schoolId);
            },
            onPreview: (classSection, month) {
              debugPrint('[RecapSubject] onPreview callback: class=${classSection.name}, classId=${classSection.classDetails?.id ?? classSection.classId}, classSectionId=${classSection.id}, schoolId=${classSection.schoolId}, month=$month');
              final classId =
                  classSection.classDetails?.id ?? classSection.classId ?? 0;
              final classSectionId = classSection.id ?? 0;
              navigateToRecap(classId, classSectionId, month,
                  isDownload: false, passedSchoolId: classSection.schoolId);
            },
          ).animate().fadeIn(duration: 500.ms).slideY(
                begin: 0.05,
                end: 0,
                curve: Curves.easeOutQuad,
                duration: 500.ms,
              ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return CustomModernAppBar(
      title: Utils.getTranslatedLabel(recapAttendanceSubjectKey),
      icon: Icons.receipt_long_rounded,
      fabAnimationController: _fabAnimationController,
      primaryColor: _maroonPrimary,
      lightColor: _maroonLight,
      onBackPressed: () => Navigator.of(context).pop(),
      height: 150, // Increased height to accommodate the tab filter
      tabBuilder: (context) {
        return BlocBuilder<ClassesCubit, ClassesState>(
          builder: (context, state) {
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _showMonthYearPicker();
                },
                borderRadius: BorderRadius.circular(12),
                highlightColor: Colors.white.withValues(alpha: 0.1),
                splashColor: Colors.white.withValues(alpha: 0.2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.9),
                              Colors.white.withValues(alpha: 0.4),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          color: _maroonPrimary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedMonth != null
                            ? '${_getMonthName(_selectedMonth!)} $_selectedYear'
                            : 'Pilih Bulan & Tahun',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            const Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          BlocBuilder<ClassesCubit, ClassesState>(
            builder: (context, state) {
              if (state is ClassesFetchSuccess) {
                // Get ALL classes (both primary and other)
                List<ClassSection> allClasses =
                    context.read<ClassesCubit>().getAllClasses();

                // Debugging to check if we're getting classes
                debugPrint(
                    "Received ${allClasses.length} total classes (primary + other)");

                if (teacherId != null) {
                  // Process for teacher's classes
                  // First try to filter by teacher ID
                  filterClassSections(allClasses, teacherId!);

                  // If no filtered classes found, just show all classes
                  if (_filteredClassSections.isEmpty) {
                    debugPrint(
                        "No filtered classes found, showing all ${allClasses.length} classes");
                    return _buildRecapTable(allClasses);
                  } else {
                    debugPrint(
                        "Found ${_filteredClassSections.length} classes for teacher ID: $teacherId");
                    return _buildRecapTable(_filteredClassSections);
                  }
                } else {
                  // If teacherId is null, show all classes
                  debugPrint("Teacher ID is null, showing all classes");
                  return _buildRecapTable(allClasses);
                }
              }
              if (state is ClassesFetchFailure) {
                return Padding(
                  padding: EdgeInsets.only(
                    top: topPaddingOfErrorAndLoadingContainer,
                  ),
                  child: CustomErrorWidget(
                    message: ErrorMessageUtils.getReadableErrorMessage(
                        state.errorMessage),
                    onRetry: () {
                      context.read<ClassesCubit>().getClasses();
                    },
                    primaryColor: _maroonPrimary,
                  ),
                );
              }
              return Center(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: topPaddingOfErrorAndLoadingContainer,
                  ),
                  child: const SkeletonRecapAttendanceScreen(itemCount: 6),
                ),
              );
            },
          ),
          _buildAppBar(),
        ],
      ),
    );
  }
}
