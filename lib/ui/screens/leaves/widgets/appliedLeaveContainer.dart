import 'package:eschool_saas_staff/data/models/leave/leaveRequest.dart';
import 'package:eschool_saas_staff/ui/screens/leave/leaveRequestsScreen.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextButton.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/statusWithFadedBackgroundContainer.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';

class AppliedLeaveContainer extends StatelessWidget {
  final int index;
  final LeaveRequest leaveRequest;
  const AppliedLeaveContainer(
      {super.key, required this.index, required this.leaveRequest});

  @override
  Widget build(BuildContext context) {
    final status =
        getLeaveRequestStatusEnumFromValue(leaveRequest.status ?? 0);
    final bool isApproved = status == LeaveRequestStatus.approved;
    final bool isRejected = status == LeaveRequestStatus.rejected;
    final Color statusColor = isApproved
        ? Colors.green.shade700
        : isRejected
            ? Colors.red.shade700
            : Theme.of(context).colorScheme.primary;
    final IconData statusIcon = isApproved
        ? Icons.check_circle_rounded
        : isRejected
            ? Icons.cancel_rounded
            : Icons.schedule_rounded;
    final int dayCount = leaveRequest.leaveDetail?.length ?? 0;
    return GestureDetector(
      onTap: () {
        Utils.showBottomSheet(
            child: AppliedLeaveDetailsBottomsheet(leaveRequest: leaveRequest),
            context: context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: statusColor.withValues(alpha: 0.35), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(statusIcon, color: statusColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextContainer(
                    textKey: Utils.formatDateLeave(
                      DateTime.parse(leaveRequest.fromDate ?? ""),
                    ),
                    style: TextStyle(
                      fontSize: Utils.getScaledValue(context, 13),
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                  ),
                  if (dayCount > 0)
                    Text(
                      '$dayCount hari • ${leaveRequest.reason ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Utils.getScaledValue(context, 12),
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusWithFadedBackgroundContainer(
                backgroundColor: statusColor.withValues(alpha: 0.12),
                textColor: statusColor,
                titleKey: getLeaveRequestStatusKey(status)),
          ],
        ),
      ),
    );
  }
}

class AppliedLeaveDetailsBottomsheet extends StatelessWidget {
  final LeaveRequest leaveRequest;
  const AppliedLeaveDetailsBottomsheet({super.key, required this.leaveRequest});

  String translateLeaveType(String? type) {
    if (type == null) return "";

    switch (type) {
      case "Full":
        return "Sehari Penuh"; // Terjemahan ke bahasa Indonesia
      case "First Half":
        return "Paruh Pertama";
      case "Second Half":
        return "Paruh Kedua";
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomsheet(
        titleLabelKey: leaveDetailsKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 10.0,
            ),
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: appContentHorizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextContainer(
                    textKey: leaveReasonKey,
                    style: TextStyle(
                        fontSize: Utils.getScaledValue(context, 15),
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.76)),
                  ),
                  CustomTextContainer(
                    textKey: leaveRequest.reason ?? "",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: Utils.getScaledValue(context, 17)),
                  ),
                ],
              ),
            ),
            (leaveRequest.attachments?.isNotEmpty ?? false)
                ? Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: appContentHorizontalPadding),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 10.0,
                        ),
                        CustomTextButton(
                          buttonTextKey: viewAttachmentsKey,
                          onTapButton: () {
                            Utils.showBottomSheet(
                                child: LeaveAttachmentsBottomsheet(
                                    files: leaveRequest.attachments!),
                                context: context);
                          },
                          textStyle: TextStyle(
                            fontSize: Utils.getScaledValue(context, 15),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      ],
                    ),
                  )
                : const SizedBox(),
            ...leaveRequest.leaveDetail
                    ?.map((leaveDetail) => ListTile(
                          subtitle: CustomTextContainer(
                            textKey: translateLeaveType(leaveDetail.type),
                            style: TextStyle(
                                fontSize: Utils.getScaledValue(context, 15)),
                          ),
                          title: CustomTextContainer(
                            textKey:
                                Utils.formatDate(DateTime.parse(leaveDetail.date!)),
                            style: TextStyle(
                                fontSize: Utils.getScaledValue(context, 15)),
                          ),
                        ))
                    .toList() ??
                [],
            const SizedBox(
              height: 25.0,
            ),
          ],
        ));
  }
}
