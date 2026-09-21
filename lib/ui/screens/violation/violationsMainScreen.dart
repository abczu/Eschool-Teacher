import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/cubits/academics/classesCubit.dart';
import 'package:eschool_saas_staff/cubits/violation/exportViolationPdfCubit.dart';
import 'package:eschool_saas_staff/cubits/violation/violationRoleCheckCubit.dart';
import 'package:eschool_saas_staff/cubits/violation/violationStudentsCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/models/violation/studentAvatarHelper.dart';
import 'package:eschool_saas_staff/data/models/violation/studentViolationItem.dart';
import 'package:eschool_saas_staff/data/models/violation/violationRoleCheck.dart';
import 'package:eschool_saas_staff/data/models/violation/violationSanctionHelper.dart';
import 'package:eschool_saas_staff/ui/screens/violation/widgets/violationFilterBottomSheet.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customCircularProgressIndicator.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/snackBarUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';

class ViolationsMainScreen extends StatefulWidget {
  const ViolationsMainScreen({super.key});

  static Widget getRouteInstance() {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ViolationRoleCheckCubit()..checkRoles()),
        BlocProvider(create: (_) => ViolationStudentsCubit()),
        BlocProvider(create: (_) => ExportViolationPdfCubit()),
        BlocProvider(create: (_) => ClassesCubit()..getClasses()),
      ],
      child: const ViolationsMainScreen(),
    );
  }

  @override
  State<ViolationsMainScreen> createState() => _ViolationsMainScreenState();
}

