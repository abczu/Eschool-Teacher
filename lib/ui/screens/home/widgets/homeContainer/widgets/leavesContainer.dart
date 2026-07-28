import 'dart:ui';
import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/cubits/settings/homeScreenDataCubit.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/homeContainer/widgets/contentTitleWithViewmoreButton.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';

import 'package:eschool_saas_staff/ui/widgets/leave/leaveDetailsContainer.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/route_manager.dart';

class LeavesContainer extends StatelessWidget {
  const LeavesContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final todaysLeave = context.read<HomeScreenDataCubit>().getTodayLeaves();
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: appContentHorizontalPadding,
          vertical: appContentHorizontalPadding),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade200,
            width: isDark ? 0.5 : 1,
          )),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: isDark ? 12 : 0,
            sigmaY: isDark ? 12 : 0,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: appContentHorizontalPadding),
            child: Column(
              children: [
          const SizedBox(
            height: 15,
          ),
          ContentTitleWithViewMoreButton(
            showViewMoreButton: true,
            contentTitleKey: leavesKey,
            viewMoreOnTap: () {
              Get.toNamed(Routes.generalLeavesScreen);
            },
          ),
          todaysLeave.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
                  child: Container(
                    width: double.maxFinite,
                    padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2A2C)
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          color: Colors.grey[400],
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        CustomTextContainer(
                          textKey: everyoneIsPresentTodayKey,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: 0.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(
                      height: 15,
                    ),
                    LeaveDetailsContainer(
                      leaveDetails: todaysLeave.first,
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    todaysLeave.length > 2
                        ? LeaveDetailsContainer(leaveDetails: todaysLeave[1])
                        : const SizedBox(),
                  ],
                )
        ],
      ),
    ),
    ),
    ),
    );
  }
}
