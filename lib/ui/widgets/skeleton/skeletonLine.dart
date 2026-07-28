import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLine extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius? borderRadius;

  const SkeletonLine(
      {super.key,
      this.height = 12,
      this.width = double.infinity,
      this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color shimmerBase = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final Color shimmerHighlight = isDark ? Colors.grey.shade700 : Colors.grey.shade100;
    return Shimmer.fromColors(
      baseColor: shimmerBase,
      highlightColor: shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius ?? BorderRadius.circular(6)),
      ),
    );
  }
}

