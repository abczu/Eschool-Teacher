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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Container(
                    width: double.maxFinite,
                    padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade100,
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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF800020).withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.event_available_rounded,
                            color: const Color(0xFF800020).withValues(alpha: 0.6),
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Tidak Ada Cuti",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A1A),
                            letterSpacing: 0.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Tidak ada cuti hari ini",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade500,
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
