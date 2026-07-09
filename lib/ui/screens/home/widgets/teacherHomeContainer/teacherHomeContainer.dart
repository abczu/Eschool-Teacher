import 'package:eschool_saas_staff/cubits/academics/classesCubit.dart';
import 'package:eschool_saas_staff/cubits/authentication/authCubit.dart';
import 'package:eschool_saas_staff/cubits/settings/homeScreenDataCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/teacherMyTimetableCubit.dart';
import 'package:eschool_saas_staff/cubits/userDetails/staffAllowedPermissionsAndModulesCubit.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/homeContainer/widgets/homeContainerAppbar.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/teacherHomeContainer/widgets/teacherHolidaysContainer.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/teacherHomeContainer/widgets/teacherLeavesContainer.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/teacherHomeContainer/widgets/teacherPermissionContainer.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/teacherHomeContainer/widgets/teacherTodaysTimetableContainer.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/teacherHomeContainer/widgets/teacherHomeSkeletonLoader.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/utils/system/systemModulesAndPermissions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherHomeContainer extends StatefulWidget {
  const TeacherHomeContainer({super.key});

  @override
  State<TeacherHomeContainer> createState() => _TeacherHomeContainerState();
}

class _TeacherHomeContainerState extends State<TeacherHomeContainer>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  Widget _buildAppBar() {
    final profileImage =
        (context.read<AuthCubit>().getUserDetails().image ?? "");

    return HomeContainerAppbar(profileImage: profileImage);
  }

  void getHomeScreenData() {
    final staffAllowedPermissionsAndModulesCubit =
        context.read<StaffAllowedPermissionsAndModulesCubit>();

    // Fetch classes data to ensure class names are available for timetable
    context.read<ClassesCubit>().getClasses();

    context.read<HomeScreenDataCubit>().getHomeScreenData(
        holidayModuleEnabled: staffAllowedPermissionsAndModulesCubit
            .isPermissionGiven(permission: "holiday-list"),
        staffLeaveModuleEnabled: staffAllowedPermissionsAndModulesCubit
            .isPermissionGiven(permission: "leave-list"),
        listTeacherTimetablePermission: false,
        isTeacher: true);

    if (staffAllowedPermissionsAndModulesCubit.isPermissionGiven(
        permission: viewTimetablePermissionKey)) {
      context
          .read<TeacherMyTimetableCubit>()
          .getTeacherMyTimetable(isRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        // Background color
        Positioned.fill(
          child: Container(
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).scaffoldBackgroundColor
                : Colors.grey[50],
          ),
        ),
        BlocConsumer<StaffAllowedPermissionsAndModulesCubit,
            StaffAllowedPermissionsAndModulesState>(
          listener: (context, state) {
            if (state is StaffAllowedPermissionsAndModulesFetchSuccess) {
              getHomeScreenData();
            }
          },
          builder: (context, state) {
            if (state is StaffAllowedPermissionsAndModulesFetchSuccess) {
              return BlocBuilder<HomeScreenDataCubit, HomeScreenDataState>(
                builder: (context, homeScreenDataState) {
                  if (homeScreenDataState is HomeScreenDataFetchSuccess) {
                    final staffPermissionsCubit =
                        context.read<StaffAllowedPermissionsAndModulesCubit>();

                    return RefreshIndicator(
                      color: Theme.of(context).colorScheme.primary,
                      displacement: MediaQuery.of(context).padding.top + 100,
                      onRefresh: () async {
                        context
                            .read<StaffAllowedPermissionsAndModulesCubit>()
                            .getPermissionAndAllowedModules();
                      },
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top + 80,
                            bottom: 100),
                        child: Column(
                          children: [
                            const SizedBox(height: 45),
                            if (staffPermissionsCubit.isPermissionGiven(
                                permission: viewTimetablePermissionKey))
                              BlocProvider(
                                create: (BuildContext context) {
                                  return TeacherMyTimetableCubit()
                                    ..getTeacherMyTimetable();
                                },
                                child: const TeacherTodaysTimetableContainer(),
                              ),
                            if (staffPermissionsCubit.isPermissionGiven(
                                permission: approveLeavePermissionKey))
                              const TeacherPermissionContainer(),
                            if (staffPermissionsCubit.isPermissionGiven(
                                permission: "leave-list"))
                              const TeacherLeavesContainer(),
                            if (staffPermissionsCubit.isPermissionGiven(
                                permission: "holiday-list"))
                              const TeacherHolidaysContainer(),
                            const SizedBox(height: 15),
                          ],
                        ),
                      ),
                    );
                  }
                  if (homeScreenDataState is HomeScreenDataFetchFailure) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height * (0.15)),
                        child: CustomErrorWidget(
                          message: homeScreenDataState.errorMessage,
                          onRetry: () {
                            getHomeScreenData();
                          },
                          primaryColor: const Color(0xFF800020),
                        ),
                      ),
                    );
                  }

                  // Show skeleton loader instead of circular progress indicator
                  return Stack(
                    children: [
                      const TeacherHomeSkeletonLoader(),
                      _buildAppBar(),
                    ],
                  );
                },
              );
            } else if (state is StaffAllowedPermissionsAndModulesFetchFailure) {
              return CustomErrorWidget(
                message: state.errorMessage,
                onRetry: () {
                  context
                      .read<StaffAllowedPermissionsAndModulesCubit>()
                      .getPermissionAndAllowedModules();
                },
                primaryColor: const Color(0xFF800020),
              );
            } else {
              // Show skeleton loader for initial permission loading
              return Stack(
                children: [
                  const TeacherHomeSkeletonLoader(),
                  _buildAppBar(),
                ],
              );
            }
          },
        ),
        _buildAppBar(),
      ],
    );
  }
}
