import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonExamCard extends StatelessWidget {
  const SkeletonExamCard({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Adaptive colors for dark/light mode
    final Color cardBg = isDark ? Theme.of(context).cardColor : Colors.white;
    final Color shimmerBase = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final Color shimmerHighlight = isDark ? Colors.grey.shade700 : Colors.grey.shade100;
    final Color headerBg = isDark ? Colors.grey.shade800.withValues(alpha: 0.6) : Colors.grey.shade200;
    final Color placeholderBg = isDark ? Colors.grey.shade700 : Colors.white;
    final Color innerPlaceholder = isDark ? Colors.grey.shade600 : Colors.grey.shade200;
    final Color footerBg = isDark ? Colors.grey.shade800.withValues(alpha: 0.3) : Colors.grey.shade50;
    final Color footerBorder = isDark ? Colors.grey.shade700 : Colors.grey.shade200;

    return Container(
      margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header dengan status & date (mirip dengan exam card asli)
          Container(
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: Shimmer.fromColors(
              baseColor: shimmerBase,
              highlightColor: shimmerHighlight,
              child: Row(
                children: [
                  // Status indicator
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: placeholderBg,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 16,
                    width: 100,
                    decoration: BoxDecoration(
                      color: placeholderBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const Spacer(),
                  // Date container
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: placeholderBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: innerPlaceholder,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          height: 12,
                          width: 40,
                          decoration: BoxDecoration(
                            color: innerPlaceholder,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main content (mirip dengan exam card asli)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Shimmer.fromColors(
              baseColor: shimmerBase,
              highlightColor: shimmerHighlight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day container (mirip dengan exam card asli)
                  Container(
                    width: 65,
                    height: 80,
                    decoration: BoxDecoration(
                      color: placeholderBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 24,
                          width: 30,
                          decoration: BoxDecoration(
                            color: innerPlaceholder,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 14,
                          width: 40,
                          decoration: BoxDecoration(
                            color: innerPlaceholder,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Exam details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Exam name
                        Container(
                          height: 18,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: placeholderBg,
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 16,
                          width: 150,
                          decoration: BoxDecoration(
                            color: placeholderBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Class info container
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: placeholderBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: innerPlaceholder,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                height: 14,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: innerPlaceholder,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer dengan timetable indicator (mirip dengan exam card asli)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: footerBg,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border(
                top: BorderSide(
                  color: footerBorder,
                  width: 1,
                ),
              ),
            ),
            child: Shimmer.fromColors(
              baseColor: shimmerBase,
              highlightColor: shimmerHighlight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: placeholderBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 13,
                        width: 120,
                        decoration: BoxDecoration(
                          color: placeholderBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 13,
                    width: 80,
                    decoration: BoxDecoration(
                      color: placeholderBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton untuk Leave Card
