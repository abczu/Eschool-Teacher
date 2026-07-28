import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/cubits/settings/homeScreenDataCubit.dart';
import 'package:eschool_saas_staff/data/models/auth/userDetails.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/homeContainer/widgets/contentTitleWithViewmoreButton.dart';
import 'package:eschool_saas_staff/ui/screens/academics/teacherTimeTableDetailsScreen.dart';
import 'package:eschool_saas_staff/ui/screens/staff/teachersScreen.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/profileImageContainer.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/route_manager.dart';
import 'dart:ui';

class TeachersTimeTableContainer extends StatelessWidget {
  const TeachersTimeTableContainer({super.key});

  Widget _buildTeacherDetailsContainer(
      {required double width,
      required BuildContext context,
      required UserDetails teacher}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Get.toNamed(Routes.teacherTimeTableDetailsScreen,
            arguments: TeacherTimeTableDetailsScreen.buildArguments(
                teacherDetails: teacher));
      },
      child: Container(
        width: width,
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
            width: isDark ? 0.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: isDark ? 12 : 0,
              sigmaY: isDark ? 12 : 0,
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileImageContainer(
                    imageUrl: teacher.image ?? "",
                    heightAndWidth: 50,
                  ),
                  const Spacer(),
                  CustomTextContainer(
                    textKey: teacher.firstName ?? "",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<UserDetails> teachers =
        context.read<HomeScreenDataCubit>().getTeachers();

    teachers = teachers.length > 4 ? teachers.sublist(0, 4) : teachers;

    return teachers.isEmpty
        ? const SizedBox()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 15,
              ),
              ContentTitleWithViewMoreButton(
                contentTitleKey: teachersTimetableKey,
                viewMoreOnTap: () {
                  Get.toNamed(Routes.teachersScreen,
                      arguments: TeachersScreen.buildArguments(
                          teacherNavigationType:
                              TeacherNavigationType.timetable));
                },
              ),
              const SizedBox(
                height: 15,
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: appContentHorizontalPadding),
                child: LayoutBuilder(builder: (context, boxConstraints) {
                  return Wrap(
                    alignment: WrapAlignment.start,
                    spacing: boxConstraints.maxWidth * (0.04),
                    runSpacing: 15,
                    children: teachers
                        .map(
                          (teacher) => _buildTeacherDetailsContainer(
                              teacher: teacher,
                              width: boxConstraints.maxWidth * (0.48),
                              context: context),
                        )
                        .toList(),
                  );
                }),
              ),
            ],
          );
  }
}
