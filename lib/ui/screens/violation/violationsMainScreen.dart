import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/cubits/academics/classesCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/gradeLevelCubit.dart';
import 'package:eschool_saas_staff/cubits/violation/exportViolationPdfCubit.dart';
import 'package:eschool_saas_staff/cubits/violation/violationRoleCheckCubit.dart';
import 'package:eschool_saas_staff/cubits/violation/violationStudentsCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/models/violation/studentAvatarHelper.dart';
import 'package:eschool_saas_staff/data/models/violation/studentViolationItem.dart';
import 'package:eschool_saas_staff/data/models/violation/violationRoleCheck.dart';
import 'package:eschool_saas_staff/data/models/violation/violationSanctionHelper.dart';
import 'package:eschool_saas_staff/ui/screens/violation/widgets/violationFilterBottomSheet.dart';
import 'package:eschool_saas_staff/ui/screens/violation/widgets/violationPdfBottomSheet.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customCircularProgressIndicator.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/utils/system/violationPdfUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ViolationsMainScreen extends StatefulWidget {
  const ViolationsMainScreen({super.key});

  static Widget getRouteInstance() {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ViolationRoleCheckCubit()..checkRoles()),
        BlocProvider(create: (_) => ViolationStudentsCubit()),
        BlocProvider(create: (_) => ExportViolationPdfCubit()),
        BlocProvider(create: (_) => GradeLevelCubit()..getGradeLevels()),
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

  /// True saat bottom sheet rekap PDF terbuka. Dipakai agar snackbar
  /// dari listener layar tidak bentrok dengan feedback di dalam sheet.
  bool _isPdfSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _appBarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _scrollController.addListener(_onScroll);

    // JANGAN tebak role di sini: ViolationRoleCheck & Classes masih loading.
    // Tab + fetch pertama dilakukan setelah role benar-benar loaded
    // (lihat listener ViolationRoleCheck di build). Ini mencegah walas-only
    // salah memanggil endpoint all-students (400 "Hanya Kesiswaan...").
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
    // Update ikon clear & filter lokal homeroom secara instan
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      if (_activeTabIndex == 0) {
        // Tab kesiswaan: cari via backend TANPA loader fullscreen
        // agar list tidak kedip setiap ketik. Hasil backend tetap
        // difilter ulang secara lokal di builder sebagai safety net.
        context.read<ViolationStudentsCubit>().getKesiswaanStudents(
              classSectionId: _selectedClassId,
              sortBy: _selectedSortBy,
              search: query.trim(),
              isRefresh: true,
            );
      } else {
        // Tab wali kelas: filter pencarian secara instan di UI lokal
        if (mounted) setState(() {});
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

    // Fallback saat backend belum memastikan role apa pun (misal masih
    // loading / offline): JANGAN pernah menebak isKesiswaan=true.
    // Akses kesiswaan (FAB Tambah Poin, endpoint all-students) hanya untuk
    // flag asli dari backend. Menaikkan isHomeroom dari primaryClasses di
    // atas sudah cukup agar guru tetap melihat list kelasnya.

    return ViolationRoleCheck(
      isKesiswaan: isKesiswaan,
      isHomeroom: isHomeroom,
      homeroomClasses: homeroomClasses,
    );
  }

  /// Fallback classId untuk walas: _selectedClassId → homeroomClasses →
  /// primaryClasses. Menutupi response homeroom yang flat tanpa class_id,
  /// agar avatar (foto web) + nama kelas tampil sama seperti kesiswaan.
  int? _resolveFallbackClassId(ViolationRoleCheck roleCheck) {
    if (_selectedClassId != null && _selectedClassId! > 0) {
      return _selectedClassId;
    }
    if (roleCheck.homeroomClasses.isNotEmpty &&
        roleCheck.homeroomClasses.first.classId > 0) {
      return roleCheck.homeroomClasses.first.classId;
    }
    final classesState = context.read<ClassesCubit>().state;
    if (classesState is ClassesFetchSuccess) {
      final all = [
        ...classesState.primaryClasses,
        ...classesState.classes,
      ];
      if (_selectedClassId != null) {
        final match = all.where((c) => c.id == _selectedClassId).firstOrNull;
        final id = match?.id ?? match?.classId ?? 0;
        if (id > 0) return id;
      }
      if (all.isNotEmpty) {
        final id = all.first.id ?? all.first.classId ?? 0;
        if (id > 0) return id;
      }
    }
    return null;
  }

  /// Fallback nama kelas untuk walas saat item.className null/kosong,
  /// agar baris info kelas tampil sama seperti kartu kesiswaan.
  String? _resolveFallbackClassName(ViolationRoleCheck roleCheck) {
    final classesState = context.read<ClassesCubit>().state;
    if (classesState is ClassesFetchSuccess) {
      final all = [
        ...classesState.primaryClasses,
        ...classesState.classes,
      ];
      final targetId = _resolveFallbackClassId(roleCheck);
      if (targetId != null) {
        final match = all.where((c) => c.id == targetId).firstOrNull;
        final name = match?.fullName ?? match?.name;
        if (name != null && name.trim().isNotEmpty) return name.trim();
      }
      if (all.isNotEmpty) {
        final name = all.first.fullName ?? all.first.name;
        if (name != null && name.trim().isNotEmpty) return name.trim();
      }
    }
    if (roleCheck.homeroomClasses.isNotEmpty) {
      final name = roleCheck.homeroomClasses.first.className.trim();
      if (name.isNotEmpty) return name;
    }
    return null;
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
      _activeTabIndex =
          1; // Walas & Kesiswaan: default ke kelasnya, bisa switch ke siswa full
    } else {
      _activeTabIndex = 0;
    }

    _fetchStudentsForCurrentTab(roleCheck);
  }

  /// Koreksi tab jika tidak sesuai role final.
  /// Dipanggil setiap kali role check / daftar kelas selesai loaded,
  /// untuk memperbaiki kasus init dini yang salah tab.
  void _syncTabWithRole(ViolationRoleCheck roleCheck) {
    if (!_hasInitializedTab) {
      _setupInitialTabAndFetch(roleCheck);
      return;
    }
    int? expected;
    if (roleCheck.isHomeroom && !roleCheck.isKesiswaan) {
      expected = 1; // Walas saja -> wajib tab kelas perwalian
    } else if (roleCheck.isKesiswaan && !roleCheck.isHomeroom) {
      expected = 0; // Kesiswaan saja -> wajib tab siswa full
    }
    // Dual role (keduanya true): biarkan pilihan user, jangan paksa pindah.
    if (expected != null && _activeTabIndex != expected) {
      setState(() {
        _activeTabIndex = expected!;
        _selectedClassId = null;
      });
      _fetchStudentsForCurrentTab(roleCheck);
    }
  }

  /// Fetch siswa untuk tab aktif.
  /// [isRefresh] = true dipakai pull-to-refresh agar tidak tampil loader
  /// fullscreen (indikator RefreshIndicator yang tampil) dan data terbaru
  /// dari backend (misal poin baru via web) langsung diambil ulang.
  Future<void> _fetchStudentsForCurrentTab(
    ViolationRoleCheck roleCheck, {
    bool isRefresh = false,
  }) {
    // GUARD: jangan pernah panggil endpoint kesiswaan untuk akun non-kesiswaan.
    // Backend mengembalikan 400 "Hanya Kesiswaan yang berwenang...".
    // Walas-only wajib memakai endpoint homeroom (otomatis scope kelas perwalian).
    if (_activeTabIndex == 0 && !roleCheck.isKesiswaan) {
      _activeTabIndex = 1;
      if (mounted) setState(() {});
      return context.read<ViolationStudentsCubit>().getHomeroomStudents(
            classSectionId: _selectedClassId,
            filter: _selectedFilter,
            sortBy: _selectedSortBy,
            isRefresh: isRefresh,
          );
    }
    if (_activeTabIndex == 1 &&
        !roleCheck.isHomeroom &&
        roleCheck.isKesiswaan) {
      _activeTabIndex = 0;
      if (mounted) setState(() {});
    }
    if (_activeTabIndex == 0) {
      // Siswa Full (Kesiswaan / Satu Sekolah)
      return context.read<ViolationStudentsCubit>().getKesiswaanStudents(
            classSectionId: _selectedClassId,
            sortBy: _selectedSortBy,
            search: _searchController.text,
            isRefresh: isRefresh,
          );
    } else {
      // Siswa Kelas (Wali Kelas)
      return context.read<ViolationStudentsCubit>().getHomeroomStudents(
            classSectionId: _selectedClassId,
            filter: _selectedFilter,
            sortBy: _selectedSortBy,
            isRefresh: isRefresh,
          );
    }
  }

  /// Handler khusus pull-to-refresh: bersihkan cache avatar agar foto
  /// terbaru ikut diambil, lalu fetch ulang data siswa dari backend.
  Future<void> _handlePullRefresh(ViolationRoleCheck roleCheck) async {
    StudentAvatarHelper.clearCache();
    await _fetchStudentsForCurrentTab(roleCheck, isRefresh: true);
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

  /// Nama kelas untuk label rekap PDF. Mengutamakan pilihan filter kelas,
  /// lalu daftar kelas perwalian / daftar kelas dari API.
  String? _findClassName(int? classId) {
    if (classId == null || classId <= 0) return null;

    final classesState = context.read<ClassesCubit>().state;
    if (classesState is ClassesFetchSuccess) {
      for (final classSection in [
        ...classesState.primaryClasses,
        ...classesState.classes,
      ]) {
        final id = classSection.id ?? classSection.classId;
        if (id != classId) continue;
        final name = (classSection.fullName ?? classSection.name ?? '').trim();
        if (name.isNotEmpty) return name;
      }
    }

    return null;
  }

  String _buildPdfScopeLabel(ViolationRoleCheck roleCheck) {
    final selectedClassName = _findClassName(_selectedClassId);
    if (selectedClassName != null) return selectedClassName;

    if (_activeTabIndex == 1) {
      if (roleCheck.homeroomClasses.length == 1) {
        final name = roleCheck.homeroomClasses.first.className.trim();
        if (name.isNotEmpty) return name;
      }
      if (roleCheck.homeroomClasses.length > 1) {
        return 'Semua Kelas Perwalian (${roleCheck.homeroomClasses.length} kelas)';
      }
      return 'Kelas Perwalian';
    }

    return 'Seluruh Sekolah';
  }

  String? _buildPdfFilterLabel() {
    if (_activeTabIndex != 1) return null;

    switch ((_selectedFilter ?? 'all').toLowerCase()) {
      case 'with_points':
        return 'Siswa berpoin';
      case 'clean':
        return 'Siswa bersih (0 poin)';
      default:
        return 'Semua siswa';
    }
  }

  /// ID kelas yang dikirim ke endpoint PDF.
  ///
  /// Walas dengan satu kelas perwalian selalu mengirim kelasnya secara
  /// eksplisit agar laporan tidak bergantung pada default backend.
  int? _resolvePdfClassSectionId(ViolationRoleCheck roleCheck) {
    if (_selectedClassId != null && _selectedClassId! > 0) {
      return _selectedClassId;
    }

    if (_activeTabIndex == 1 && roleCheck.homeroomClasses.length == 1) {
      final id = roleCheck.homeroomClasses.first.classId;
      return id > 0 ? id : null;
    }

    return null;
  }

  void _openPdfSheet(ViolationRoleCheck roleCheck) {
    final gradeLevelCubit = context.read<GradeLevelCubit>();
    if (gradeLevelCubit.state is! GradeLevelFetchSuccess &&
        gradeLevelCubit.state is! GradeLevelFetchInProgress) {
      gradeLevelCubit.getGradeLevels();
    }

    // Bersihkan state lama agar sheet selalu mulai dari pilihan awal.
    context.read<ExportViolationPdfCubit>().reset();

    _isPdfSheetOpen = true;
    ViolationPdfBottomSheet.show(
      context,
      isHomeroom: _activeTabIndex == 1,
      classSectionId: _resolvePdfClassSectionId(roleCheck),
      homeroomFilter: _activeTabIndex == 1 ? _selectedFilter : null,
      scopeLabel: _buildPdfScopeLabel(roleCheck),
      activeFilterLabel: _buildPdfFilterLabel(),
    ).whenComplete(() {
      _isPdfSheetOpen = false;
    });
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
        // Feedback utama (loading/sukses/gagal) ditangani langsung di
        // ViolationPdfBottomSheet. Listener ini hanya jaring pengaman
        // untuk kegagalan bila sheet sudah tertutup saat proses selesai.
        if (_isPdfSheetOpen) return;
        if (exportState is! ExportViolationPdfFailure) return;

        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(exportState.errorMessage),
              backgroundColor: Colors.redAccent,
            ),
          );
      },
      builder: (context, exportState) {
        return BlocConsumer<ViolationRoleCheckCubit, ViolationRoleCheckState>(
          listener: (context, roleState) {
            if (roleState is ViolationRoleCheckSuccess) {
              final roleCheck = _resolveRoleCheck(roleState.roleCheck);
              // Init pertama HANYA setelah role asli dari backend tiba,
              // plus auto-koreksi jika tab saat ini tidak sesuai role.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _syncTabWithRole(roleCheck);
                if (mounted) setState(() {});
              });
            } else if (roleState is ViolationRoleCheckFailure) {
              // Role gagal dimuat (misal offline): fallback agar walas
              // tetap bisa melihat kelasnya, bukan memanggil all-students.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                final fallback = _resolveRoleCheck(null);
                _syncTabWithRole(fallback);
                if (mounted) setState(() {});
              });
            }
          },
          builder: (context, roleState) {
            ViolationRoleCheck? rawCheck;
            if (roleState is ViolationRoleCheckSuccess) {
              rawCheck = roleState.roleCheck;
            }
            final ViolationRoleCheck roleCheck = _resolveRoleCheck(rawCheck);
            final bool isDark = Theme.of(context).brightness == Brightness.dark;
            final bool canExportPdf = canExportViolationPdf(
              isHomeroomTab: _activeTabIndex == 1,
              isHomeroom: roleCheck.isHomeroom,
              isKesiswaan: roleCheck.isKesiswaan,
              isRoleResolved: roleState is ViolationRoleCheckSuccess,
            );

            // Kondisi: Hanya tampilkan tab selector jika guru adalah Walas DAN Kesiswaan
            final bool showTabs = roleCheck.isKesiswaan && roleCheck.isHomeroom;

            // Dengarkan daftar kelas yang telat loaded: fallback walas
            // (_resolveRoleCheck) bergantung padanya, jadi sync ulang tab
            // saat kelas tiba agar tidak stuck di endpoint yang salah.
            return BlocListener<ClassesCubit, ClassesState>(
              listener: (context, classesState) {
                if (classesState is ClassesFetchSuccess) {
                  final roleState =
                      context.read<ViolationRoleCheckCubit>().state;
                  final raw = roleState is ViolationRoleCheckSuccess
                      ? roleState.roleCheck
                      : null;
                  // Hanya sync jika role backend sudah ada ATAU
                  // fallback kelas mengubah hasil resolve.
                  if (raw != null || !_hasInitializedTab) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      final resolved = _resolveRoleCheck(raw);
                      _syncTabWithRole(resolved);
                      // Kelas baru tiba → coba lengkapi foto walas yang
                      // sebelumnya skip karena fallbackClassId masih null.
                      final studentsState =
                          context.read<ViolationStudentsCubit>().state;
                      if (studentsState is ViolationStudentsFetchSuccess) {
                        StudentAvatarHelper.loadAvatarsForStudents(
                          studentsState.students,
                          fallbackClassId: _resolveFallbackClassId(resolved),
                          onLoaded: () {
                            if (mounted) setState(() {});
                          },
                        );
                      }
                      if (mounted) setState(() {});
                    });
                  }
                }
              },
              child: Scaffold(
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
                    if (showTabs)
                      _buildSegmentedTabBar(primaryColor, roleCheck, isDark),

                    // 2. Search Bar, Filter, & Rekap PDF
                    _buildSearchBar(
                      primaryColor,
                      roleCheck,
                      isDark,
                      canExportPdf,
                    ),

                    // 3. Main List Siswa
                    Expanded(
                      child: BlocConsumer<ViolationStudentsCubit,
                          ViolationStudentsState>(
                        listener: (context, studentsState) {
                          if (studentsState is ViolationStudentsFetchSuccess) {
                            StudentAvatarHelper.loadAvatarsForStudents(
                              studentsState.students,
                              fallbackClassId:
                                  _resolveFallbackClassId(roleCheck),
                              onLoaded: () {
                                if (mounted) setState(() {});
                              },
                            );
                          }
                        },
                        builder: (context, studentsState) {
                          if (studentsState
                              is ViolationStudentsFetchInProgress) {
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

                            // Trigger background avatar loading (foto web via student-list).
                            // fallbackClassId menutupi item walas yang classId-nya null,
                            // agar foto tampil sama seperti tab kesiswaan.
                            StudentAvatarHelper.loadAvatarsForStudents(
                              students,
                              fallbackClassId:
                                  _resolveFallbackClassId(roleCheck),
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

                            // Filter pencarian lokal — berlaku untuk SEMUA tab.
                            // Safety net: backend kadang mengabaikan param `search`,
                            // jadi pastikan list yang tampil benar-benar cocok
                            // dengan ketikan di search bar (nama / NISN / kelas).
                            final searchQuery =
                                _searchController.text.trim().toLowerCase();
                            if (searchQuery.isNotEmpty) {
                              students = students
                                  .where((s) =>
                                      s.studentName
                                          .toLowerCase()
                                          .contains(searchQuery) ||
                                      s.identitySearchValues.any((value) =>
                                          value
                                              .toLowerCase()
                                              .contains(searchQuery)) ||
                                      (s.className
                                              ?.toLowerCase()
                                              .contains(searchQuery) ??
                                          false) ||
                                      (s.rollNumber
                                              ?.toString()
                                              .contains(searchQuery) ??
                                          false))
                                  .toList();
                            }

                            // Filter status pelanggaran lokal (khusus walas).
                            // Safety net: backend kadang mengabaikan param `filter`,
                            // buktinya pilih "Bersih (0 Poin)" tapi siswa 5 poin
                            // tetap muncul. Filter di sini dijamin jalan.
                            final statusFilter = (_selectedFilter ??
                                    studentsState.selectedFilter ??
                                    'all')
                                .toLowerCase()
                                .trim();
                            if (_activeTabIndex == 1 ||
                                studentsState.isHomeroomView) {
                              if (statusFilter == 'with_points') {
                                students = students
                                    .where((s) => s.totalPoints > 0)
                                    .toList();
                              } else if (statusFilter == 'clean') {
                                students = students
                                    .where((s) => s.totalPoints <= 0)
                                    .toList();
                              }

                              // Sort lokal (safety net bila backend abaikan sort_by).
                              final sortKey = (_selectedSortBy ??
                                      studentsState.selectedSortBy ??
                                      'attendance_number')
                                  .toLowerCase()
                                  .trim();
                              if (sortKey == 'alphabetical') {
                                students.sort((a, b) => a.studentName
                                    .toLowerCase()
                                    .compareTo(b.studentName.toLowerCase()));
                              } else if (sortKey == 'highest_points') {
                                students.sort((a, b) =>
                                    b.totalPoints.compareTo(a.totalPoints));
                              } else {
                                // attendance_number (default): absen kecil dulu,
                                // yang tanpa nomor absen ditaruh paling bawah.
                                students.sort((a, b) => (a.rollNumber ?? 9999)
                                    .compareTo(b.rollNumber ?? 9999));
                              }
                            }

                            if (students.isEmpty) {
                              return RefreshIndicator(
                                onRefresh: () => _handlePullRefresh(roleCheck),
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
                                            Icons
                                                .sentiment_satisfied_alt_rounded,
                                            size: 64,
                                            color: Colors.green.shade400,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            searchQuery.isNotEmpty
                                                ? "Tidak ditemukan hasil untuk \"${_searchController.text.trim()}\""
                                                : (statusFilter == 'clean'
                                                    ? "Tidak ada siswa bersih (0 poin) di kelas ini"
                                                    : (statusFilter ==
                                                            'with_points'
                                                        ? "Tidak ada siswa dengan poin pelanggaran di kelas ini"
                                                        : (_activeTabIndex == 1
                                                            ? "Tidak ada data siswa ditemukan di kelas ini"
                                                            : "Tidak ada siswa dengan catatan pelanggaran"))),
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _activeTabIndex == 1
                                                ? "Semua siswa kelas ini dalam status tertib / tidak ada pelanggaran."
                                                : "Semua siswa dalam status tertib / 0 poin sanksi.",
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.white60
                                                  : Colors.grey.shade600,
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
                              onRefresh: () => _handlePullRefresh(roleCheck),
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
                                    isDark: isDark,
                                    fallbackClassName:
                                        _resolveFallbackClassName(roleCheck),
                                    onTap: () async {
                                      await Get.toNamed(
                                        Routes.studentViolationDetailScreen,
                                        arguments: {
                                          'studentId': item.studentId,
                                          'studentName': item.studentName,
                                          'isKesiswaan': roleCheck.isKesiswaan,
                                        },
                                      );
                                      // Selalu refresh saat kembali dari detail:
                                      // data bisa berubah (misal hapus riwayat di
                                      // detail) tanpa result back yang andal.
                                      if (context.mounted) {
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
                // FAB Tambah Poin: HANYA kesiswaan asli dari backend
                // (roleState success), bukan hasil fallback resolve. Dibungkus
                // BlocBuilder students agar FAB muncul BERSAMAAN dengan list
                // (setelah loading selesai), tidak mendahului kartu siswa.
                floatingActionButton: (roleState is ViolationRoleCheckSuccess &&
                        roleCheck.isKesiswaan)
                    ? BlocBuilder<ViolationStudentsCubit,
                        ViolationStudentsState>(
                        builder: (context, studentsState) {
                          if (studentsState is! ViolationStudentsFetchSuccess) {
                            return const SizedBox.shrink();
                          }
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutBack,
                            builder: (context, value, child) =>
                                Transform.scale(scale: value, child: child),
                            child: FloatingActionButton.extended(
                              onPressed: () async {
                                final result = await Get.toNamed(
                                  Routes.giveViolationPointsScreen,
                                );
                                if (result == true && context.mounted) {
                                  _fetchStudentsForCurrentTab(roleCheck);
                                }
                              },
                              backgroundColor: const Color(0xFF8B1F41),
                              icon: const Icon(Icons.add_rounded,
                                  color: Colors.white),
                              label: Text(
                                "Tambah Poin",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSegmentedTabBar(
      Color primaryColor, ViolationRoleCheck roleCheck, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade200,
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
                  color: _activeTabIndex == 1
                      ? (isDark ? Colors.grey.shade800 : Colors.white)
                      : Colors.transparent,
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
                          : (isDark ? Colors.white70 : Colors.grey.shade700),
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
                            : (isDark ? Colors.white70 : Colors.grey.shade700),
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
                  color: _activeTabIndex == 0
                      ? (isDark ? Colors.grey.shade800 : Colors.white)
                      : Colors.transparent,
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
                          : (isDark ? Colors.white70 : Colors.grey.shade700),
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
                            : (isDark ? Colors.white70 : Colors.grey.shade700),
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

  Widget _buildSearchBar(Color primaryColor, ViolationRoleCheck roleCheck,
      bool isDark, bool canExportPdf) {
    final bool hasActiveFilter = _selectedClassId != null ||
        (_selectedFilter != null && _selectedFilter != 'all');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).cardColor : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade200),
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
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: "Cari nama / NISN / NIS...",
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                  ),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: isDark ? Colors.white54 : Colors.grey, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded,
                              size: 18,
                              color: isDark
                                  ? Colors.white70
                                  : Colors.grey.shade600),
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
                color: hasActiveFilter
                    ? primaryColor
                    : (isDark ? Theme.of(context).cardColor : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasActiveFilter
                      ? primaryColor
                      : (isDark ? Colors.white12 : Colors.grey.shade300),
                ),
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 22,
                color: hasActiveFilter
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
          if (canExportPdf) ...[
            const SizedBox(width: 10),
            Tooltip(
              message: "Rekap Pelanggaran (PDF)",
              child: InkWell(
                onTap: () => _openPdfSheet(roleCheck),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: isDark ? Theme.of(context).cardColor : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade300,
                    ),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 22,
                    color: isDark ? Colors.white70 : primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStudentCard({
    required StudentViolationItem item,
    required Color primaryColor,
    required bool isKesiswaan,
    required bool isDark,
    String? fallbackClassName,
    required VoidCallback onTap,
  }) {
    final sanction = ViolationSanctionHelper.getSanctionLevel(
      item.totalPoints,
      customStatusName: item.sanctionName,
    );
    // Teks badge samakan web (Aman, Level 1-4): utamakan nama dari server.
    final badgeText = ViolationSanctionHelper.listBadgeLabel(
      points: item.totalPoints,
      sanctionName: item.sanctionName,
      fallbackTitle: sanction.title,
    );
    // Samakan dengan kesiswaan: jika response walas flat tanpa className,
    // tampilkan nama kelas perwalian agar tidak muncul "- • Absen X".
    final displayClassName =
        (item.className != null && item.className!.trim().isNotEmpty)
            ? item.className!.trim()
            : (fallbackClassName ?? '-');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).cardColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
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
                      errorWidget: (context, url, error) => SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.person,
                          color: isDark ? Colors.white70 : Colors.black,
                          size: 36,
                        ),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.person,
                    color: isDark ? Colors.white70 : Colors.black,
                    size: 36,
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
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.resolvedNisn != null ||
                      item.resolvedNis != null ||
                      item.resolvedAdmissionNo != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.studentIdentityText,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    "$displayClassName ${item.rollNumber != null ? '• Absen ${item.rollNumber}' : ''}",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
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
                          badgeText,
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
