import 'package:eschool_saas_staff/data/models/academic/pickedStudyMaterial.dart';
import 'package:eschool_saas_staff/data/models/academic/studyMaterial.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/widgets/customFileContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customDropdownSelectionButton.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customRoundedButton.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextFieldContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/filterSelectionBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/system/uploadImageOrFileButton.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:eschool_saas_staff/utils/system/file_compression_mixin.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddStudyMaterialBottomsheet extends StatefulWidget {
  final Function(PickedStudyMaterial) onTapSubmit;
  final bool editFileDetails;
  final PickedStudyMaterial? pickedStudyMaterial;

  const AddStudyMaterialBottomsheet({
    super.key,
    required this.editFileDetails,
    required this.onTapSubmit,
    this.pickedStudyMaterial,
  });

  @override
  State<AddStudyMaterialBottomsheet> createState() =>
      _AddStudyMaterialBottomsheetState();
}

class _AddStudyMaterialBottomsheetState
    extends State<AddStudyMaterialBottomsheet> with FileCompressionMixin {
  StudyMaterialTypeItem _selectedStudyMaterial =
      allStudyMaterialTypeItems.first;

  late final TextEditingController _fileNameEditingController =
      TextEditingController();

  late final TextEditingController _youtubeLinkEditingController =
      TextEditingController();

  PlatformFile? addedFile; //if studymaterial type is fileUpload
  PlatformFile?
      addedVideoThumbnailFile; //if studymaterial type is not fileUpload
  PlatformFile? addedVideoFile; //if studymaterial type is videoUpload

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (widget.editFileDetails) {
        _fileNameEditingController.text = widget.pickedStudyMaterial!.fileName;
        if (widget.pickedStudyMaterial!.pickedStudyMaterialTypeId == 1) {
          _selectedStudyMaterial = allStudyMaterialTypeItems.firstWhereOrNull(
                  (element) =>
                      element.studyMaterialType == StudyMaterialType.file) ??
              allStudyMaterialTypeItems.first;
          addedFile = widget.pickedStudyMaterial!.studyMaterialFile;
        } else if (widget.pickedStudyMaterial!.pickedStudyMaterialTypeId == 2) {
          _selectedStudyMaterial = allStudyMaterialTypeItems.firstWhereOrNull(
                  (element) =>
                      element.studyMaterialType ==
                      StudyMaterialType.youtubeVideo) ??
              allStudyMaterialTypeItems.first;
          addedVideoThumbnailFile =
              widget.pickedStudyMaterial!.videoThumbnailFile;
          _youtubeLinkEditingController.text =
              widget.pickedStudyMaterial!.youTubeLink!;
        } else {
          _selectedStudyMaterial = allStudyMaterialTypeItems.firstWhereOrNull(
                  (element) =>
                      element.studyMaterialType ==
                      StudyMaterialType.uploadedVideoUrl) ??
              allStudyMaterialTypeItems.first;
          addedVideoThumbnailFile =
              widget.pickedStudyMaterial!.videoThumbnailFile;
          addedVideoFile = widget.pickedStudyMaterial!.studyMaterialFile;
        }
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _fileNameEditingController.dispose();
    _youtubeLinkEditingController.dispose();
    super.dispose();
  }

  bool isSupportedFileFormat(String fileName) {
    final supportedImageFormats = ['jpg', 'jpeg', 'png', 'heic', 'heif'];
    final supportedDocumentFormats = ['txt', 'pdf', 'docx'];
    final fileExtension = fileName.split('.').last.toLowerCase();

    return supportedImageFormats.contains(fileExtension) ||
        supportedDocumentFormats.contains(fileExtension);
  }

  void showErrorMessage(String messageKey) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: isDark ? const Color(0xFF2A2A2C) : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.red, size: 24),
            const SizedBox(width: 10),
            Text(
              'Info',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        content: Text(
          Utils.getTranslatedLabel(messageKey),
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void addStudyMaterial() {
    FocusManager.instance.primaryFocus?.unfocus();
    final pickedStudyMaterialId = _selectedStudyMaterial.id;

    if (_fileNameEditingController.text.trim().isEmpty) {
      showErrorMessage(pleaseEnterStudyMaterialNameKey);
      return;
    }

    if (pickedStudyMaterialId == 1 && addedFile == null) {
      showErrorMessage(pleaseSelectFileKey);
      return;
    }

    if (pickedStudyMaterialId != 1 && addedVideoThumbnailFile == null) {
      showErrorMessage(pleaseSelectThumbnailImageKey);
      return;
    }

    if (pickedStudyMaterialId == 2 &&
        (_youtubeLinkEditingController.text.trim().isEmpty ||
            !Uri.parse(_youtubeLinkEditingController.text.trim()).isAbsolute)) {
      showErrorMessage(pleaseEnterYoutubeLinkKey);
      return;
    }

    if (pickedStudyMaterialId == 3 && addedVideoFile == null) {
      showErrorMessage(pleaseSelectVideoKey);
      return;
    }

    if (pickedStudyMaterialId == 1 && !isSupportedFileFormat(addedFile!.name)) {
      showErrorMessage(supportedFileKey);
      return;
    }

    widget.onTapSubmit(
      PickedStudyMaterial(
        fileName: _fileNameEditingController.text.trim(),
        pickedStudyMaterialTypeId: pickedStudyMaterialId,
        studyMaterialFile:
            pickedStudyMaterialId == 1 ? addedFile : addedVideoFile,
        videoThumbnailFile: addedVideoThumbnailFile,
        youTubeLink: _youtubeLinkEditingController.text.trim(),
      ),
    );
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomsheet(
      titleLabelKey: addStudyMaterialKey,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: appContentHorizontalPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 15,
              ),
              //
              CustomSelectionDropdownSelectionButton(
                onTap: () {
                  Utils.showBottomSheet(
                      child: FilterSelectionBottomsheet<StudyMaterialTypeItem>(
                        selectedValue: _selectedStudyMaterial,
                        showFilterByLabel: false,
                        titleKey: studyMaterialTypeKey,
                        values: allStudyMaterialTypeItems,
                        onSelection: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedStudyMaterial = value;
                              addedFile = null;
                              addedVideoFile = null;
                              addedVideoThumbnailFile = null;
                              _youtubeLinkEditingController.clear();
                            });
                          }
                          Get.back();
                        },
                      ),
                      context: context);
                },
                titleKey: _selectedStudyMaterial.title,
                backgroundColor: Theme.of(context).colorScheme.surface,
              ),
              const SizedBox(
                height: 15,
              ),
              //
              //File name
              //
              CustomTextFieldContainer(
                hintTextKey: Utils.getTranslatedLabel(
                  studyMaterialNameKey,
                ),
                maxLines: 1,
                textEditingController: _fileNameEditingController,
                backgroundColor: Theme.of(context).colorScheme.surface,
              ),

              //
              //Select file picker. If study material type is fileUpload then it will pick file
              //else it will pick video thumbnail image
              //

              //
              //if file or images has been picked then show the pickedFile name and remove button
              //else show file picker option
              //
              addedFile != null
                  ? CustomFileContainer(
                      title: addedFile?.name ?? "",
                      onDelete: () {
                        addedFile = null;
                        setState(() {});
                      },
                    )
                  : addedVideoThumbnailFile != null
                      ? CustomFileContainer(
                          title: addedVideoThumbnailFile?.name ?? "",
                          onDelete: () {
                            addedVideoThumbnailFile = null;
                            setState(() {});
                          },
                        )
                      : UploadImageOrFileButton(
                          uploadFile: true,
                          customTitleKey:
                              _selectedStudyMaterial.studyMaterialType ==
                                      StudyMaterialType.file
                                  ? selectFileKey
                                  : selectThumbnailKey,
                          onTap: () async {
                            // Gunakan mixin untuk pick dan kompres otomatis
                            final compressedFiles = await pickAndCompressFiles(
                              allowMultiple: false,
                              type: _selectedStudyMaterial.studyMaterialType ==
                                      StudyMaterialType.file
                                  ? FileType.any
                                  : FileType.image,
                              maxSizeInMB: 2.0,
                              showProgressDialog: true,
                              context: context,
                            );

                            if (compressedFiles != null &&
                                compressedFiles.isNotEmpty) {
                              //if current selected study material type is file
                              if (context.mounted &&
                                  _selectedStudyMaterial.studyMaterialType ==
                                      StudyMaterialType.file) {
                                addedFile = compressedFiles.first;
                              } else {
                                addedVideoThumbnailFile = compressedFiles.first;
                              }
                              setState(() {});
                            }
                          },
                        ),

              const SizedBox(
                height: 15,
              ),
              _selectedStudyMaterial.studyMaterialType ==
                      StudyMaterialType.youtubeVideo
                  ? CustomTextFieldContainer(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      hintTextKey: youtubeLinkKey,
                      maxLines: 2,
                      bottomPadding: 0,
                      textEditingController: _youtubeLinkEditingController,
                    )
                  : _selectedStudyMaterial.studyMaterialType ==
                          StudyMaterialType.uploadedVideoUrl
                      ? addedVideoFile != null
                          ? CustomFileContainer(
                              onDelete: () {
                                addedVideoFile = null;
                                setState(() {});
                              },
                              title: addedVideoFile?.name ?? "",
                            )
                          : UploadImageOrFileButton(
                              uploadFile: true,
                              customTitleKey:
                                  _selectedStudyMaterial.studyMaterialType ==
                                          StudyMaterialType.file
                                      ? selectFileKey
                                      : selectVideoKey,
                              onTap: () async {
                                // Gunakan mixin untuk pick dan kompres otomatis
                                final compressedFiles =
                                    await pickAndCompressFiles(
                                  allowMultiple: false,
                                  type: FileType.video,
                                  maxSizeInMB:
                                      5.0, // Video biasanya lebih besar
                                  showProgressDialog: true,
                                  context: context,
                                );

                                if (compressedFiles != null &&
                                    compressedFiles.isNotEmpty) {
                                  addedVideoFile = compressedFiles.first;
                                  setState(() {});
                                }
                              },
                            )
                      : const SizedBox(),
              const SizedBox(
                height: 15,
              ),
              CustomRoundedButton(
                onTap: () {
                  addStudyMaterial();
                },
                widthPercentage: 0.9,
                backgroundColor: Theme.of(context).colorScheme.primary,
                buttonTitle: Utils.getTranslatedLabel(submitKey),
                showBorder: false,
                titleColor: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
