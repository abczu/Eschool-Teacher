import 'package:eschool_saas_staff/ui/styles/themeExtensions/customColorsExtension.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';

class UploadImageOrFileLimitButton extends StatelessWidget {
  final bool uploadFile;
  final bool includeImageFileOnlyAllowedNoteLimit;
  final String? customTitleKey;
  final Function()? onTap;
  const UploadImageOrFileLimitButton(
      {super.key,
      required this.uploadFile,
      this.includeImageFileOnlyAllowedNoteLimit = false,
      this.customTitleKey,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          radius: 5,
          onTap: onTap,
          child: Container(
            height: Utils().getResponsiveHeight(context, 40),
            padding: EdgeInsets.symmetric(
                horizontal: appContentHorizontalPadding, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.tertiary),
              color: Theme.of(context)
                  .extension<CustomColors>()!
                  .totalStaffOverviewBackgroundColor!
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context)
                      .extension<CustomColors>()!
                      .totalStaffOverviewBackgroundColor!,
                  radius: 25,
                  child: Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.surface,
                    size: 20,
                  ),
                ),
                CustomTextContainer(
                  textKey: customTitleKey ??
                      (uploadFile ? uploadFileKey : uploadImageKey),
                  style: TextStyle(
                      fontSize: Utils.getScaledValue(context, 15),
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .extension<CustomColors>()!
                          .totalStaffOverviewBackgroundColor!),
                )
              ],
            ),
          ),
        ),
        if (includeImageFileOnlyAllowedNoteLimit) ...[
          const SizedBox(
            height: 5,
          ),
          CustomTextContainer(
            textKey: onlyImageAndDocumentsAreAllowedNoteLimitKey,
            style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFE53935)
                    : Theme.of(context).extension<CustomColors>()!.redColor!,
                fontWeight: FontWeight.bold,
                fontSize: Utils.getScaledValue(context, 12)),
          ),
        ]
      ],
    );
  }
}
