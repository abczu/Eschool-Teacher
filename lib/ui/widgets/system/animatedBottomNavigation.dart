import 'package:eschool_saas_staff/data/models/system/bottomNavItem.dart';
import 'package:eschool_saas_staff/ui/widgets/system/appBarPainter.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AnimatedBottomNavigation extends StatefulWidget {
  final List<BottomNavItem> items;
  final int selectedIndex;
  final Function(int) onItemSelected;
  final Color? navigationBarColor;

  const AnimatedBottomNavigation({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    this.navigationBarColor,
  });

  @override
  State<AnimatedBottomNavigation> createState() =>
      _AnimatedBottomNavigationState();
}

class _AnimatedBottomNavigationState extends State<AnimatedBottomNavigation>
    with TickerProviderStateMixin {
  double horizontalPadding = 40.0;
  double horizontalMargin = 15.0;
  late int noOfIcons;

  // Updated maroon color palette to match TeacherAddAttendanceSubjectScreen
  final Color maroonPrimary = const Color(0xFF800020); // Main maroon color
  final Color maroonLight =
      const Color(0xFFAA6976); // Lighter maroon for accents
  final Color maroonDark =
      const Color(0xFF690013); // Darker maroon for subtle effects

  late double position;
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    noOfIcons = widget.items.length;
    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 275));
  }

  @override
  void didChangeDependencies() {
    position = getEndPosition(widget.selectedIndex);
    animation = Tween(begin: position, end: position).animate(controller);
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(AnimatedBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      animateDrop(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  double getEndPosition(int index) {
    // Calculate the width of each item section
    double totalWidth =
        MediaQuery.of(context).size.width - (2 * horizontalMargin);
    double itemWidth = (totalWidth - (2 * horizontalPadding)) / noOfIcons;

    // Calculate the center position of the selected item
    double itemCenterX =
        horizontalPadding + (itemWidth * index) + (itemWidth / 2);

    // Center the circle on the item (subtract half the circle width)
    return itemCenterX - 70.0;
  }

  void animateDrop(int index) {
    double newPosition = getEndPosition(index);
    animation = Tween(begin: position, end: newPosition).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));

    controller.reset();
    controller.forward().then((value) {
      position = newPosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          painter: AppBarPainter(
            animation.value,
            circleColor:
                maroonPrimary, // Use maroon primary color for the circle
            navigationBarColor: Theme.of(context).colorScheme.surface,
            selectedIndex: widget.selectedIndex,
          ),
          size: Size(MediaQuery.of(context).size.width - (2 * horizontalMargin),
              100.0),
          child: SizedBox(
            height: 140.0,
            width: MediaQuery.of(context).size.width - (2 * horizontalMargin),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(noOfIcons, (index) {
                  final item = widget.items[index];
                  final isSelected = index == widget.selectedIndex;
                  return GestureDetector(
                    onTap: () {
                      widget.onItemSelected(index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 275),
                      curve: Curves.easeOutCubic,
                      height: 125,
                      width: (MediaQuery.of(context).size.width -
                              (2 * horizontalMargin) -
                              (2 * horizontalPadding)) /
                          noOfIcons,
                      padding: const EdgeInsets.only(top: 14.0, bottom: 22.5),
                      alignment: isSelected
                          ? Alignment.topCenter
                          : Alignment.bottomCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 35.0,
                            width: 35.0,
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 275),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeOutCubic,
                                child: SvgPicture.asset(
                                  Utils.getImagePath(isSelected
                                      ? item.selectedIconPath
                                      : item.iconPath),
                                  key: ValueKey(
                                      '${isSelected ? 'selected' : 'normal'}${item.iconPath}'),
                                  height: 28.0,
                                  width: 28.0,
                                  colorFilter: ColorFilter.mode(
                                    isSelected
                                        ? Colors.white
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeInOutCubic,
                            opacity: isSelected ? 0.0 : 1.0,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 5),
                                CustomTextContainer(
                                  textKey: item.title,
                                  style: TextStyle(
                                    fontSize: Utils.getScaledValue(context, 14.0),
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
