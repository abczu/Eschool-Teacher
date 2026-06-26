import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ContentTitleWithViewMoreButton extends StatelessWidget {
  final String contentTitleKey;
  final bool? showViewMoreButton;
  final Function? viewMoreOnTap;
  const ContentTitleWithViewMoreButton(
      {super.key,
      required this.contentTitleKey,
      this.showViewMoreButton,
      this.viewMoreOnTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: appContentHorizontalPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomTextContainer(
            textKey: contentTitleKey,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          if (showViewMoreButton ?? false)
            InkWell(
              onTap: () => viewMoreOnTap?.call(),
              borderRadius: BorderRadius.circular(20),
              splashColor: const Color(0xFF800020).withValues(alpha: 0.1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFF800020).withValues(alpha: 0.05),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextContainer(
                      textKey: viewMoreKey,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF800020),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Color(0xFF800020),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
