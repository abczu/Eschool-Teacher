import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/cubits/settings/homeScreenDataCubit.dart';
import 'package:eschool_saas_staff/data/models/system/holiday.dart';
import 'package:eschool_saas_staff/ui/screens/system/holidaysScreen.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/homeContainer/widgets/contentTitleWithViewmoreButton.dart';
import 'package:eschool_saas_staff/ui/widgets/system/holidayContainer.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class TeacherHolidaysContainer extends StatelessWidget {
  const TeacherHolidaysContainer({super.key});

  @override
  Widget build(BuildContext context) {
    List<Holiday> holidays = context.read<HomeScreenDataCubit>().getHolidays();

    // Filter out past holidays (endDate or startDate already passed)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    holidays = holidays.where((holiday) {
      final endDate = holiday.endDate != null
          ? DateTime.parse(holiday.endDate!)
          : DateTime.parse(holiday.startDate ?? "");
      return !endDate.isBefore(today);
    }).toList();

    // Sort holidays based on startDate
    holidays.sort((a, b) {
      // Parse the holiday dates as DateTime objects
      final dateA = DateTime.parse(a.startDate ?? "");
      final dateB = DateTime.parse(b.startDate ?? "");

      // Compare the entire DateTime object to ensure correct order
      return dateA.compareTo(dateB);
    });

    holidays = holidays.length > 5 ? holidays.sublist(0, 5) : holidays;
    return holidays.isEmpty
        ? const SizedBox()
        : Column(
            children: [
              const SizedBox(
                height: 15,
              ),
              ContentTitleWithViewMoreButton(
                contentTitleKey: holidaysKey,
                showViewMoreButton: true,
                viewMoreOnTap: () {
                  Get.toNamed(Routes.holidaysScreen,
                      arguments: HolidaysScreen.buildArguments(
                          holidays: context
                              .read<HomeScreenDataCubit>()
                              .getHolidays()));
                },
              ),
              const SizedBox(
                height: 15,
              ),
              SizedBox(
                height: 125,
                child: ListView.builder(
                  itemCount: holidays.length,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(
                      horizontal: appContentHorizontalPadding),
                  itemBuilder: (context, index) {
                    return HolidayContainer(
                        holiday: holidays[index],
                        margin: const EdgeInsetsDirectional.only(end: 25),
                        width: MediaQuery.of(context).size.width * (0.925));
                  },
                ),
              )
            ],
          );
  }
}

