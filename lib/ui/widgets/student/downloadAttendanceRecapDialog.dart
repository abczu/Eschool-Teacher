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

  const DownloadAttendanceRecapDialog({
    super.key,
    required this.url,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DownloadAttendanceRecapCubit()..downloadRecap(url: url, fileName: fileName),
      child: BlocListener<DownloadAttendanceRecapCubit, DownloadAttendanceRecapState>(
        listener: (context, state) {
          if (state is DownloadAttendanceRecapSuccess) {
            Get.back();
            OpenFilex.open(state.downloadedFilePath);
          } else if (state is DownloadAttendanceRecapFailure) {
            Get.back();
            Utils.showSnackBar(message: state.errorMessage, context: context);
          }
        },
        child: AlertDialog(
          content: SizedBox(
            height: 50,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CustomCircularProgressIndicator(
                  widthAndHeight: 15.0,
                  strokeWidth: 2.0,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10.0),
                const Flexible(
                  child: Text("Sedang mengunduh rekap absensi...")
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
