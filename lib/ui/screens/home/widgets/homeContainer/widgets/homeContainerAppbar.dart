import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/cubits/authentication/authCubit.dart';
import 'package:eschool_saas_staff/cubits/userDetails/staffAllowedPermissionsAndModulesCubit.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eschool_saas_staff/ui/widgets/system/profilePreview.dart';
import 'dart:math' as math;
import 'dart:ui';

class HomeContainerAppbar extends StatefulWidget {
  final String profileImage;
  const HomeContainerAppbar({super.key, required this.profileImage});

  @override
  State<HomeContainerAppbar> createState() => _HomeContainerAppbarState();
}

class _HomeContainerAppbarState extends State<HomeContainerAppbar>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _glowAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _rotationAnimationController;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _glowAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowAnimationController,
        curve: Curves.easeInOutSine,
      ),
    );

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );

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

    _glowAnimationController.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _pulseAnimationController.repeat(reverse: true);
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _rotationAnimationController.repeat();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_glowAnimationController.isAnimating) _glowAnimationController.repeat(reverse: true);
      if (!_pulseAnimationController.isAnimating) _pulseAnimationController.repeat(reverse: true);
      if (!_rotationAnimationController.isAnimating) _rotationAnimationController.repeat();
    } else {
      _glowAnimationController.stop();
      _pulseAnimationController.stop();
      _rotationAnimationController.stop();
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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color maroonPrimary = isDark ? const Color(0xFF8B1F41) : const Color(0xFF800020);
    final Color maroonLight = isDark ? const Color(0xFFA84B5C) : const Color(0xFFAA6976);
    final Color maroonDark = isDark ? const Color(0xFF4A0E17) : const Color.fromARGB(255, 124, 9, 31);

    return BlocBuilder<AuthCubit, AuthState>(builder: (context, state) {
      final currentProfileImage = context.read<AuthCubit>().getUserDetails().image ?? "";
      return SizedBox(
        height: 140 + MediaQuery.of(context).padding.top,
        width: MediaQuery.of(context).size.width,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            // Solid foundation to ensure only cards are transparent to decoration, not the scaffold
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
                  stops: [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),
            
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _glowAnimationController,
                  _pulseAnimationController,
                  _rotationAnimationController,
                ]),
                builder: (context, _) => CustomPaint(
                  painter: AnimatedAppBarDecorationPainter(
                    color: Colors.white.withValues(alpha: 0.07 + (_glowAnimation.value * 0.05)),
                    glowValue: _glowAnimation.value,
                    pulseValue: _pulseAnimation.value,
                    rotationValue: _rotationAnimation.value,
                  ),
                ),
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
                    // Primary glow circle
                    Positioned(
                      top: MediaQuery.of(context).padding.top -
                          100 +
                          (math.sin(_glowAnimation.value * 2 * math.pi) * 5),
                      right: -60 + (math.cos(_glowAnimation.value * 2 * math.pi) * 3),
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
                                    alpha: 0.15 + (_glowAnimation.value * 0.05)),
                                Colors.white.withValues(
                                    alpha: 0.08 + (_glowAnimation.value * 0.03)),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.6, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Secondary glow circle
                    Positioned(
                      top: MediaQuery.of(context).padding.top -
                          70 +
                          (math.sin(_glowAnimation.value * 2 * math.pi + 1.5) * 4),
                      left: -30 + (math.cos(_glowAnimation.value * 2 * math.pi + 1.5) * 2),
                      child: Transform.scale(
                        scale: 1.0 + (math.sin(_pulseAnimation.value * math.pi) * 0.05),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withValues(
                                    alpha: 0.12 + (_glowAnimation.value * 0.04)),
                                Colors.white.withValues(
                                    alpha: 0.06 + (_glowAnimation.value * 0.02)),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.7, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Tertiary glow circle
                    Positioned(
                      top: MediaQuery.of(context).padding.top +
                          25 +
                          (math.sin(_glowAnimation.value * 2 * math.pi + 3) * 3),
                      right: -15 + (math.cos(_glowAnimation.value * 2 * math.pi + 3) * 2),
                      child: Transform.rotate(
                        angle: _rotationAnimation.value * 0.3,
                        child: Transform.scale(
                          scale: 0.9 + (math.sin(_pulseAnimation.value * math.pi + 2) * 0.08),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withValues(
                                      alpha: 0.1 + (_glowAnimation.value * 0.03)),
                                  Colors.white.withValues(
                                      alpha: 0.05 + (_glowAnimation.value * 0.02)),
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

            Positioned(
              bottom: 30,
              left: 16,
              right: 16,
              child: Container(
                height: 95,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Theme.of(context).colorScheme.surface,
                  border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5) : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: isDark ? 12 : 0, sigmaY: isDark ? 12 : 0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => ProfileImagePreview.show(context, currentProfileImage, 'home_avatar'),
                            child: Hero(
                              tag: 'home_avatar',
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: maroonPrimary.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: currentProfileImage.isEmpty
                                      ? Icon(Icons.person, color: maroonPrimary, size: 30)
                                      : CachedNetworkImage(
                                          imageUrl: currentProfileImage,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                          errorWidget: (context, url, error) => Icon(Icons.person, color: maroonPrimary, size: 30),
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                             child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Hai, selamat datang kembali!",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  context.read<AuthCubit>().getUserDetails().fullName ?? "",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: isDark ? const Color(0xFFE53935) : maroonPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18.0,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          BlocBuilder<StaffAllowedPermissionsAndModulesCubit, StaffAllowedPermissionsAndModulesState>(
                            builder: (context, state) {
                              if (state is StaffAllowedPermissionsAndModulesFetchSuccess) {
                                return _buildHeaderButton(
                                  icon: Icons.notifications_active_rounded,
                                  onTap: () => Get.toNamed(Routes.notificationsScreen),
                                  color: const Color(0xFF800020),
                                );
                              }
                              if (state is StaffAllowedPermissionsAndModulesFetchFailure) {
                                return _buildHeaderButton(
                                  icon: Icons.login_outlined,
                                  onTap: () {
                                    context.read<AuthCubit>().signOut();
                                    Get.offNamed(Routes.loginScreen);
                                  },
                                  color: const Color(0xFF800020),
                                );
                              }
                              return const SizedBox(width: 48, height: 48);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  String _getGreeting() {
    return 'Selamat Datang ✨';
  }

  Widget _buildHeaderButton({required IconData icon, required VoidCallback onTap, required Color color}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withValues(alpha: 0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class DramaticCurvedGradientPainter extends CustomPainter {
  final List<Color> colors;
  final List<double> stops;
  DramaticCurvedGradientPainter({required this.colors, required this.stops});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
        stops: stops,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.lineTo(0, size.height - 60);

    // Primary dramatic curve set
    final firstControlPoint = Offset(size.width * 0.25, size.height + 30);
    final firstEndPoint = Offset(size.width * 0.5, size.height - 40);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);

    final secondControlPoint = Offset(size.width * 0.75, size.height - 110);
    final secondEndPoint = Offset(size.width, size.height - 50);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);

    // Dynamic highlights
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final highlightPath = Path();
    highlightPath.moveTo(0, size.height - 58);
    highlightPath.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy - 4, firstEndPoint.dx, firstEndPoint.dy - 3);
    highlightPath.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy - 3, secondEndPoint.dx, secondEndPoint.dy - 3);

    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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

    // Refined animated decorative circles
    final circles = [
      {
        'center': Offset(size.width * (0.88 + math.sin(glowValue * 2 * math.pi) * 0.01),
            size.height * (0.22 + math.cos(glowValue * 2 * math.pi) * 0.008)),
        'radius': 25 * (0.9 + math.sin(pulseValue * math.pi) * 0.15),
        'hasGlow': true,
      },
      {
        'center': Offset(size.width * (0.12 + math.cos(glowValue * 2 * math.pi + 1.5) * 0.008),
            size.height * (0.78 + math.sin(glowValue * 2 * math.pi + 1.5) * 0.01)),
        'radius': 18 * (0.95 + math.sin(pulseValue * math.pi + 0.5) * 0.1),
        'hasGlow': false,
      },
      {
        'center': Offset(size.width * (0.52 + math.sin(glowValue * 2 * math.pi + 3) * 0.012),
            size.height * (0.18 + math.cos(glowValue * 2 * math.pi + 3) * 0.006)),
        'radius': 12 * (1.0 + math.sin(pulseValue * math.pi + 1) * 0.2),
        'hasGlow': true,
      },
    ];

    for (var circle in circles) {
      final center = circle['center'] as Offset;
      final radius = circle['radius'] as double;
      if (circle['hasGlow'] as bool) {
        canvas.drawCircle(center, radius * 1.3, glowPaint);
      }
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedAppBarDecorationPainter oldDelegate) => true;
}
