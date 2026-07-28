import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonAvatar extends StatelessWidget {
  final double size;
  const SkeletonAvatar({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color shimmerBase = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final Color shimmerHighlight = isDark ? Colors.grey.shade700 : Colors.grey.shade100;
    return Shimmer.fromColors(
      baseColor: shimmerBase,
      highlightColor: shimmerHighlight,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(size / 6)),
      ),
    );
  }
}