class _ViolationsMainScreenState extends State<ViolationsMainScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _appBarAnimationController;
  Timer? _searchDebounce;

  // Active Tab: 0 = Siswa Full (Kesiswaan), 1 = Siswa Kelas (Wali Kelas)
  int _activeTabIndex = 0;
  bool _hasInitializedTab = false;

  // Filter state
  int? _selectedClassId;
  String? _selectedSortBy;
  String? _selectedFilter; // homeroom only: all, with_points, clean

  @override
  void initState() {
    super.initState();
    _appBarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _scrollController.addListener(_onScroll);

    // Langsung muat data awal dan sesuaikan tab begitu screen aktif
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final roleState = context.read<ViolationRoleCheckCubit>().state;
        ViolationRoleCheck? rawCheck;
        if (roleState is ViolationRoleCheckSuccess) {
          rawCheck = roleState.roleCheck;
        }
        final effectiveRole = _resolveRoleCheck(rawCheck);
        _setupInitialTabAndFetch(effectiveRole);
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _appBarAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_activeTabIndex == 0) {
        context.read<ViolationStudentsCubit>().loadMoreKesiswaanStudents();
      }
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      if (_activeTabIndex == 0) {
        context.read<ViolationStudentsCubit>().getKesiswaanStudents(
              classId: _selectedClassId,
              sortBy: _selectedSortBy,
              search: query,
              isRefresh: false,
            );
      } else {
        // Tab wali kelas: filter pencarian secara instan di UI lokal
        setState(() {});
      }
    });
  }

  ViolationRoleCheck _resolveRoleCheck(ViolationRoleCheck? rawCheck) {
    final classesState = context.read<ClassesCubit>().state;
    List<ClassSection> primaryClasses = [];
    if (classesState is ClassesFetchSuccess) {
      primaryClasses = classesState.primaryClasses;
    }

    bool isKesiswaan = rawCheck?.isKesiswaan ?? false;
    bool isHomeroom = rawCheck?.isHomeroom ?? false;
    List<HomeroomClass> homeroomClasses =
        List.from(rawCheck?.homeroomClasses ?? []);

    // Jika guru memiliki kelas perwalian di sistem tapi API role check belum terisi
    if (!isHomeroom && primaryClasses.isNotEmpty) {
      isHomeroom = true;
      if (homeroomClasses.isEmpty) {
        homeroomClasses = primaryClasses
            .map((c) => HomeroomClass(
                  classId: c.id ?? c.classId ?? 0,
                  className: c.fullName ?? c.name ?? 'Kelas Perwalian',
                ))
            .toList();
      }
    }

    // Jika keduanya false (akun guru umum), fallback agar UI langsung menampilkan list siswa
    if (!isKesiswaan && !isHomeroom) {
      if (primaryClasses.isNotEmpty) {
        isHomeroom = true;
      } else {
        isKesiswaan = true;
      }
    }

    return ViolationRoleCheck(
      isKesiswaan: isKesiswaan,
      isHomeroom: isHomeroom,
      homeroomClasses: homeroomClasses,
    );
  }

  void _setupInitialTabAndFetch(ViolationRoleCheck roleCheck) {
    if (_hasInitializedTab) return;
    _hasInitializedTab = true;

    // Aturan Penentuan Tab Sesuai Role:
    // 1. Walas saja: hanya menampilkan siswa kelasnya saja (_activeTabIndex = 1)
    // 2. Kesiswaan saja: hanya menampilkan siswa full (_activeTabIndex = 0)
    // 3. Walas DAN Kesiswaan: ada dua opsi, default ke siswa kelas perwaliannya
    if (roleCheck.isHomeroom && !roleCheck.isKesiswaan) {
      _activeTabIndex = 1;
    } else if (roleCheck.isKesiswaan && !roleCheck.isHomeroom) {
      _activeTabIndex = 0;
    } else if (roleCheck.isHomeroom && roleCheck.isKesiswaan) {
      _activeTabIndex = 1; // Walas & Kesiswaan: default ke kelasnya, bisa switch ke siswa full
    } else {
      _activeTabIndex = 0;
    }

    _fetchStudentsForCurrentTab(roleCheck);
  }

  void _fetchStudentsForCurrentTab(ViolationRoleCheck roleCheck) {
    if (_activeTabIndex == 0) {
      // Siswa Full (Kesiswaan / Satu Sekolah)
      context.read<ViolationStudentsCubit>().getKesiswaanStudents(
            classSectionId: _selectedClassId,
            sortBy: _selectedSortBy,
            search: _searchController.text,
          );
    } else {
      // Siswa Kelas (Wali Kelas)
      context.read<ViolationStudentsCubit>().getHomeroomStudents(
            classSectionId: _selectedClassId,
            filter: _selectedFilter,
            sortBy: _selectedSortBy,
          );
    }
  }

  void _openFilter(ViolationRoleCheck roleCheck) {
    final classesState = context.read<ClassesCubit>().state;
    List<ClassSection> allClasses = [];
    if (classesState is ClassesFetchSuccess) {
      allClasses = [
        ...classesState.primaryClasses,
        ...classesState.classes,
      ];
    }

    final isHomeroom = _activeTabIndex == 1;

    ViolationFilterBottomSheet.show(
      context,
      isHomeroomView: isHomeroom,
      allClasses: allClasses,
      homeroomClasses: roleCheck.homeroomClasses,
      currentClassId: _selectedClassId,
      currentSortBy: _selectedSortBy,
      currentFilter: _selectedFilter,
      onApply: ({classId, sortBy, filter}) {
        setState(() {
          _selectedClassId = classId;
          _selectedSortBy = sortBy;
          _selectedFilter = filter;
        });
        _fetchStudentsForCurrentTab(roleCheck);
      },
    );
  }

  String _getAppBarSubtitle(ViolationRoleCheck roleCheck) {
    if (roleCheck.isHomeroom && !roleCheck.isKesiswaan) {
      return "Siswa Kelas Perwalian";
    } else if (roleCheck.isKesiswaan && !roleCheck.isHomeroom) {
      return "Kedisiplinan & Poin Sanksi";
    } else {
      return _activeTabIndex == 1
          ? "Siswa Kelas Perwalian"
          : "Kedisiplinan Siswa (Semua)";
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF8B1F41);

    return BlocConsumer<ExportViolationPdfCubit, ExportViolationPdfState>(
      listener: (context, exportState) {
        if (exportState is ExportViolationPdfSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Laporan PDF berhasil diunduh!"),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: "Buka",
                textColor: Colors.white,
                onPressed: () {
                  OpenFilex.open(exportState.filePath);
                },
              ),
            ),
          );
        } else if (exportState is ExportViolationPdfFailure) {
          SnackBarUtils.showSnackBar(
            context: context,
            message: exportState.errorMessage,
            backgroundColor: Colors.redAccent,
          );
        }
      },
      builder: (context, exportState) {
        return BlocConsumer<ViolationRoleCheckCubit, ViolationRoleCheckState>(
          listener: (context, roleState) {
            if (roleState is ViolationRoleCheckSuccess) {
              final roleCheck = _resolveRoleCheck(roleState.roleCheck);
              if (!_hasInitializedTab) {
                _setupInitialTabAndFetch(roleCheck);
              }
              setState(() {});
            }
          },
          builder: (context, roleState) {
            ViolationRoleCheck? rawCheck;
            if (roleState is ViolationRoleCheckSuccess) {
              rawCheck = roleState.roleCheck;
            }
            final ViolationRoleCheck roleCheck = _resolveRoleCheck(rawCheck);

            // Kondisi: Hanya tampilkan tab selector jika guru adalah Walas DAN Kesiswaan
            final bool showTabs = roleCheck.isKesiswaan && roleCheck.isHomeroom;

            return Scaffold(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).scaffoldBackgroundColor
                  : Colors.grey.shade50,
              appBar: CustomModernAppBar(
                title: "Pelanggaran Siswa",
                subtitle: _getAppBarSubtitle(roleCheck),
                icon: Icons.shield_outlined,
                fabAnimationController: _appBarAnimationController,
                primaryColor: const Color(0xFF8B1F41),
                lightColor: const Color(0xFFAC3B5C),
                onBackPressed: () => Get.back(),
                height: 85,
              ),
              body: Column(
                children: [

                  // 1. Tab Selector (HANYA MUNCUL jika Walas DAN Kesiswaan)
                  if (showTabs) _buildSegmentedTabBar(primaryColor, roleCheck),

                  // 2. Search Bar & Filter Button
                  _buildSearchBar(primaryColor, roleCheck),

                  // 3. Main List Siswa
                  Expanded(
                    child: BlocConsumer<ViolationStudentsCubit,
                        ViolationStudentsState>(
                      listener: (context, studentsState) {
                        if (studentsState is ViolationStudentsFetchSuccess) {
                          StudentAvatarHelper.loadAvatarsForStudents(
                            studentsState.students,
                            onLoaded: () {
                              if (mounted) setState(() {});
                            },
                          );
                        }
                      },
                      builder: (context, studentsState) {
                        if (studentsState is ViolationStudentsFetchInProgress) {
                          return const Center(
                            child: CustomCircularProgressIndicator(),
                          );
                        }

                        if (studentsState is ViolationStudentsFetchFailure) {
                          return CustomErrorWidget(
                            message: studentsState.errorMessage,
                            onRetry: () =>
                                _fetchStudentsForCurrentTab(roleCheck),
                          );
                        }

                        if (studentsState is ViolationStudentsFetchSuccess) {
                          List<StudentViolationItem> students =
                              studentsState.students;

                          // Trigger background avatar loading
                          StudentAvatarHelper.loadAvatarsForStudents(
                            students,
                            onLoaded: () {
                              if (mounted) setState(() {});
                            },
                          );

                          // Filter lokal untuk kelas jika filter kelas aktif (safety net)
                          if (_selectedClassId != null) {
                            String? targetClassName;
                            final classesState =
                                context.read<ClassesCubit>().state;
                            if (classesState is ClassesFetchSuccess) {
                              final match = [
                                ...classesState.primaryClasses,
                                ...classesState.classes,
                              ]
                                  .where((c) => c.id == _selectedClassId)
                                  .firstOrNull;
                              targetClassName =
                                  match?.fullName?.toLowerCase().trim();
                            }

                            students = students.where((s) {
                              if (s.classId != null && s.classId! > 0) {
                                return s.classId == _selectedClassId;
                              }
                              if (targetClassName != null &&
                                  s.className != null &&
                                  s.className!.trim().isNotEmpty) {
                                return s.className!.toLowerCase().trim() ==
                                    targetClassName;
                              }
                              return true;
                            }).toList();
                          }

                          // Filter lokal untuk nama siswa jika berada di tab Wali Kelas
                          if (_activeTabIndex == 1 &&
                              _searchController.text.trim().isNotEmpty) {
                            final q =
                                _searchController.text.trim().toLowerCase();
                            students = students
                                .where((s) =>
                                    s.studentName.toLowerCase().contains(q) ||
                                    (s.nisn?.toLowerCase().contains(q) ??
                                        false))
                                .toList();
                          }

                          if (students.isEmpty) {
                            return RefreshIndicator(
                              onRefresh: () async =>
                                  _fetchStudentsForCurrentTab(roleCheck),
                              child: ListView(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.2),
                                  Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.sentiment_satisfied_alt_rounded,
                                          size: 64,
                                          color: Colors.green.shade400,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _activeTabIndex == 1
                                              ? "Tidak ada data siswa ditemukan di kelas ini"
                                              : "Tidak ada siswa dengan catatan pelanggaran",
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _activeTabIndex == 1
                                              ? "Semua siswa kelas ini dalam status tertib / tidak ada pelanggaran."
                                              : "Semua siswa dalam status tertib / 0 poin sanksi.",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: () async =>
                                _fetchStudentsForCurrentTab(roleCheck),
                            child: ListView.separated(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              itemCount: students.length +
                                  (studentsState.isLoadingMore ? 1 : 0),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                if (index == students.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child:
                                          CustomCircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final item = students[index];
                                return _buildStudentCard(
                                  item: item,
                                  primaryColor: primaryColor,
                                  isKesiswaan: roleCheck.isKesiswaan,
                                  onTap: () async {
                                    final refreshed = await Get.toNamed(
                                      Routes.studentViolationDetailScreen,
                                      arguments: {
                                        'studentId': item.studentId,
                                        'studentName': item.studentName,
                                        'isKesiswaan': roleCheck.isKesiswaan,
                                      },
                                    );
                                    if (refreshed == true) {
                                      _fetchStudentsForCurrentTab(roleCheck);
                                    }
                                  },
                                );
                              },
                            ),
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
              floatingActionButton: roleCheck.isKesiswaan
                  ? FloatingActionButton.extended(
                      onPressed: () async {
                        final result = await Get.toNamed(
                          Routes.giveViolationPointsScreen,
                        );
                        if (result == true) {
                          _fetchStudentsForCurrentTab(roleCheck);
                        }
                      },
                      backgroundColor: const Color(0xFF8B1F41),
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      label: Text(
                        "Tambah Poin",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            );
          },
        );
      },
    );
  }
  Widget _buildSegmentedTabBar(
      Color primaryColor, ViolationRoleCheck roleCheck) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Opsi 1: Siswa Kelas (Menampilkan yang kelasnya saja)
          Expanded(
            child: InkWell(
              onTap: () {
                if (_activeTabIndex != 1) {
                  setState(() {
                    _activeTabIndex = 1;
                    _selectedClassId = null;
                    _selectedSortBy = 'attendance_number';
                    _selectedFilter = 'all';
                  });
                  _fetchStudentsForCurrentTab(roleCheck);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTabIndex == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _activeTabIndex == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.groups_rounded,
                      size: 18,
                      color: _activeTabIndex == 1
                          ? primaryColor
                          : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Siswa Kelas",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: _activeTabIndex == 1
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: _activeTabIndex == 1
                            ? primaryColor
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Opsi 2: Siswa Full (Menampilkan siswa seluruh sekolah / kesiswaan)
          Expanded(
            child: InkWell(
              onTap: () {
                if (_activeTabIndex != 0) {
                  setState(() {
                    _activeTabIndex = 0;
                    _selectedClassId = null;
                    _selectedSortBy = 'highest_points';
                  });
                  _fetchStudentsForCurrentTab(roleCheck);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTabIndex == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _activeTabIndex == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.public_rounded,
                      size: 18,
                      color: _activeTabIndex == 0
                          ? primaryColor
                          : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Siswa Full",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: _activeTabIndex == 0
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: _activeTabIndex == 0
                            ? primaryColor
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(Color primaryColor, ViolationRoleCheck roleCheck) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: "Cari nama siswa / NISN...",
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () => _openFilter(roleCheck),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: _selectedClassId != null ||
                        (_selectedFilter != null && _selectedFilter != 'all')
                    ? primaryColor
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _selectedClassId != null ||
                          (_selectedFilter != null && _selectedFilter != 'all')
                      ? primaryColor
                      : Colors.grey.shade300,
                ),
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 22,
                color: _selectedClassId != null ||
                        (_selectedFilter != null && _selectedFilter != 'all')
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard({
    required StudentViolationItem item,
    required Color primaryColor,
    required bool isKesiswaan,
    required VoidCallback onTap,
  }) {
    final sanction = ViolationSanctionHelper.getSanctionLevel(
      item.totalPoints,
      customStatusName: item.sanctionName,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Builder(
              builder: (context) {
                final avatar = item.displayAvatarUrl;
                final fullAvatar = (avatar != null && avatar.trim().isNotEmpty)
                    ? StudentAvatarHelper.formatImageUrl(avatar.trim())
                    : null;

                if (fullAvatar != null) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: CachedNetworkImage(
                      imageUrl: fullAvatar,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 200),
                      fadeOutDuration: const Duration(milliseconds: 100),
                      placeholder: (context, url) => Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: primaryColor.withValues(alpha: 0.4),
                          size: 26,
                        ),
                      ),
                    ),
                  );
                }

                return Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: primaryColor.withValues(alpha: 0.4),
                    size: 26,
                  ),
                );
              },
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.studentName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${item.className ?? '-'} ${item.rollNumber != null ? '• Absen ${item.rollNumber}' : ''}",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Sanction Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: sanction.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(sanction.icon,
                            size: 13, color: sanction.primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          sanction.title,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: sanction.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Poin Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sanction.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: sanction.primaryColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    "${item.totalPoints}",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: sanction.textColor,
                    ),
                  ),
                  Text(
                    "Poin",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: sanction.textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
