import 'package:eschool_saas_staff/cubits/teacherAcademics/announcement/teacherCreateAnnouncementCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/announcement/teacherEditAnnouncementCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/classSectionsAndSubjects.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/models/academic/studyMaterial.dart';
import 'package:eschool_saas_staff/data/models/announcement/teacherAnnouncement.dart';
import 'package:eschool_saas_staff/data/models/academic/teacherSubject.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/widgets/customFileContainer.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/widgets/studyMaterialContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:eschool_saas_staff/ui/widgets/system/errorContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/filterSelectionBottomsheet.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:eschool_saas_staff/utils/system/optimized_file_compression_mixin.dart';
import 'package:eschool_saas_staff/utils/system/optimized_file_compression_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class TeacherAddEditAnnouncementScreen extends StatefulWidget {
  final TeacherAnnouncement? announcement;
  final ClassSection? selectedClassSection;
  final TeacherSubject? selectedSubject;
  static Widget getRouteInstance() {
    final arguments = Get.arguments as Map<String, dynamic>?;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => TeacherCreateAnnouncementCubit(),
        ),
        BlocProvider(
          create: (context) => TeacherEditAnnouncementCubit(),
        ),
        BlocProvider(
          create: (context) => ClassSectionsAndSubjectsCubit(),
        ),
      ],
      child: TeacherAddEditAnnouncementScreen(
        announcement: arguments?['announcement'],
        selectedClassSection: arguments?['selectedClassSection'],
        selectedSubject: arguments?['selectedSubject'],
      ),
    );
  }

  static Map<String, dynamic> buildArguments(
      {required TeacherAnnouncement? announcement,
      required ClassSection? selectedClassSection,
      required TeacherSubject? selectedSubject}) {
    return {
      "announcement": announcement,
      "selectedClassSection": selectedClassSection,
      "selectedSubject": selectedSubject
    };
  }

  const TeacherAddEditAnnouncementScreen(
      {super.key,
      required this.announcement,
      this.selectedClassSection,
      this.selectedSubject});

  @override
  State<TeacherAddEditAnnouncementScreen> createState() =>
      _TeacherAddEditAnnouncementScreenState();
}

