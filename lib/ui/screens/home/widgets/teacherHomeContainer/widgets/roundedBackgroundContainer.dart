import 'dart:ui';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:flutter/material.dart';

class RoundedBackgroundContainer extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  const RoundedBackgroundContainer(
      {super.key,
      required this.child,
      this.color,
      this.borderRadius,
      this.padding,
      this.margin});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double radius = borderRadius ?? 24;

    return Container(
      margin: margin ??
          EdgeInsets.symmetric(
              horizontal: appContentHorizontalPadding,
              vertical: appContentHorizontalPadding),
      decoration: BoxDecoration(
          color: color ?? (isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Theme.of(context).colorScheme.surface),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            width: isDark ? 0.5 : 1,
          )),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: isDark ? 12 : 0,
            sigmaY: isDark ? 12 : 0,
          ),
          child: Padding(
            padding: padding ??
                EdgeInsets.symmetric(
                  vertical: appContentHorizontalPadding,
                  horizontal: appContentHorizontalPadding,
                ),
            child: child,
          ),
        ),
      ),
    );
  }
}
