import 'dart:io';

import 'package:eschool_saas_staff/cubits/payRoll/downloadPayRollSlipCubit.dart';
import 'package:eschool_saas_staff/data/models/payroll/payRoll.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customCircularProgressIndicator.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/route_manager.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

class DownloadPayRollSlipDialog extends StatefulWidget {
  final PayRoll payRoll;
  const DownloadPayRollSlipDialog({super.key, required this.payRoll});

  @override
  State<DownloadPayRollSlipDialog> createState() =>
      _DownloadPayRollSlipDialogState();
}

class _DownloadPayRollSlipDialogState extends State<DownloadPayRollSlipDialog> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (mounted) {
        debugPrint("=== UI INITIATED PAYROLL PDF DOWNLOAD ===");
        debugPrint("Payroll Details:");
        debugPrint("ID: ${widget.payRoll.id}");
        debugPrint("Title: ${widget.payRoll.title}");
        debugPrint("Month: ${widget.payRoll.month}");
        debugPrint("Year: ${widget.payRoll.year}");
        debugPrint("Amount: ${widget.payRoll.amount}");

        context.read<DownloadPayRollSlipCubit>().downloadPayRollSlip(
            payRollId: widget.payRoll.id ?? 0,
            payRollSlipTitle: widget.payRoll.title ?? "-");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DownloadPayRollSlipCubit, DownloadPayRollSlipState>(
      listener: (context, state) {
        if (state is DownloadPayRollSlipSuccess) {
          Get.back();

          // Verify file exists before trying to open
          final file = File(state.downloadedFilePath);
          if (file.existsSync()) {
            OpenFilex.open(state.downloadedFilePath).then((result) {
              debugPrint("File open result: ${result.message}");

              // If file opening failed, show a user-friendly message
              if (result.type != ResultType.done && context.mounted) {
                Utils.showSnackBar(
                    message:
                        "Slip gaji berhasil diunduh namun tidak dapat dibuka otomatis. File tersimpan di: ${state.downloadedFilePath}",
                    context: context);
              }
            });
          } else {
            if (context.mounted) {
              Utils.showSnackBar(
                  message:
                      "File slip gaji tidak dapat ditemukan setelah download",
                  context: context);
            }
          }
        } else if (state is DownloadPayRollSlipFailure) {
          Get.back();

          // Show more user-friendly error messages
          String userMessage = state.errorMessage;
          if (userMessage.contains("format") ||
              userMessage.contains("decode")) {
            userMessage =
                "Format file slip gaji tidak valid. Silakan coba lagi atau hubungi administrator.";
          } else if (userMessage.contains("network") ||
              userMessage.contains("connection")) {
            userMessage =
                "Masalah koneksi internet. Periksa koneksi Anda dan coba lagi.";
          } else if (userMessage.contains("empty")) {
            userMessage =
                "Data slip gaji kosong. Silakan hubungi administrator.";
          }

          if (context.mounted) {
            Utils.showSnackBar(message: userMessage, context: context);
          }
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
                  child:
                      CustomTextContainer(textKey: downloadingSalarySlipKey)),
            ],
          ),
        ),
      ),
    );
  }
}

