import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';

import 'package:eschool_saas_staff/cubits/settings/settingCubit.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customCircularProgressIndicator.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  static Widget getRouteInstance() {
    return BlocProvider(
      create: (context) => SettingsCubit(),
      child: const AboutUsScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen>
    with TickerProviderStateMixin {
  String? cachedData;
  late AnimationController _controller;
  late AnimationController _fabAnimationController;
  final ScrollController _scrollController = ScrollController();

  // Warna tema utama aplikasi (sama dengan AppBar)
  static const Color _themePrimary = Color(0xFF800020);
  static const Color _themeLight = Color(0xFFAA6976);
  static const Color _themeBackground = Color(0xFFF5E6E8);

  @override
  void initState() {
    super.initState();
    context.read<SettingsCubit>().getSettings("about_us");
    _loadCachedData();

    _scrollController.addListener(_scrollListener);
    _fabAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _controller.forward();
  }

  void _scrollListener() {
    if (_scrollController.offset > 50) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadCachedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      cachedData = prefs.getString("about_us");
    });
  }

  String generateRandomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  String parseCustomHtml(String input) {
    // Strip standard HTML tags first
    input = input
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    String placeholderBold = generateRandomString(10);
    String placeholderItalic = generateRandomString(10);

    while (placeholderItalic == placeholderBold) {
      placeholderItalic = generateRandomString(10);
      placeholderBold = generateRandomString(10);
    }

    input = input
        .replaceAll('\\*', placeholderBold)
        .replaceAll('\\/', placeholderItalic);

    bool isBold = false;
    bool isItalic = false;
    String output = '';

    for (int i = 0; i < input.length; i++) {
      if (input[i] == '*') {
        isBold = !isBold;
        output += isBold ? '<b>' : '</b>';
      } else if (input[i] == '/') {
        isItalic = !isItalic;
        output += isItalic ? '<i>' : '</i>';
      } else {
        output += input[i];
      }
    }

    output = output
        .replaceAll(placeholderBold, '*')
        .replaceAll(placeholderItalic, '/')
        .replaceAll("\n", "<br/>");

    return output;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _themePrimary,
              secondary: _themeLight,
              surface: _themeBackground,
            ),
      ),
      child: Scaffold(
        backgroundColor: _themeBackground,
        appBar: CustomModernAppBar(
          title: Utils.getTranslatedLabel(aboutUsKey),
          icon: Icons.info_outline,
          fabAnimationController: _fabAnimationController,
          primaryColor: _themePrimary,
          lightColor: _themeLight,
          onBackPressed: () => Navigator.of(context).pop(),
        ),
        body: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            return SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  // Hero Section - Simple & Clean
                  FadeInDown(
                    duration: const Duration(milliseconds: 800),
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _themePrimary,    // 0xFF800020
                            _themeLight,      // 0xFFAA6976
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: _themePrimary.withValues(alpha: 0.3),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // School Icon
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              size: 55,
                              color: _themePrimary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Title
                          Text(
                            'eSchool SaaS',
                            style: GoogleFonts.poppins(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Tagline
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Transformasi Pendidikan Melalui Teknologi',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ═══════════════════════════════════════════
                  // FEATURE CARDS
                  // ═══════════════════════════════════════════
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildFeatureCard(
                          icon: Icons.computer,
                          title: 'Pembelajaran Modern',
                          description: 'Platform pembelajaran digital yang modern',
                          gradient: [
                            _themeBackground,
                            _themeLight.withValues(alpha: 0.15),
                          ],
                        ),
                        _buildFeatureCard(
                          icon: Icons.analytics,
                          title: 'Analisis Cerdas',
                          description: 'Pemantauan kinerja dan wawasan secara langsung',
                          gradient: [
                            _themeBackground,
                            const Color(0xFFF4D0D9).withValues(alpha: 0.3),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ═══════════════════════════════════════════
                  // CONTENT CARD
                  // ═══════════════════════════════════════════
                  if (state is SettingsSuccess)
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: _themePrimary.withValues(alpha: 0.08),
                              blurRadius: 25,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: HtmlWidget(
                            parseCustomHtml(state.data),
                            textStyle: GoogleFonts.poppins(
                              fontSize: 15,
                              color: _themePrimary.withValues(alpha: 0.75),
                              height: 1.6,
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (state is SettingsFailure)
                    Center(
                      child: CustomErrorWidget(
                        message: ErrorMessageUtils.getReadableErrorMessage(
                            state.errorMessage),
                        onRetry: () {
                          context
                              .read<SettingsCubit>()
                              .getSettings("about_us");
                        },
                        primaryColor: _themePrimary,
                      ),
                    )
                  else
                    const Center(
                      child: CustomCircularProgressIndicator(),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required List<Color> gradient,
  }) {
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _themePrimary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _themePrimary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: 28, color: _themePrimary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _themePrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: _themePrimary.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Clipper that creates a smooth wave curve at the bottom
/// while keeping the top edge perfectly straight/horizontal
class _WaveCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Start at top-left (straight horizontal top)
    path.lineTo(0, 0);

    // Go straight down on the left side
    path.lineTo(0, size.height - 60);

    // Create smooth wave curve at bottom
    path.quadraticBezierTo(
      size.width * 0.25, // control point x
      size.height,       // control point y (dips down)
      size.width * 0.5,  // end point x (middle)
      size.height - 40,  // end point y
    );
    path.quadraticBezierTo(
      size.width * 0.75, // control point x
      size.height - 80,  // control point y (lifts up)
      size.width,        // end point x (right edge)
      size.height - 50,  // end point y
    );

    // Go straight up on the right side
    path.lineTo(size.width, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
