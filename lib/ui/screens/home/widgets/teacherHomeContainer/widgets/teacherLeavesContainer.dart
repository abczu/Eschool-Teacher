import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/cubits/settings/homeScreenDataCubit.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/homeContainer/widgets/contentTitleWithViewmoreButton.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/teacherHomeContainer/widgets/roundedBackgroundContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/leave/leaveDetailsContainer.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class TeacherLeavesContainer extends StatelessWidget {
  const TeacherLeavesContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final homeCubit = context.read<HomeScreenDataCubit>();
    final todaysLeave = homeCubit.getTodayLeaves();

    return RoundedBackgroundContainer(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          ContentTitleWithViewMoreButton(
            contentTitleKey: leavesKey,
            showViewMoreButton: true,
            viewMoreOnTap: () {
              Get.toNamed(Routes.generalLeavesScreen);
            },
          ),
          const SizedBox(height: 16),
          todaysLeave.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Container(
                    width: double.maxFinite,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF800020).withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF800020).withValues(alpha: 0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          color: const Color(0xFF800020).withValues(alpha: 0.4),
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Tidak Ada Cuti",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF800020),
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        CustomTextContainer(
                          textKey: everyoneIsPresentTodayKey,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: todaysLeave.take(2).map((leave) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: LeaveDetailsContainer(
                          leaveDetails: leave,
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ],
      ),
    );
  }
}
