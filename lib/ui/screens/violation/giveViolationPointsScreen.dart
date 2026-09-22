import 'dart:io';
import 'package:eschool_saas_staff/cubits/academics/classesCubit.dart';
import 'package:eschool_saas_staff/cubits/violation/giveViolationPointsCubit.dart';
import 'package:eschool_saas_staff/cubits/violation/violationTypesCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/models/student/studentDetails.dart';
import 'package:eschool_saas_staff/data/models/violation/violationSanctionHelper.dart';
import 'package:eschool_saas_staff/data/models/violation/violationType.dart';
import 'package:eschool_saas_staff/data/repositories/student/studentRepository.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customCircularProgressIndicator.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/utils/system/snackBarUtils.dart';
import 'package:eschool_saas_staff/data/models/violation/studentAvatarHelper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class GiveViolationPointsScreen extends StatefulWidget {
  final int? initialStudentId;
  final String? initialStudentName;
  final String? initialClassName;

  const GiveViolationPointsScreen({
    super.key,
    this.initialStudentId,
    this.initialStudentName,
    this.initialClassName,
  });

  static Widget getRouteInstance() {
    final args = Get.arguments as Map<String, dynamic>?;
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => GiveViolationPointsCubit()),
        BlocProvider(create: (_) => ViolationTypesCubit()..getViolationTypes()),
        BlocProvider(create: (_) => ClassesCubit()..getClasses(modeAll: true)),
      ],
      child: GiveViolationPointsScreen(
        initialStudentId: args?['studentId'] as int?,
        initialStudentName: args?['studentName'] as String?,
        initialClassName: args?['className'] as String?,
      ),
    );
  }

  @override
  State<GiveViolationPointsScreen> createState() =>
      _GiveViolationPointsScreenState();
}

