import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonTeacherManageAssignmentSubmissionScreen extends StatelessWidget {
  final int itemCount;

  const SkeletonTeacherManageAssignmentSubmissionScreen({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = isDark ? Theme.of(context).cardColor : Colors.white;
    final Color shimmerBase = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final Color shimmerHighlight = isDark ? Colors.grey.shade700 : Colors.grey.shade100;
    final Color placeholderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white;

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 240), // Adjusted for app bar and filter
        physics: const BouncingScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          width: MediaQuery.of(context).size.width,
          child: Shimmer.fromColors(
            baseColor: shimmerBase,
            highlightColor: shimmerHighlight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header section
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: placeholderColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Container(
                          width: 20,
                          height: 20,
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 15,
                              width: 180,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              height: 13,
                              width: 100,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Assignment submission items
                ...List.generate(
                  itemCount,
                  (index) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 12,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Header with student info
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                          child: Row(
                            children: [
                              // Student avatar
                              Container(
                                width: 45,
                                height: 45,
                                margin: const EdgeInsets.only(left: 15, right: 10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: isDark ? Colors.grey.shade800 : Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),

                              Expanded(
                                child: Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),

                              // Status badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 14),
                                decoration: BoxDecoration(
                                  color: placeholderColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade300,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      height: 13,
                                      width: 60,
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Submission date and status info
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            height: 12,
                                            width: 80,
                                            decoration: BoxDecoration(
                                              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            height: 13,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(6),
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

                        // Expanded content simulation
                        if (index % 2 == 0) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Section header
                                Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    height: 15,
                                    width: 100,
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                  ),
                                ),

                                // Points section
                                Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.grey.shade900 : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isDark ? Colors.grey.shade800 : Colors.white,
                                        ),
                                        child: Container(
                                          width: 22,
                                          height: 22,
                                          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              height: 13,
                                              width: 60,
                                              decoration: BoxDecoration(
                                                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              height: 20,
                                              width: 80,
                                              decoration: BoxDecoration(
                                                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isDark ? Colors.grey.shade800 : Colors.white,
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 18,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
                                              borderRadius:
                                                  BorderRadius.circular(9),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Progress bar
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),

                                // Files section
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isDark ? Colors.grey.shade800 : Colors.white,
                                            ),
                                            child: Container(
                                              width: 22,
                                              height: 22,
                                              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            height: 14,
                                            width: 80,
                                            decoration: BoxDecoration(
                                              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(7),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // File item
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 42,
                                              height: 42,
                                              decoration: BoxDecoration(
                                                color: isDark ? Colors.grey.shade800 : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    height: 13,
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Container(
                                                    height: 12,
                                                    width: 120,
                                                    decoration: BoxDecoration(
                                                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
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
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton untuk Timetable Slot Container
