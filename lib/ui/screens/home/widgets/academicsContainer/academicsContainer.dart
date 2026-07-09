import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool_saas_staff/cubits/authentication/authCubit.dart';
import 'package:eschool_saas_staff/cubits/userDetails/staffAllowedPermissionsAndModulesCubit.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/academicsContainer/widgets/staffAcademicsContainer.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/academicsContainer/widgets/teacherAcademicsContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customCircularProgressIndicator.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eschool_saas_staff/ui/widgets/system/profilePreview.dart';
import 'dart:math' as math;

class AcademicsContainer extends StatefulWidget {
  const AcademicsContainer({super.key});

  @override
  State<AcademicsContainer> createState() => _AcademicsContainerState();
}

class _AcademicsContainerState extends State<AcademicsContainer>
    with
        TickerProviderStateMixin,
        WidgetsBindingObserver,
        AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late AnimationController _glowAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _rotationAnimationController;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    // Refined glow animation - more subtle and elegant
    _glowAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowAnimationController,
        curve: Curves.easeInOutSine, // Smoother curve
      ),
    );

    // Gentle pulse animation - less aggressive
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOutCubic, // More elegant curve
      ),
    );

    // Slower, more graceful rotation
    _rotationAnimationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _rotationAnimationController,
        curve: Curves.linear,
      ),
    );

    // Start animations with delays for more natural feel
    _glowAnimationController.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 500), () {
      _pulseAnimationController.repeat(reverse: true);
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      _rotationAnimationController.repeat();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _glowAnimationController.stop();
        _pulseAnimationController.stop();
        _rotationAnimationController.stop();
        break;
      case AppLifecycleState.resumed:
        if (!_glowAnimationController.isAnimating) {
          _glowAnimationController.repeat(reverse: true);
        }
        if (!_pulseAnimationController.isAnimating) {
          _pulseAnimationController.repeat(reverse: true);
        }
        if (!_rotationAnimationController.isAnimating) {
          _rotationAnimationController.repeat();
        }
        break;
      case AppLifecycleState.inactive:
        _glowAnimationController.stop();
        _pulseAnimationController.stop();
        _rotationAnimationController.stop();
        break;
      case AppLifecycleState.detached:
        _glowAnimationController.stop();
        _pulseAnimationController.stop();
        _rotationAnimationController.stop();
        break;
      case AppLifecycleState.hidden:
        _glowAnimationController.stop();
        _pulseAnimationController.stop();
        _rotationAnimationController.stop();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _glowAnimationController.dispose();
    _pulseAnimationController.dispose();
    _rotationAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Set system UI overlay style to ensure status bar is properly handled
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return BlocBuilder<AuthCubit, AuthState>(builder: (context, state) {
      final bool isDark = Theme.of(context).brightness == Brightness.dark;
      final Color maroonPrimary = isDark ? const Color(0xFF8B1F41) : const Color(0xFF800020);
      final Color maroonLight = isDark ? const Color(0xFFA84B5C) : const Color(0xFFAA6976);
      final Color maroonDark = isDark ? const Color(0xFF4A0E17) : const Color.fromARGB(255, 124, 9, 31);
      final profileImage = context.read<AuthCubit>().getUserDetails().image ?? "";

      return Stack(
        children: [
          // Background color
          Positioned.fill(
            child: Container(
              color: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.grey[50],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: BlocBuilder<StaffAllowedPermissionsAndModulesCubit,
                StaffAllowedPermissionsAndModulesState>(
              builder: (context, state) {
                if (state is StaffAllowedPermissionsAndModulesFetchSuccess) {
                  return RefreshIndicator(
                    color: maroonPrimary,
                    onRefresh: () async {
                      context
                          .read<StaffAllowedPermissionsAndModulesCubit>()
                          .getPermissionAndAllowedModules();
                    },
                    child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsetsDirectional.only(
                            top: Utils.appContentTopScrollPadding(
                                    context: context) +
                                20,
                            end: appContentHorizontalPadding,
                            start: appContentHorizontalPadding,
                            bottom: 100),
                        child: context.read<AuthCubit>().isTeacher()
                            ? const TeacherAcademicsContainer()
                            : const StaffAcademicsContainer()),
                  );
                } else if (state
                    is StaffAllowedPermissionsAndModulesFetchFailure) {
                  return Center(
                    child: CustomErrorWidget(
                      message: state.errorMessage,
                      onRetry: () {
                        context
                            .read<StaffAllowedPermissionsAndModulesCubit>()
                            .getPermissionAndAllowedModules();
                      },
                      primaryColor: maroonPrimary,
                    ),
                  );
                } else {
                  return Center(
                    child: CustomCircularProgressIndicator(
                      indicatorColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }
              },
            ),
          ),
          // New Stylish Appbar that matches homeContainerAppbar
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 140 + MediaQuery.of(context).padding.top,
              width: MediaQuery.of(context).size.width,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  // Solid foundation to ensure content scroll under the curves is hidden
                  Positioned.fill(
                    child: Container(
                      color: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.grey[50],
                    ),
                  ),
                   Positioned.fill(
                    child: CustomPaint(
                      painter: DramaticCurvedGradientPainter(
                        colors: [
                          maroonDark,
                          maroonPrimary,
                          isDark ? const Color(0xFF4A0E17) : const Color(0xFF9A1E3C),
                          isDark ? Theme.of(context).scaffoldBackgroundColor : maroonLight,
                        ],
                        stops: const [0.0, 0.3, 0.6, 1.0],
                      ),
                    ),
                  ),

                  // Decorative design elements with enhanced animations
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _glowAnimationController,
                        _pulseAnimationController,
                        _rotationAnimationController,
                      ]),
                      builder: (context, _) {
                        return CustomPaint(
                          painter: AnimatedAppBarDecorationPainter(
                            color: Colors.white.withValues(
                                alpha: 0.07 + (_glowAnimation.value * 0.05)),
                            glowValue: _glowAnimation.value,
                            pulseValue: _pulseAnimation.value,
                            rotationValue: _rotationAnimation.value,
                          ),
                        );
                      },
                    ),
                  ),

                  // Refined animated glowing effect - more subtle and elegant
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _glowAnimationController,
                      _pulseAnimationController,
                    ]),
                    builder: (context, _) {
                      return Stack(
                        children: [
                          // Primary glow circle - softer movement
                          Positioned(
                            top: MediaQuery.of(context).padding.top -
                                100 +
                                (math.sin(_glowAnimation.value * 2 * math.pi) *
                                    5),
                            right: -60 +
                                (math.cos(_glowAnimation.value * 2 * math.pi) *
                                    3),
                            child: Transform.scale(
                              scale: 0.95 + (_pulseAnimation.value * 0.1),
                              child: Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white.withValues(
                                          alpha: 0.15 +
                                              (_glowAnimation.value * 0.05)),
                                      Colors.white.withValues(
                                          alpha: 0.08 +
                                              (_glowAnimation.value * 0.03)),
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                    stops: const [0.0, 0.6, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Secondary glow circle - gentle floating
                          Positioned(
                            top: MediaQuery.of(context).padding.top -
                                70 +
                                (math.sin(_glowAnimation.value * 2 * math.pi +
                                        1.5) *
                                    4),
                            left: -30 +
                                (math.cos(_glowAnimation.value * 2 * math.pi +
                                        1.5) *
                                    2),
                            child: Transform.scale(
                              scale: 1.0 +
                                  (math.sin(_pulseAnimation.value * math.pi) *
                                      0.05),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white.withValues(
                                          alpha: 0.12 +
                                              (_glowAnimation.value * 0.04)),
                                      Colors.white.withValues(
                                          alpha: 0.06 +
                                              (_glowAnimation.value * 0.02)),
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                    stops: const [0.0, 0.7, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Tertiary glow circle - micro floating animation
                          Positioned(
                            top: MediaQuery.of(context).padding.top +
                                25 +
                                (math.sin(_glowAnimation.value * 2 * math.pi +
                                        3) *
                                    3),
                            right: -15 +
                                (math.cos(_glowAnimation.value * 2 * math.pi +
                                        3) *
                                    2),
                            child: Transform.rotate(
                              angle: _rotationAnimation.value * 0.3,
                              child: Transform.scale(
                                scale: 0.9 +
                                    (math.sin(_pulseAnimation.value * math.pi +
                                            2) *
                                        0.08),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.white.withValues(
                                            alpha: 0.1 +
                                                (_glowAnimation.value * 0.03)),
                                        Colors.white.withValues(
                                            alpha: 0.05 +
                                                (_glowAnimation.value * 0.02)),
                                        Colors.white.withValues(alpha: 0.0),
                                      ],
                                      stops: const [0.0, 0.8, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // Animated main content container with elevation and smooth entrance
                  Positioned(
                    bottom: 30,
                    left: 16,
                    right: 16,
                    child: Container(
                      height: 95,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: maroonPrimary.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: maroonLight.withValues(alpha: 0.15),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Profile image with tap to zoom
                          GestureDetector(
                            onTap: () {
                              ProfileImagePreview.show(
                                  context, profileImage, 'academics_avatar');
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [maroonPrimary, maroonDark],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: maroonPrimary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(2),
                              child: Hero(
                                tag: 'academics_avatar',
                                child: CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  radius: 25,
                                  backgroundImage: profileImage.isNotEmpty
                                      ? CachedNetworkImageProvider(
                                          profileImage,
                                        )
                                      : null,
                                  child: profileImage.isEmpty
                                      ? Icon(
                                          Icons.person,
                                          color: maroonPrimary,
                                          size: 30,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15.0),
                          // Title text without animations
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Akademik",
                                  style: GoogleFonts.poppins(
                                    height: 1.1,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? const Color(0xFFFF3D60)
                                        : maroonPrimary,
                                  ),
                                ),
                                Text(
                                  "Kelola konten akademik",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Back button without animations
                          Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: () {
                                // Navigate back or perform any action when pressed
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [maroonPrimary, maroonDark],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          maroonPrimary.withValues(alpha: 0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.grid_view_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      );
    });
  }
}

// Custom painter for dramatically curved gradient background with a double-wave effect
class DramaticCurvedGradientPainter extends CustomPainter {
  final List<Color> colors;
  final List<double> stops;

  DramaticCurvedGradientPainter({
    required this.colors,
    required this.stops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Create gradient
    paint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
      stops: stops,
    ).createShader(rect);

    // Create dramatic double-curved path with deep valleys
    final path = Path();
    path.lineTo(
        0, size.height - 60); // Start from bottom-left with larger offset

    // First dramatic curve
    final firstControlPoint = Offset(
        size.width * 0.25, size.height + 30); // Control point below the bottom
    final firstEndPoint = Offset(size.width * 0.5, size.height - 40);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    // Second dramatic curve
    final secondControlPoint = Offset(size.width * 0.75,
        size.height - 110); // Higher control point for deeper curve
    final secondEndPoint = Offset(size.width, size.height - 50);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    // Complete the path
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);

    // Add more dramatic highlights for enhanced depth
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final highlightPath = Path();
    highlightPath.moveTo(0, size.height - 58);
    highlightPath.quadraticBezierTo(firstControlPoint.dx,
        firstControlPoint.dy - 4, firstEndPoint.dx, firstEndPoint.dy - 3);
    highlightPath.quadraticBezierTo(secondControlPoint.dx,
        secondControlPoint.dy - 3, secondEndPoint.dx, secondEndPoint.dy - 3);

    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Enhanced wave pattern for more visual impact
// Enhanced custom painter for animated decorative elements in the app bar
class AnimatedAppBarDecorationPainter extends CustomPainter {
  final Color color;
  final double glowValue;
  final double pulseValue;
  final double rotationValue;

  AnimatedAppBarDecorationPainter({
    required this.color,
    required this.glowValue,
    required this.pulseValue,
    required this.rotationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: color.a * (0.3 + glowValue * 0.3))
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1 + glowValue * 2);

    // Refined animated decorative circles - more subtle movement
    final circles = [
      {
        'center': Offset(
            size.width * (0.88 + math.sin(glowValue * 2 * math.pi) * 0.01),
            size.height * (0.22 + math.cos(glowValue * 2 * math.pi) * 0.008)),
        'radius': 25 * (0.9 + math.sin(pulseValue * math.pi) * 0.15),
        'hasGlow': true,
      },
      {
        'center': Offset(
            size.width *
                (0.12 + math.cos(glowValue * 2 * math.pi + 1.5) * 0.008),
            size.height *
                (0.78 + math.sin(glowValue * 2 * math.pi + 1.5) * 0.01)),
        'radius': 18 * (0.95 + math.sin(pulseValue * math.pi + 0.5) * 0.1),
        'hasGlow': false,
      },
      {
        'center': Offset(
            size.width * (0.52 + math.sin(glowValue * 2 * math.pi + 3) * 0.012),
            size.height *
                (0.18 + math.cos(glowValue * 2 * math.pi + 3) * 0.006)),
        'radius': 12 * (1.0 + math.sin(pulseValue * math.pi + 1) * 0.2),
        'hasGlow': true,
      },
      {
        'center': Offset(
            size.width *
                (0.72 + math.cos(glowValue * 2 * math.pi + 4.5) * 0.008),
            size.height *
                (0.68 + math.sin(glowValue * 2 * math.pi + 4.5) * 0.01)),
        'radius': 8 * (0.8 + math.sin(pulseValue * math.pi + 1.5) * 0.3),
        'hasGlow': false,
      },
      {
        'center': Offset(
            size.width * (0.25 + math.sin(glowValue * 2 * math.pi + 6) * 0.01),
            size.height *
                (0.42 + math.cos(glowValue * 2 * math.pi + 6) * 0.008)),
        'radius': 6 * (1.0 + math.sin(pulseValue * math.pi + 2) * 0.15),
        'hasGlow': true,
      },
    ];

    // Draw refined animated circles
    for (var circle in circles) {
      final center = circle['center'] as Offset;
      final radius = circle['radius'] as double;
      final hasGlow = circle['hasGlow'] as bool;

      if (hasGlow) {
        // Draw subtle glow effect
        canvas.drawCircle(center, radius * 1.3, glowPaint);
      }
      // Draw main circle
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedAppBarDecorationPainter oldDelegate) {
    return oldDelegate.glowValue != glowValue ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.rotationValue != rotationValue;
  }
}