class _TeacherAddEditAnnouncementScreenState
    extends State<TeacherAddEditAnnouncementScreen>
    with TickerProviderStateMixin, OptimizedFileCompressionMixin {
  late ClassSection? _selectedClassSection = widget.selectedClassSection;
  late TeacherSubject? _selectedSubject = widget.selectedSubject;
  late AnimationController _fabAnimationController;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomModernAppBar(
        title:
            widget.announcement != null ? "Edit Pengumuman" : "Buat Pengumuman",
        icon: Icons.campaign_rounded,
        fabAnimationController: _fabAnimationController,
        onBackPressed: () {
          Get.back(result: refreshAnnouncementsInPreviousPage);
        },
        // Not showing any of the optional buttons as requested
        showAddButton: false,
        showArchiveButton: false,
        showFilterButton: false,
        showHelperButton: false,
      ),
      body: _buildAddEditAnnouncementForm(),
    );
  }

  //This will determine if need to refresh the previous page
  //announcement data. If teacher remove the the any files
  //so we need to fetch the list again
  late bool refreshAnnouncementsInPreviousPage = false;

  late final TextEditingController _announcementTitleTextEditingController =
      TextEditingController(
    text: widget.announcement?.title,
  );
  late final TextEditingController
      _announcementDescriptionTextEditingController = TextEditingController(
    text: widget.announcement?.description,
  );

  List<PlatformFile> uploadedFiles = [];

  late List<StudyMaterial> announcementAttachments =
      widget.announcement?.files ?? [];

  @override
  void initState() {
    // Initialize the animation controller for the modern app bar
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _fabAnimationController.repeat();

    Future.delayed(Duration.zero, () {
      if (mounted) {
        context
            .read<ClassSectionsAndSubjectsCubit>()
            .getClassSectionsAndSubjects(
                classSectionId: _selectedClassSection?.id);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _announcementTitleTextEditingController.dispose();
    _announcementDescriptionTextEditingController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _addFiles() async {
    debugPrint(
        '🎯 [ANNOUNCEMENT SCREEN] Memulai upload file dengan kompresi otomatis');

    // Gunakan mixin untuk pick dan kompres otomatis dengan loading dialog
    final compressedFiles = await pickAndCompressFiles(
      allowMultiple: true,
      maxSizeInMB: 0.5, // Target 500KB
      forceCompress: true,
      context: context,
    );

    if (compressedFiles != null && compressedFiles.isNotEmpty) {
      // Convert File to PlatformFile for compatibility
      for (final file in compressedFiles) {
        final fileSize = await file.length();
        final fileName = file.path.split('/').last;

        debugPrint('✅ [ANNOUNCEMENT SCREEN] File berhasil diproses: $fileName');
        debugPrint(
            '   📊 Ukuran final: ${OptimizedFileCompressionUtils.formatFileSize(fileSize)}');

        final platformFile = PlatformFile(
          name: fileName,
          size: fileSize,
          path: file.path,
        );

        uploadedFiles.add(platformFile);
      }
      setState(() {});
    } else {
      debugPrint(
          '❌ [ANNOUNCEMENT SCREEN] Tidak ada file yang dipilih atau diproses');
    }
  }

  void showErrorMessage(String errorMessageKey) {
    Utils.showSnackBar(
      context: context,
      message: errorMessageKey,
    );
  }

  void changeSelectedClassSection(ClassSection? classSection,
      {bool fetchNewSubjects = true}) {
    if (_selectedClassSection != classSection) {
      _selectedClassSection = classSection;
      //fetching new subjects after user changes the selected class
      if (fetchNewSubjects && _selectedClassSection != null) {
        context
            .read<ClassSectionsAndSubjectsCubit>()
            .getNewSubjectsFromSelectedClassSectionIndex(
                newClassSectionId: classSection?.id ?? 0)
            .then((value) {
          if (mounted) {
            if (context.read<ClassSectionsAndSubjectsCubit>().state
                is ClassSectionsAndSubjectsFetchSuccess) {
              final successState = (context
                  .read<ClassSectionsAndSubjectsCubit>()
                  .state as ClassSectionsAndSubjectsFetchSuccess);
              changeSelectedTeacherSubject(successState.subjects.firstOrNull);
            }
          }
        });
      }
      setState(() {});
    }
  }

  void changeSelectedTeacherSubject(TeacherSubject? teacherSubject,
      {bool fetchNewLessons = true}) {
    if (_selectedSubject != teacherSubject) {
      _selectedSubject = teacherSubject;
      setState(() {});
    }
  }

  void createAnnouncement() {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_selectedSubject == null) {
      showErrorMessage(noSubjectSelectedKey);
      return;
    }

    if (_selectedClassSection == null) {
      showErrorMessage(noClassSectionSelectedKey);
      return;
    }

    if (_announcementTitleTextEditingController.text.trim().isEmpty) {
      showErrorMessage(pleaseAddAnnouncementTitleKey);
      return;
    }
    if (_announcementDescriptionTextEditingController.text.trim().isEmpty) {
      showErrorMessage(pleaseAddAnnouncementDescriptionKey);
      return;
    }

    context.read<TeacherCreateAnnouncementCubit>().createAnnouncement(
          classSectionId: _selectedClassSection?.id ?? 0,
          classSubjectId: _selectedSubject?.classSubjectId ?? 0,
          title: _announcementTitleTextEditingController.text,
          description: _announcementDescriptionTextEditingController.text,
          attachments: uploadedFiles,
        );
  }

  void editAnnouncement() {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_announcementTitleTextEditingController.text.trim().isEmpty) {
      showErrorMessage(pleaseAddAnnouncementTitleKey);
      return;
    }
    if (_announcementDescriptionTextEditingController.text.trim().isEmpty) {
      showErrorMessage(pleaseAddAnnouncementDescriptionKey);
      return;
    }

    context.read<TeacherEditAnnouncementCubit>().editAnnouncement(
          announcementId: widget.announcement?.id ?? 0,
          classSectionId: _selectedClassSection?.id ?? 0,
          classSubjectId: _selectedSubject?.classSubjectId ?? 0,
          title: _announcementTitleTextEditingController.text,
          description: _announcementDescriptionTextEditingController.text,
          attachments: uploadedFiles,
        );
  }

  Widget _buildAddEditAnnouncementForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Header with Icon
          Container(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.campaign_rounded,
                  size: 42,
                  color: Colors.white,
                )
                    .animate()
                    .scale(duration: 500.ms)
                    .then()
                    .shimmer(duration: 1000.ms),
                const SizedBox(height: 15),
                Text(
                  widget.announcement != null
                      ? "Edit Pengumuman"
                      : "Buat Pengumuman",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black26,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // Form Content
          BlocConsumer<ClassSectionsAndSubjectsCubit,
              ClassSectionsAndSubjectsState>(
            listener: (context, state) {
              if (state is ClassSectionsAndSubjectsFetchSuccess) {
                if (_selectedClassSection == null) {
                  changeSelectedClassSection(state.classSections.firstOrNull,
                      fetchNewSubjects: false);
                }
                if (_selectedSubject == null) {
                  changeSelectedTeacherSubject(state.subjects.firstOrNull);
                }
              }
            },
            builder: (context, state) {
              return state is ClassSectionsAndSubjectsFetchFailure
                  ? Center(
                      child: ErrorContainer(
                      errorMessage: state.errorMessage,
                      onTapRetry: () {
                        context
                            .read<ClassSectionsAndSubjectsCubit>()
                            .getClassSectionsAndSubjects();
                      },
                    ))
                  : _buildFormContent(state);
            },
          ),

          const SizedBox(height: 30),

          // Submit Button
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildFormContent(ClassSectionsAndSubjectsState state) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        // Basic Info Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informasi Dasar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 20),

              // Class Selection
              _buildAnimatedTextField(
                controller: TextEditingController(
                    text: _selectedClassSection?.fullName ?? 'Pilih Kelas'),
                label: 'Bagian Kelas',
                icon: Icons.class_,
                readOnly: true,
                onTap: () {
                  if (state is ClassSectionsAndSubjectsFetchSuccess) {
                    Utils.showBottomSheet(
                        child: FilterSelectionBottomsheet<ClassSection>(
                          showFilterByLabel: false,
                          onSelection: (value) {
                            changeSelectedClassSection(value);
                            Get.back();
                          },
                          selectedValue: _selectedClassSection!,
                          titleKey: classKey,
                          values: state.classSections,
                        ),
                        context: context);
                  }
                },
              ),
              const SizedBox(height: 15),

              // Subject Selection
              _buildAnimatedTextField(
                controller: TextEditingController(
                    text: _selectedSubject?.subject.getSybjectNameWithType() ??
                        'Pilih Mata Pelajaran'),
                label: 'Mata Pelajaran',
                icon: Icons.subject,
                readOnly: true,
                onTap: () {
                  if (state is ClassSectionsAndSubjectsFetchSuccess) {
                    Utils.showBottomSheet(
                        child: FilterSelectionBottomsheet<TeacherSubject>(
                          showFilterByLabel: false,
                          selectedValue: _selectedSubject!,
                          titleKey: subjectKey,
                          values: state.subjects,
                          onSelection: (value) {
                            changeSelectedTeacherSubject(value!);
                            Get.back();
                          },
                        ),
                        context: context);
                  }
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Announcement Details Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detail Pengumuman',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 20),
              _buildAnimatedTextField(
                  controller: _announcementTitleTextEditingController,
                  label: 'Judul Pengumuman',
                  icon: Icons.title,
                  maxLength: 128,
                  autoExpand: true),
              const SizedBox(height: 15),
              _buildAnimatedTextField(
                controller: _announcementDescriptionTextEditingController,
                label: 'Deskripsi',
                icon: Icons.description,
                maxLength: 1024,
                autoExpand: true, // Enable auto-expanding
                keyboardType: TextInputType.multiline,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Attachments Section - Clean & Minimalist Design
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clean Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.attach_file_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Lampiran Pengumuman',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),

              // Minimalist Info Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Format yang didukung',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildFormatChip('PDF'),
                        _buildFormatChip('JPEG'),
                        _buildFormatChip('PNG'),
                        _buildFormatChip('CSV'),
                        _buildFormatChip('MS Word'),
                        _buildFormatChip('MP4'),
                        _buildFormatChip('AVI'),
                        _buildFormatChip('YouTube'),
                      ],
                    ),
                    //     fontStyle: FontStyle.italic,
                    //   ),
                    // ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Content Area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Existing attachments
                    if (widget.announcement != null &&
                        announcementAttachments.isNotEmpty) ...[
                      Text(
                        'Lampiran Saat Ini',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...announcementAttachments.map(
                        (attachment) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: StudyMaterialContainer(
                            onDeleteStudyMaterial: (fileId) {
                              announcementAttachments.removeWhere(
                                  (element) => element.id == fileId);
                              refreshAnnouncementsInPreviousPage = true;
                              setState(() {});
                            },
                            showOnlyStudyMaterialTitles: true,
                            showEditAndDeleteButton: true,
                            studyMaterial: attachment,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // New attachments
                    if (uploadedFiles.isNotEmpty) ...[
                      Text(
                        'Lampiran Baru',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(uploadedFiles.length, (index) => index)
                          .map(
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: CustomFileContainer(
                            backgroundColor:
                                Theme.of(context).scaffoldBackgroundColor,
                            onDelete: () {
                              uploadedFiles.removeAt(index);
                              setState(() {});
                            },
                            title: uploadedFiles[index].name,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Clean Add Button
                    InkWell(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        _addFiles();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tambah Lampiran',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: widget.announcement != null
              ? BlocConsumer<TeacherEditAnnouncementCubit,
                  TeacherEditAnnouncementState>(
                  listener: (context, state) {
                    if (state is TeacherEditAnnouncementSuccess) {
                      // Show auto-dismissing success snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 12),
                                Text(
                                  'Pengumuman diperbarui!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          backgroundColor: Colors.green.shade400,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                        ),
                      );

                      // Add slight delay before popping
                      Future.delayed(const Duration(milliseconds: 2200), () {
                        if (context.mounted) {
                          Get.back(result: true);
                        }
                      });
                    } else if (state is TeacherEditAnnouncementFailure) {
                      Utils.showSnackBar(
                          context: context, message: state.errorMessage);
                    }
                  },
                  builder: (context, state) {
                    return _buildButtonContent(
                      onTap: () {
                        if (state is TeacherEditAnnouncementInProgress) return;
                        editAnnouncement();
                      },
                      isLoading: state is TeacherEditAnnouncementInProgress,
                      title: 'Update Pengumuman',
                    );
                  },
                )
              : BlocConsumer<TeacherCreateAnnouncementCubit,
                  TeacherCreateAnnouncementState>(
                  listener: (context, state) async {
                    if (state is TeacherCreateAnnouncementSuccess) {
                      // Show auto-dismissing success banner
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 12),
                                Text(
                                  'Pengumuman ditambahkan!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          backgroundColor: Colors.green.shade400,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                        ),
                      );

                      // Clear form and pop
                      _announcementTitleTextEditingController.text = "";
                      _announcementDescriptionTextEditingController.text = "";
                      uploadedFiles = [];
                      announcementAttachments = [];
                      refreshAnnouncementsInPreviousPage = true;

                      // Add slight delay before popping
                      Future.delayed(const Duration(milliseconds: 2200), () {
                        if (context.mounted) {
                          Navigator.pop(context, true);
                        }
                      });
                    } else if (state is TeacherCreateAnnouncementFailure) {
                      Utils.showSnackBar(
                        context: context,
                        message: state.errorMessage,
                      );
                    }
                  },
                  builder: (context, state) {
                    return _buildButtonContent(
                      onTap: () {
                        if (state is TeacherCreateAnnouncementInProgress) {
                          return;
                        }
                        createAnnouncement();
                      },
                      isLoading: state is TeacherCreateAnnouncementInProgress,
                      title: 'Buat Pengumuman',
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildButtonContent({
    required VoidCallback onTap,
    required bool isLoading,
    required String title,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      splashColor: Colors.white.withValues(alpha: 0.2),
      highlightColor: Colors.white.withValues(alpha: 0.1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Text(
              isLoading ? 'Memproses...' : title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            if (!isLoading) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 22,
              ).animate(onPlay: (controller) {
                controller.repeat(reverse: true);
              }).slideX(
                begin: 0,
                end: 0.3,
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeInOut,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    bool autoExpand = false,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      maxLines: autoExpand ? null : maxLines,
      minLines: autoExpand ? 3 : null,
      maxLength: maxLength,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType:
          keyboardType ?? (autoExpand ? TextInputType.multiline : null),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.white54 : Colors.grey.shade600,
        ),
        prefixIcon: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.secondary),
        ),
        counterText: "",
      ),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildFormatChip(String label) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade300,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white70 : Colors.grey.shade700,
        ),
      ),
    );
  }
}

