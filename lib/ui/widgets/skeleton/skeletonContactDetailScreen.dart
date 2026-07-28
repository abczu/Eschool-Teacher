import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonContactDetailScreen extends StatelessWidget {
  const SkeletonContactDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact Info Card Skeleton
          _buildContactInfoCardSkeleton(context),

          const SizedBox(height: 16),

          // Message Card Skeleton
          _buildMessageCardSkeleton(context),

          const SizedBox(height: 16),

          // Replies Section Skeleton
          _buildRepliesSectionSkeleton(context),

          const SizedBox(height: 100), // Space for reply input
        ],
      ),
    );
  }

  Widget _buildContactInfoCardSkeleton(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = isDark ? Theme.of(context).cardColor : Colors.white;
    final Color shimmerBase = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final Color shimmerHighlight = isDark ? Colors.grey.shade700 : Colors.grey.shade100;
    final Color ph = isDark ? Colors.grey.shade700 : Colors.white;
    final Color subtleBg = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Shimmer.fromColors(
      baseColor: shimmerBase,
      highlightColor: shimmerHighlight,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: Colors.grey.shade800) : null,
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: ph,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 80,
                        decoration: BoxDecoration(
                          color: ph,
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 18,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: ph,
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ],
                  ),
                ),
                // Status chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ph,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    height: 12,
                    width: 50,
                    decoration: BoxDecoration(
                      color: subtleBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Contact Details
            _buildDetailRowSkeleton(ph),
            const SizedBox(height: 12),
            _buildDetailRowSkeleton(ph),
            const SizedBox(height: 12),
            _buildDetailRowSkeleton(ph),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRowSkeleton(Color ph) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: ph,
            borderRadius: BorderRadius.circular(9),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 14,
          width: 60,
          decoration: BoxDecoration(
            color: ph,
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: ph,
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageCardSkeleton(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = isDark ? Theme.of(context).cardColor : Colors.white;
    final Color shimmerBase = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final Color shimmerHighlight = isDark ? Colors.grey.shade700 : Colors.grey.shade100;
    final Color ph = isDark ? Colors.grey.shade700 : Colors.white;

    return Shimmer.fromColors(
      baseColor: shimmerBase,
      highlightColor: shimmerHighlight,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: Colors.grey.shade800) : null,
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: ph,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 16,
                  width: 60,
                  decoration: BoxDecoration(
                    color: ph,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Message content
            Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                color: ph,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 14,
              width: 280,
              decoration: BoxDecoration(
                color: ph,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 14,
              width: 200,
              decoration: BoxDecoration(
                color: ph,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepliesSectionSkeleton(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color shimmerBase = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final Color shimmerHighlight = isDark ? Colors.grey.shade700 : Colors.grey.shade100;
    final Color ph = isDark ? Colors.grey.shade700 : Colors.white;
    final Color subtleBorder = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final Color replyBg = isDark ? Theme.of(context).cardColor : Colors.white;

    return Shimmer.fromColors(
      baseColor: shimmerBase,
      highlightColor: shimmerHighlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: ph,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 16,
                width: 100,
                decoration: BoxDecoration(
                  color: ph,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Reply items
          for (int i = 0; i < 2; i++) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: replyBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: subtleBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: ph,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 12,
                              width: 80,
                              decoration: BoxDecoration(
                                color: ph,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              height: 10,
                              width: 60,
                              decoration: BoxDecoration(
                                color: ph,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 13,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: ph,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 13,
                    width: 250,
                    decoration: BoxDecoration(
                      color: ph,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
