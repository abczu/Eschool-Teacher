import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/cubits/settings/homeScreenDataCubit.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/homeContainer/widgets/contentTitleWithViewmoreButton.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/teacherHomeContainer/widgets/roundedBackgroundContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
// import 'package:eschool_saas_staff/ui/widgets/leave/leaveDetailsContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/permissionDetailsContainer.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class TeacherPermissionContainer extends StatelessWidget {
  const TeacherPermissionContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1);

    final todaysPermission =
        context.read<HomeScreenDataCubit>().getTodayPermission();
    return RoundedBackgroundContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ContentTitleWithViewMoreButton(
            contentTitleKey: permissionStudentKey,
            showViewMoreButton: true,
            viewMoreOnTap: () {
              Get.toNamed(Routes.generalPermissionScreen);
            },
          ),
          const SizedBox(
            height: 15,
          ),
          todaysPermission.isEmpty
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
                          "Tidak Ada Surat Izin",
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
                          "Tidak ada surat izin hari ini",
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
              : Column(
                  children: [
                    PermissionDetailsContainer(
                      permissionDetails: todaysPermission[0],
                      overflow: true,
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    todaysPermission.length > 2
                        ? PermissionDetailsContainer(
                            permissionDetails: todaysPermission[1],
                            overflow: true,
                          )
                        : const SizedBox(),
                  ],
                ),
        ],
      ),
    );
  }
}
