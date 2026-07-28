import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';

class TeacherHomeSkeletonLoader extends StatefulWidget {
  const TeacherHomeSkeletonLoader({super.key});

  @override
  State<TeacherHomeSkeletonLoader> createState() =>
      _TeacherHomeSkeletonLoaderState();
}

class _TeacherHomeSkeletonLoaderState extends State<TeacherHomeSkeletonLoader>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 80,
          bottom: 100,
        ),
        child: Column(
          children: [
            const SizedBox(height: 45),

            // Today's Timetable Skeleton
            _buildTimetableSkeleton(context),

            // Permission Container Skeleton
            _buildPermissionSkeleton(context),

            // Leaves Container Skeleton
            _buildLeavesSkeleton(context),

            // Holidays Container Skeleton
            _buildHolidaysSkeleton(context),

            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerWrapper({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
    Duration? period,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: baseColor ?? (isDark ? Colors.grey.shade800 : Colors.grey[300]!),
      highlightColor: highlightColor ?? (isDark ? Colors.grey.shade700 : Colors.grey[50]!),
      period: period ?? const Duration(milliseconds: 1800),
      child: child,
    );
  }

  Widget _buildRoundedContainer({
    required double height,
    double? width,
    double borderRadius = 12.0,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    Color? color,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      width: width,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? (isDark ? Colors.grey.shade700 : Colors.white),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  Widget _buildContainerSkeleton({
    required BuildContext context,
    required List<Widget> children,
    double? margin,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: margin ?? 16.0,
        vertical: 15.0,
      ),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20.0),
        border: isDark ? Border.all(color: Colors.grey.shade800) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTitleWithViewMore(BuildContext context, double titleWidth) {
    return _buildShimmerWrapper(
      period: const Duration(milliseconds: 1600),
      child: Row(
        children: [
          _buildRoundedContainer(
            height: 24,
            width: titleWidth,
            borderRadius: 6,
          ),
          const Spacer(),
          _buildRoundedContainer(
            height: 20,
            width: 70,
            borderRadius: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableSkeleton(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return _buildContainerSkeleton(
      context: context,
      children: [
        // Title Skeleton
        _buildTitleWithViewMore(
            context, MediaQuery.of(context).size.width * 0.4),

        const SizedBox(height: 20),

        // Timetable Slots Skeleton
        ...List.generate(
          2,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildShimmerWrapper(
              period: Duration(milliseconds: 1800 + (index * 200)),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : Colors.grey[200]!,
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildRoundedContainer(
                          height: 18,
                          width: MediaQuery.of(context).size.width * 0.35,
                          borderRadius: 4,
                        ),
                        const Spacer(),
                        _buildRoundedContainer(
                          height: 16,
                          width: 80,
                          borderRadius: 8,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRoundedContainer(
                      height: 16,
                      width: MediaQuery.of(context).size.width * 0.25,
                      borderRadius: 4,
                    ),
                    const SizedBox(height: 8),
                    _buildRoundedContainer(
                      height: 14,
                      width: MediaQuery.of(context).size.width * 0.6,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // View More Button Skeleton
        const SizedBox(height: 10),
        _buildShimmerWrapper(
          period: const Duration(milliseconds: 2000),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRoundedContainer(
                  height: 16,
                  width: 80,
                  borderRadius: 4,
                ),
                const SizedBox(width: 5),
                _buildRoundedContainer(
                  height: 16,
                  width: 16,
                  borderRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionSkeleton(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return _buildContainerSkeleton(
      context: context,
      children: [
        // Title with View More
        _buildTitleWithViewMore(
            context, MediaQuery.of(context).size.width * 0.35),

        const SizedBox(height: 20),

        // Permission Cards Skeleton
        ...List.generate(
          2,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index == 0 ? 15.0 : 0),
            child: _buildShimmerWrapper(
              period: Duration(milliseconds: 1900 + (index * 150)),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : Colors.grey[200]!,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar
                    _buildRoundedContainer(
                      height: 50,
                      width: 50,
                      borderRadius: 25,
                    ),
                    const SizedBox(width: 12),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRoundedContainer(
                            height: 16,
                            width: MediaQuery.of(context).size.width *
                                (0.4 - index * 0.05),
                            borderRadius: 4,
                          ),
                          const SizedBox(height: 8),
                          _buildRoundedContainer(
                            height: 14,
                            width: MediaQuery.of(context).size.width *
                                (0.3 + index * 0.1),
                            borderRadius: 4,
                          ),
                          const SizedBox(height: 6),
                          _buildRoundedContainer(
                            height: 12,
                            width: MediaQuery.of(context).size.width *
                                (0.5 - index * 0.08),
                            borderRadius: 4,
                          ),
                        ],
                      ),
                    ),

                    // Status Badge
                    _buildRoundedContainer(
                      height: 24,
                      width: 60,
                      borderRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeavesSkeleton(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return _buildContainerSkeleton(
      context: context,
      children: [
        // Title with View More
        _buildTitleWithViewMore(
            context, MediaQuery.of(context).size.width * 0.25),

        const SizedBox(height: 20),

        // Leave Cards Skeleton
        ...List.generate(
          2,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index == 0 ? 15.0 : 0),
            child: _buildShimmerWrapper(
              period: Duration(milliseconds: 2000 + (index * 300)),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : Colors.grey[200]!,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar
                    _buildRoundedContainer(
                      height: 50,
                      width: 50,
                      borderRadius: 25,
                    ),
                    const SizedBox(width: 12),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRoundedContainer(
                            height: 16,
                            width: MediaQuery.of(context).size.width *
                                (0.35 + index * 0.1),
                            borderRadius: 4,
                          ),
                          const SizedBox(height: 8),
                          _buildRoundedContainer(
                            height: 14,
                            width: MediaQuery.of(context).size.width *
                                (0.45 - index * 0.05),
                            borderRadius: 4,
                          ),
                          const SizedBox(height: 6),
                          _buildRoundedContainer(
                            height: 12,
                            width: MediaQuery.of(context).size.width *
                                (0.6 - index * 0.15),
                            borderRadius: 4,
                          ),
                        ],
                      ),
                    ),

                    // Date Badge
                    _buildRoundedContainer(
                      height: 24,
                      width: 50,
                      borderRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHolidaysSkeleton(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        const SizedBox(height: 15),

        // Title with View More
        Padding(
          padding:
              EdgeInsets.symmetric(horizontal: appContentHorizontalPadding),
          child: _buildTitleWithViewMore(
              context, MediaQuery.of(context).size.width * 0.3),
        ),

        const SizedBox(height: 15),

        // Horizontal Holiday Cards
        SizedBox(
          height: 125,
          child: ListView.builder(
            itemCount: 3,
            scrollDirection: Axis.horizontal,
            padding:
                EdgeInsets.symmetric(horizontal: appContentHorizontalPadding),
            itemBuilder: (context, index) {
              return _buildShimmerWrapper(
                period: Duration(milliseconds: 2100 + (index * 400)),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.925,
                  margin: const EdgeInsetsDirectional.only(end: 25),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: isDark ? Colors.grey.shade800 : Colors.grey[200]!,
                      width: 1.0,
                    ),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Date Container
                        Container(
                          width: 60,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade800 : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildRoundedContainer(
                                height: 18,
                                width: 30,
                                borderRadius: 4,
                                color: isDark ? Colors.grey.shade700 : Colors.grey[400],
                              ),
                              const SizedBox(height: 6),
                              _buildRoundedContainer(
                                height: 14,
                                width: 40,
                                borderRadius: 4,
                                color: isDark ? Colors.grey.shade700 : Colors.grey[400],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildRoundedContainer(
                                height: 18,
                                width: MediaQuery.of(context).size.width *
                                    (0.5 - index * 0.05),
                                borderRadius: 4,
                              ),
                              const SizedBox(height: 8),
                              _buildRoundedContainer(
                                height: 14,
                                width: MediaQuery.of(context).size.width *
                                    (0.4 + index * 0.03),
                                borderRadius: 4,
                              ),
                              const SizedBox(height: 6),
                              _buildRoundedContainer(
                                height: 12,
                                width: MediaQuery.of(context).size.width *
                                    (0.3 - index * 0.02),
                                borderRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