class _GiveViolationPointsScreenState extends State<GiveViolationPointsScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _appBarAnimationController;

  // Selected Student
  int? _selectedStudentId;
  String? _selectedStudentName;
  String? _selectedClassName;
  String? _selectedStudentImage;

  // Selected Violation Type
  ViolationType? _selectedViolationType;

  // Date
  DateTime _selectedDate = DateTime.now();

  // Notes
  final TextEditingController _notesController = TextEditingController();

  // Photo
  File? _selectedPhoto;
  final ImagePicker _picker = ImagePicker();

  // Student search/pick state (dikelola secara lokal di dalam modal)

  @override
  void initState() {
    super.initState();
    _appBarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _selectedStudentId = widget.initialStudentId;
    _selectedStudentName = widget.initialStudentName;
    _selectedClassName = widget.initialClassName;
  }

  @override
  void dispose() {
    _appBarAnimationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (picked != null) {
        final file = File(picked.path);
        final bytes = await file.length();
        // Check max 2MB (2 * 1024 * 1024)
        if (bytes > 2 * 1024 * 1024) {
          if (!mounted) return;
          SnackBarUtils.showSnackBar(
            context: context,
            message: "Ukuran foto melebihi 2MB. Silakan pilih foto lain.",
            backgroundColor: Colors.redAccent,
          );
          return;
        }
        if (!mounted) return;
        setState(() {
          _selectedPhoto = file;
        });
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showSnackBar(
        context: context,
        message: "Gagal memilih gambar: $e",
        backgroundColor: Colors.redAccent,
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final bool isDarkPicker =
            Theme.of(context).brightness == Brightness.dark;
        // Tema gelap: biarkan date picker mengikuti tema sistem.
        // Tema terang: tint dengan warna primary aplikasi.
        if (isDarkPicker) return child!;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _openStudentPickerModal() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final classesCubit = context.read<ClassesCubit>();
    if (classesCubit.state is! ClassesFetchSuccess &&
        classesCubit.state is! ClassesFetchInProgress) {
      classesCubit.getClasses(modeAll: true);
    }

    // State internal picker
    ClassSection? selectedClass;
    List<StudentDetails> studentList = [];
    bool isLoadingStudents = false;
    String classSearchQuery = "";
    String studentSearchQuery = "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BlocProvider.value(
          value: classesCubit,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final bool isDarkModal =
                  Theme.of(context).brightness == Brightness.dark;
              final Color modalCardColor = isDarkModal
                  ? Theme.of(context).cardColor
                  : Colors.white;
              final Color modalMutedColor = isDarkModal
                  ? Colors.white60
                  : Colors.grey.shade600;
              final Color modalTitleColor =
                  isDarkModal ? Colors.white : Colors.black87;
              return Container(
                height: MediaQuery.of(context).size.height * 0.85,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: modalCardColor,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDarkModal
                              ? Colors.white24
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // TAMPILAN 1: PILIH KELAS
                    if (selectedClass == null) ...[
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () => Navigator.of(context).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Pilih Kelas",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        onChanged: (val) {
                          setModalState(() {
                            classSearchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Cari nama kelas...",
                          prefixIcon:
                              const Icon(Icons.search_rounded, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: BlocBuilder<ClassesCubit, ClassesState>(
                          builder: (context, state) {
                            if (state is ClassesFetchInProgress) {
                              return const Center(
                                child: CustomCircularProgressIndicator(),
                              );
                            }
                            if (state is ClassesFetchFailure) {
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Gagal memuat kelas",
                                      style: GoogleFonts.poppins(
                                          color: Colors.redAccent),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () => context
                                          .read<ClassesCubit>()
                                          .getClasses(
                                              forceRefresh: true,
                                              modeAll: true),
                                      child: const Text("Coba Lagi"),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final Set<int> seenIds = {};
                            final List<ClassSection> allClasses = [];
                            if (state is ClassesFetchSuccess) {
                              for (final c in [
                                ...state.primaryClasses,
                                ...state.classes
                              ]) {
                                if (c.id != null && seenIds.add(c.id!)) {
                                  allClasses.add(c);
                                }
                              }
                            }

                            final filteredClasses = allClasses.where((c) {
                              if (classSearchQuery.trim().isEmpty) return true;
                              final q = classSearchQuery.toLowerCase().trim();
                              final name =
                                  (c.fullName ?? c.name ?? "").toLowerCase();
                              return name.contains(q);
                            }).toList();

                            if (filteredClasses.isEmpty) {
                              return Center(
                                child: Text(
                                  "Kelas tidak ditemukan",
                                  style: GoogleFonts.poppins(
                                      color: modalMutedColor),
                                ),
                              );
                            }

                            return ListView.separated(
                              itemCount: filteredClasses.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final c = filteredClasses[index];
                                final name =
                                    c.fullName ?? c.name ?? "Kelas ${c.id}";

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        primaryColor.withValues(alpha: 0.1),
                                    child: Icon(
                                      Icons.class_rounded,
                                      size: 18,
                                      color: primaryColor,
                                    ),
                                  ),
                                  title: Text(
                                    name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: modalTitleColor,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.grey,
                                  ),
                                  onTap: () async {
                                    setModalState(() {
                                      selectedClass = c;
                                      isLoadingStudents = true;
                                      studentList = [];
                                      studentSearchQuery = "";
                                    });

                                    if (c.id != null) {
                                      try {
                                        final res = await StudentRepository()
                                            .getStudents(
                                          classSectionId: c.id!,
                                          getAllData: true,
                                        );
                                        StudentAvatarHelper.cacheStudents(
                                            res.students,
                                            classSectionId: c.id);
                                        setModalState(() {
                                          studentList = res.students;
                                          isLoadingStudents = false;
                                        });
                                      } catch (e) {
                                        setModalState(() {
                                          studentList = [];
                                          isLoadingStudents = false;
                                        });
                                      }
                                    } else {
                                      setModalState(() {
                                        isLoadingStudents = false;
                                      });
                                    }
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ]

                    // TAMPILAN 2: PILIH SISWA DARI KELAS TERPILIH
                    else ...[
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () {
                              setModalState(() {
                                selectedClass = null;
                                studentList = [];
                                studentSearchQuery = "";
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Pilih Siswa",
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  selectedClass?.fullName ??
                                      selectedClass?.name ??
                                      "",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: modalMutedColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        onChanged: (val) {
                          setModalState(() {
                            studentSearchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Cari nama atau NISN siswa...",
                          prefixIcon:
                              const Icon(Icons.search_rounded, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: isLoadingStudents
                            ? const Center(
                                child: CustomCircularProgressIndicator(),
                              )
                            : studentList.isEmpty
                                ? Center(
                                    child: Text(
                                      "Tidak ada data siswa di kelas ini",
                                      style: GoogleFonts.poppins(
                                          color: modalMutedColor),
                                    ),
                                  )
                                : Builder(
                                    builder: (context) {
                                      final filtered = studentList.where((s) {
                                        if (studentSearchQuery.trim().isEmpty) {
                                          return true;
                                        }
                                        final q = studentSearchQuery
                                            .toLowerCase()
                                            .trim();
                                        final name = (s.fullName ??
                                                "${s.firstName ?? ''} ${s.lastName ?? ''}")
                                            .toLowerCase();
                                        final nisn = (s.student?.admissionNo ??
                                                s.rollNumber ??
                                                '')
                                            .toLowerCase();
                                        return name.contains(q) ||
                                            nisn.contains(q);
                                      }).toList();

                                      if (filtered.isEmpty) {
                                        return Center(
                                          child: Text(
                                            "Tidak ada siswa yang cocok",
                                            style: GoogleFonts.poppins(
                                                color: modalMutedColor),
                                          ),
                                        );
                                      }

                                      return ListView.separated(
                                        itemCount: filtered.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          final s = filtered[index];
                                          final name = s.fullName ??
                                              "${s.firstName ?? ''} ${s.lastName ?? ''}"
                                                  .trim();
                                          final nisn =
                                              s.student?.admissionNo ??
                                                  s.rollNumber ??
                                                  '-';

                                          final studentImage =
                                              (s.image != null &&
                                                      s.image!.trim().isNotEmpty)
                                                  ? s.image!.trim()
                                                  : ((s.profileUrl != null &&
                                                          s.profileUrl!
                                                              .trim()
                                                              .isNotEmpty)
                                                      ? s.profileUrl!.trim()
                                                      : null);

                                          return ListTile(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4),
                                            leading: (studentImage != null &&
                                                    studentImage.isNotEmpty)
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(20),
                                                    child: CachedNetworkImage(
                                                      imageUrl: studentImage,
                                                      width: 40,
                                                      height: 40,
                                                      fit: BoxFit.cover,
                                                      placeholder:
                                                          (context, url) =>
                                                              CircleAvatar(
                                                        radius: 20,
                                                        backgroundColor:
                                                            primaryColor
                                                                .withValues(
                                                                    alpha: 0.1),
                                                        child: Text(
                                                          name.isNotEmpty
                                                              ? name[0]
                                                                  .toUpperCase()
                                                              : 'S',
                                                          style: TextStyle(
                                                            color: primaryColor,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      errorWidget: (context,
                                                              url, error) =>
                                                          CircleAvatar(
                                                        radius: 20,
                                                        backgroundColor:
                                                            primaryColor
                                                                .withValues(
                                                                    alpha: 0.1),
                                                        child: Text(
                                                          name.isNotEmpty
                                                              ? name[0]
                                                                  .toUpperCase()
                                                              : 'S',
                                                          style: TextStyle(
                                                            color: primaryColor,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : CircleAvatar(
                                                    radius: 20,
                                                    backgroundColor: Theme.of(
                                                            context)
                                                        .colorScheme
                                                        .primary
                                                        .withValues(alpha: 0.1),
                                                    child: Text(
                                                      name.isNotEmpty
                                                          ? name[0]
                                                              .toUpperCase()
                                                          : 'S',
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                            title: Text(
                                              name,
                                              style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14),
                                            ),
                                            subtitle: Text(
                                              "NISN / No: $nisn",
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: modalMutedColor),
                                            ),
                                            trailing: const Icon(
                                                Icons.chevron_right_rounded,
                                                color: Colors.grey),
                                            onTap: () {
                                              setState(() {
                                                _selectedStudentId =
                                                    s.student?.id ?? s.id;
                                                _selectedStudentName = name;
                                                _selectedClassName =
                                                    selectedClass?.fullName ??
                                                        selectedClass?.name;
                                                _selectedStudentImage =
                                                    studentImage;
                                              });
                                              Navigator.of(context).pop();
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _submitForm() {
    if (_selectedStudentId == null) {
      SnackBarUtils.showSnackBar(
        context: context,
        message: "Silakan pilih siswa terlebih dahulu",
        backgroundColor: Colors.redAccent,
      );
      return;
    }

    if (_selectedViolationType == null) {
      SnackBarUtils.showSnackBar(
        context: context,
        message: "Silakan pilih jenis pelanggaran",
        backgroundColor: Colors.redAccent,
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final formattedDate =
          DateFormat('yyyy-MM-dd').format(_selectedDate);

      context.read<GiveViolationPointsCubit>().submitViolationPoints(
            studentId: _selectedStudentId!,
            violationTypeId: _selectedViolationType!.id,
            incidentDate: formattedDate,
            notes: _notesController.text,
            photo: _selectedPhoto,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color fieldFillColor =
        isDark ? Colors.white10 : Colors.grey.shade50;
    final Color fieldBorderColor =
        isDark ? Colors.white24 : Colors.grey.shade300;
    final Color labelColor = isDark ? Colors.white : Colors.black87;
    final Color subtleTextColor =
        isDark ? Colors.white60 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).scaffoldBackgroundColor
          : Colors.grey.shade50,
      appBar: CustomModernAppBar(
        title: "Input Poin Pelanggaran",
        subtitle: "Catat Pelanggaran & Sanksi Siswa",
        icon: Icons.add_moderator_rounded,
        fabAnimationController: _appBarAnimationController,
        primaryColor: const Color(0xFF8B1F41),
        lightColor: const Color(0xFFAC3B5C),
        onBackPressed: () => Get.back(),
        height: 85,
      ),
      body: BlocConsumer<GiveViolationPointsCubit, GiveViolationPointsState>(
        listener: (context, state) {
          if (state is GiveViolationPointsSuccess) {
            SnackBarUtils.showSnackBar(
              context: context,
              message: "Poin pelanggaran berhasil dicatat!",
              backgroundColor: Colors.green,
            );
            Get.back(result: true);
          } else if (state is GiveViolationPointsFailure) {
            SnackBarUtils.showSnackBar(
              context: context,
              message: state.errorMessage,
              backgroundColor: Colors.redAccent,
            );
          }
        },
        builder: (context, state) {
          final isSubmitting = state is GiveViolationPointsInProgress;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Pemilihan Siswa
                  Text(
                    "Siswa/Siswi yang Melanggar",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: widget.initialStudentId != null
                        ? null // Jika sudah dipassing dari detail, read-only
                        : _openStudentPickerModal,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: fieldFillColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: fieldBorderColor),
                      ),
                      child: Row(
                        children: [
                          if (_selectedStudentImage != null &&
                              _selectedStudentImage!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: _selectedStudentImage!,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Icon(
                                    Icons.person_outline_rounded,
                                    color: primaryColor,
                                    size: 24),
                              ),
                            )
                          else
                            Icon(Icons.person_outline_rounded,
                                color: primaryColor, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedStudentName ??
                                      "Pilih Siswa dari Kelas...",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: _selectedStudentName != null
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: _selectedStudentName != null
                                        ? labelColor
                                        : subtleTextColor,
                                  ),
                                ),
                                if (_selectedClassName != null)
                                  Text(
                                    "Kelas: $_selectedClassName",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: subtleTextColor,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (widget.initialStudentId == null)
                            const Icon(Icons.arrow_drop_down,
                                color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Jenis Pelanggaran (Dropdown)
                  Text(
                    "Jenis Pelanggaran",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  BlocBuilder<ViolationTypesCubit, ViolationTypesState>(
                    builder: (context, typesState) {
                      if (typesState is ViolationTypesFetchInProgress) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CustomCircularProgressIndicator(),
                          ),
                        );
                      }
                      if (typesState is ViolationTypesFetchFailure) {
                        return CustomErrorWidget(
                          message: typesState.errorMessage,
                          onRetry: () => context
                              .read<ViolationTypesCubit>()
                              .getViolationTypes(),
                        );
                      }

                      final types = typesState is ViolationTypesFetchSuccess
                          ? typesState.violationTypes
                          : <ViolationType>[];

                      return DropdownButtonFormField<ViolationType>(
                        initialValue: _selectedViolationType,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: "Pilih Jenis Pelanggaran",
                          hintStyle: GoogleFonts.poppins(
                              color: subtleTextColor, fontSize: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: fieldBorderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: fieldBorderColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          filled: true,
                          fillColor: fieldFillColor,
                        ),
                        items: types.map((vt) {
                          final catColor =
                              ViolationSanctionHelper.getCategoryColor(
                                  vt.category);
                          return DropdownMenuItem(
                            value: vt,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: catColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "+${vt.points} Poin",
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: catColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "${vt.name} (${vt.category})",
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedViolationType = val;
                          });
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // 3. Tanggal Kejadian
                  Text(
                    "Tanggal Kejadian",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: fieldFillColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: fieldBorderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                                .format(_selectedDate),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: labelColor,
                            ),
                          ),
                          Icon(Icons.calendar_month_rounded,
                              color: primaryColor, size: 22),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. Catatan / Kronologi Kejadian
                  Text(
                    "Catatan / Deskripsi",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 4,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: labelColor,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          "Tuliskan rincian atau kronologi kejadian pelanggaran...",
                      hintStyle: GoogleFonts.poppins(
                          color: isDark
                              ? Colors.white38
                              : Colors.grey.shade500,
                          fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: fieldBorderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: fieldBorderColor),
                      ),
                      filled: true,
                      fillColor: fieldFillColor,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 5. Bukti Foto (Opsional, Maks 2MB)
                  Text(
                    "Bukti Foto (Opsional, Maks 2MB)",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_selectedPhoto != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            _selectedPhoto!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedPhoto = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_rounded),
                            label: Text(
                              "Kamera",
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: BorderSide(color: fieldBorderColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_rounded),
                            label: Text(
                              "Galeri",
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: BorderSide(color: fieldBorderColor),
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: isSubmitting
                          ? const CustomCircularProgressIndicator(
                              indicatorColor: Colors.white,
                            )
                          : Text(
                              "Simpan Pelanggaran",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
