import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';

class SkeletonTimetableSlot extends StatelessWidget {
  const SkeletonTimetableSlot({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color shimmerBase = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final Color shimmerHighlight = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return Container(
      margin: const EdgeInsets.only(top: 10.0, bottom: 10.0),
      height: Utils().getResponsiveHeight(context, 150),
      child: LayoutBuilder(builder: (context, boxConstraints) {
        return Row(
          children: [
            // Time column on the left
            SizedBox(
              width: boxConstraints.maxWidth * (0.2),
              child: Shimmer.fromColors(
                baseColor: shimmerBase,
                highlightColor: shimmerHighlight,
                child: Column(
                  children: [
                    // Start time
                    Container(
                      height: 18,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Timezone label
                    Container(
                      height: 12,
                      width: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const Spacer(),
                    // Time line
                    Container(
                      height: Utils().getResponsiveHeight(context, 65),
                      width: 2,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const Spacer(),
                    // End time
                    Container(
                      height: 18,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    // Timezone label
                    Container(
                      height: 12,
                      width: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: boxConstraints.maxWidth * (0.05)),
            // Content area on the right
            SizedBox(
              width: boxConstraints.maxWidth * (0.7),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: appContentHorizontalPadding, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                child: Shimmer.fromColors(
                  baseColor: shimmerBase,
                  highlightColor: shimmerHighlight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject label
                      Container(
                        height: 12,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Subject name
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const Spacer(),
                      // Class/Teacher label
                      Container(
                        height: 12,
                        width: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Class/Teacher name
                      Container(
                        height: 16,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// Skeleton untuk Home Container (halaman beranda)
