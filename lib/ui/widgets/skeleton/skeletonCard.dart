import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonCard extends StatelessWidget {
  final double height;
  final double? width;
  final EdgeInsetsGeometry padding;

  const SkeletonCard(
      {super.key,
      this.height = 100,
      this.width,
      this.padding = const EdgeInsets.all(12)});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color shimmerBase = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final Color shimmerHighlight = isDark ? Colors.grey.shade700 : Colors.grey.shade100;
    return Shimmer.fromColors(
      baseColor: shimmerBase,
      highlightColor: shimmerHighlight,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Skeleton untuk Class Section Card (sesuai dengan teacherClassSectionScreen)
