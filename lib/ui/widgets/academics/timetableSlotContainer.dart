import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';

class TimetableSlotContainer extends StatelessWidget {
  final String startTime;
  final String endTime;
  final String subjectName;
  final bool isForClass;
  final String? teacherName;
  final String note;
  final String? classSectionName;
  final Color? backgroundColor;

  const TimetableSlotContainer(
      {super.key,
      required this.startTime,
      required this.endTime,
      required this.subjectName,
      required this.isForClass,
      required this.note,
      this.classSectionName,
      this.teacherName,
      this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final titleTextStyle = TextStyle(
      color: Theme.of(context).colorScheme.secondary,
      fontSize: Utils.getScaledValue(context, 12),
    );
    final valueTextStyle = TextStyle(
        fontSize: Utils.getScaledValue(context, 15),
        fontWeight: FontWeight.w600);
    return Container(
      margin: const EdgeInsets.only(top: 10.0, bottom: 10.0),
      child: LayoutBuilder(builder: (context, boxConstraints) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            SizedBox(
                width: boxConstraints.maxWidth * (0.2),
                child: Column(
                  children: [
                    CustomTextContainer(
                      textKey: (startTime).isEmpty
                          ? "-"
                          : Utils.formatTime(
                              timeOfDay: TimeOfDay(
                                  hour: Utils.getHourFromTimeDetails(
                                      time: startTime),
                                  minute: Utils.getMinuteFromTimeDetails(
                                      time: startTime)),
                              context: context),
                      style: TextStyle(
                          fontSize: Utils.getScaledValue(context, 15),
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Text(Utils.getTimezoneLabel(),
                        style: TextStyle(
                          fontSize: Utils.getScaledValue(context, 12),
                        )),
                    const Spacer(),
                    Container(
                      height: Utils().getResponsiveHeight(context, 40),
                      width: Utils.getScaledValue(context, 1.5),
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    const Spacer(),
                    CustomTextContainer(
                      textKey: (endTime).isEmpty
                          ? "-"
                          : Utils.formatTime(
                              timeOfDay: TimeOfDay(
                                  hour: Utils.getHourFromTimeDetails(
                                      time: endTime),
                                  minute: Utils.getMinuteFromTimeDetails(
                                      time: endTime)),
                              context: context),
                      style: TextStyle(
                          fontSize: Utils.getScaledValue(context, 15.0),
                          fontWeight: FontWeight.bold),
                    ),
                    Text(Utils.getTimezoneLabel(),
                        style: TextStyle(
                          fontSize: Utils.getScaledValue(context, 12.0),
                        )),
                  ],
                )),
            SizedBox(
              width: boxConstraints.maxWidth * (0.05),
            ),
            SizedBox(
                width: boxConstraints.maxWidth * (0.7),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: appContentHorizontalPadding, vertical: 10),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: backgroundColor ??
                          (Theme.of(context).brightness == Brightness.light
                              ? Colors.white
                              : Theme.of(context).colorScheme.surface),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.transparent
                            : Colors.white.withValues(alpha: 0.1),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).brightness == Brightness.light
                              ? Colors.black.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]),
                  child: note.isNotEmpty
                      ? Center(
                          child: CustomTextContainer(
                            textKey: note.toLowerCase() == "break"
                                ? "istirahat"
                                : note,
                            style: const TextStyle(
                              fontSize: 18.0,
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ///[Subject name]
                            CustomTextContainer(
                              textKey: subjectKey,
                              style: titleTextStyle,
                            ),
                            CustomTextContainer(
                              textKey: subjectName,
                              style: valueTextStyle,
                            ),
                            const SizedBox(height: 10),
 
                            ///[Class and teacher name]
                            CustomTextContainer(
                              textKey: isForClass ? teacherKey : classKey,
                              style: titleTextStyle,
                            ),
                            CustomTextContainer(
                              textKey: isForClass
                                  ? (teacherName ?? "-")
                                  : (classSectionName ?? "-"),
                              style: valueTextStyle,
                            ),
                          ],
                        ),
                )),
          ],
        ));
      }),
    );
  }
}
