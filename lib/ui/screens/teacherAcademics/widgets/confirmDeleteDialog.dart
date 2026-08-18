import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  const ConfirmDeleteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      actions: [
        CupertinoButton(
          child: Text(
            Utils.getTranslatedLabel(yesKey),
            style: const TextStyle(
              color: Color(0xFFE53935), // Bright red (maroonLight)
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () {
            Get.back(result: true);
          },
        ),
        CupertinoButton(
          child: Text(
            Utils.getTranslatedLabel(noKey),
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          onPressed: () {
            Get.back();
          },
        ),
      ],
      backgroundColor: isDark ? const Color(0xFF2A2A2C) : Colors.white,
      content: Text(
        Utils.getTranslatedLabel(deleteDialogMessageKey),
        style: TextStyle(
          color: isDark ? Colors.grey.shade300 : Colors.black54,
        ),
      ),
      title: Text(
        Utils.getTranslatedLabel(deleteDialogTitleKey),
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
