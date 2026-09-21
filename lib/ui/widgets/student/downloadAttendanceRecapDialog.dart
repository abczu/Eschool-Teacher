import 'dart:io';
import 'package:eschool_saas_staff/cubits/academics/downloadAttendanceRecapCubit.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customCircularProgressIndicator.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/route_manager.dart';
import 'package:open_filex/open_filex.dart';

class DownloadAttendanceRecapDialog extends StatelessWidget {
  final String url;
  final String fileName;
  final bool isPreview;

  const DownloadAttendanceRecapDialog({
    super.key,
    required this.url,
    required this.fileName,
    this.isPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DownloadAttendanceRecapCubit()
        ..downloadRecap(url: url, fileName: fileName, isPreview: isPreview),
      child: BlocListener<DownloadAttendanceRecapCubit,
          DownloadAttendanceRecapState>(
        listener: (context, state) {
          if (state is DownloadAttendanceRecapSuccess) {
            Get.back();
            if (!isPreview) {
              Utils.showSnackBar(
                message: "File rekap berhasil diunduh ke folder Download",
                context: context,
              );
            }
            OpenFilex.open(state.downloadedFilePath);
          } else if (state is DownloadAttendanceRecapFailure) {
            Get.back();
            Utils.showSnackBar(message: state.errorMessage, context: context);
          }
        },
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SizedBox(
            height: 50,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CustomCircularProgressIndicator(
                  widthAndHeight: 18.0,
                  strokeWidth: 2.5,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 14.0),
                Flexible(
                  child: Text(
                    isPreview
                        ? "Sedang memuat pratinjau rekap..."
                        : "Sedang mengunduh rekap absensi...",
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

