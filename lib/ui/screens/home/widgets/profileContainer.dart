import 'dart:math';
import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/cubits/settings/appLocalizationCubit.dart';
import 'package:eschool_saas_staff/cubits/authentication/authCubit.dart';
import 'package:eschool_saas_staff/data/repositories/system/settingsRepository.dart';
import 'package:eschool_saas_staff/ui/screens/leaves/leavesScreen.dart';
import 'package:eschool_saas_staff/ui/screens/login/widgets/schoolListScreen.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/system/filterSelectionTile.dart';
import 'package:eschool_saas_staff/utils/system/appLanguages.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eschool_saas_staff/ui/widgets/system/profilePreview.dart';
import 'package:flutter_bloc/flutter_bloc.dart' hide Transition;
import 'package:get/route_manager.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool_saas_staff/cubits/settings/themeCubit.dart';
import 'package:eschool_saas_staff/cubits/userDetails/staffAllowedPermissionsAndModulesCubit.dart';


class AppColorPalette {
  static const Color primaryMaroon = Color(0xFF8B1F41);
  static const Color secondaryMaroon = Color(0xFFA84B5C);
  static const Color lightMaroon = Color(0xFFE7C8CD);
  static const Color accentPink = Color(0xFFF4D0D9);
  static const Color warmBeige = Color(0xFFF5E6E8);
}

class ProfileContainer extends StatefulWidget {
  const ProfileContainer({super.key});

  @override
  State<ProfileContainer> createState() => _ProfileContainerState();
}

class _ProfileContainerState extends State<ProfileContainer>
    with
        TickerProviderStateMixin,
        WidgetsBindingObserver,
        AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  int _hoveredMenuIndex = -1;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Animation controllers from homeContainerAppbar
  late AnimationController _glowAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _rotationAnimationController;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;


  // Responsive maroon color palette - Brightened for vibrancy
  Color get maroonPrimary => Theme.of(context).brightness == Brightness.dark 
      ? const Color(0xFF8B1F41) : const Color(0xFF800020);
  Color get maroonLight => Theme.of(context).brightness == Brightness.dark 
      ? const Color(0xFFA84B5C) : const Color(0xFFAA6976);
  Color get maroonDark => Theme.of(context).brightness == Brightness.dark 
      ? const Color(0xFF4A0E17) : const Color.fromARGB(255, 124, 9, 31);
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();

    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _animation =
        Tween<double>(begin: 0, end: 2 * pi).animate(_animationController);

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
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(
        parent: _rotationAnimationController,
        curve: Curves.linear,
      ),
    );

    // Start animations with delays for more natural feel
    _glowAnimationController.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _pulseAnimationController.repeat(reverse: true);
      }
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _rotationAnimationController.repeat();
      }
    });

    // Set system UI overlay style for status bar
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
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
    _animationController.dispose();
    _glowAnimationController.dispose();
    _pulseAnimationController.dispose();
    _rotationAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authstate) {
        return Stack(
          children: [
            // Background color
            Positioned.fill(
              child: Container(
                color: isDark ? const Color(0xFF121212) : Colors.grey[50],
              ),
            ),

            AnimationLimiter(
              child: RefreshIndicator(
                color: maroonPrimary,
                onRefresh: () async {
                  context
                      .read<StaffAllowedPermissionsAndModulesCubit>()
                      .getPermissionAndAllowedModules();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsetsDirectional.only(
                    top: Utils.appContentTopScrollPadding(context: context) +
                        110,
                    end: 16, // Samakan dengan Akademik
                    start: 16, // Samakan dengan Akademik
                    bottom: 100,
                  ),
                  child: Column(
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 600),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 30.0,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: <Widget>[
                        const SizedBox(height: 8),

                        // // Welcome message
                        // _buildWelcomeSection(context),

                        // const SizedBox(height: 32),

                        _buildMenuSection(
                          context: context,
                          title: "Pengaturan Personal",
                          icon: Icons.person_outline,
                          iconColor:
                              const Color(0xFF8B0000).withValues(alpha: 0.9),
                          index: 0,
                          menus: [
                            _buildMenuItem(
                              context: context,
                              icon: Icons.edit,
                              title: "Edit Profil",
                              index: 0,
                              onTap: () =>
                                  Get.toNamed(Routes.editProfileScreen),
                            ),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.lock_outline,
                              title: "Ubah Kata Sandi",
                              index: 1,
                              onTap: () =>
                                  Get.toNamed(Routes.changePasswordScreen),
                            ),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.notifications_active_outlined,
                              title: "Pengaturan Notifikasi",
                              index: 11,
                              onTap: () =>
                                  _showNotificationSettingsBottomSheet(context),
                            ),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.palette_outlined,
                              title: "Tampilan Aplikasi",
                              index: 12,
                              onTap: () => _showThemeSelectionBottomSheet(context),
                            ),
                          ],
                        ),

                        _buildMenuSection(
                          context: context,
                          title: "Cuti",
                          icon: Icons.event_available,
                          iconColor:
                              const Color(0xFF8B0000).withValues(alpha: 0.9),
                          index: 1,
                          menus: [
                            _buildMenuItem(
                              context: context,
                              icon: Icons.add_circle_outline,
                              title: "Ajukan Cuti",
                              index: 2,
                              onTap: () => Get.toNamed(Routes.applyLeaveScreen),
                            ),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.history,
                              title: "Riwayat Cuti Saya",
                              index: 3,
                              onTap: () => Get.toNamed(Routes.leavesScreen,
                                  arguments: LeavesScreen.buildArguments(
                                      showMyLeaves: true)),
                            ),
                          ],
                        ),

                        _buildMenuSection(
                          context: context,
                          title: "Penggajian",
                          icon: Icons.account_balance_wallet,
                          iconColor:
                              const Color(0xFF8B0000).withValues(alpha: 0.9),
                          index: 2,
                          menus: [
                            _buildMenuItem(
                              context: context,
                              icon: Icons.receipt_long,
                              title: "Slip Gaji Saya",
                              index: 4,
                              onTap: () => Get.toNamed(Routes.myPayrollScreen),
                            ),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.monetization_on_outlined,
                              title: "Tunjangan & Potongan",
                              index: 5,
                              onTap: () => Get.toNamed(
                                  Routes.allowancesAndDeductionsScreen),
                            ),
                          ],
                        ),

                        _buildMenuSection(
                          context: context,
                          title: "Informasi",
                          icon: Icons.info_outline,
                          iconColor:
                              const Color(0xFF8B0000).withValues(alpha: 0.9),
                          index: 3,
                          menus: [
                            _buildMenuItem(
                              context: context,
                              icon: Icons.business,
                              title: "Tentang Kami",
                              index: 6,
                              onTap: () => Get.toNamed(Routes.aboutUsScreen),
                            ),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.contact_mail,
                              title: "Hubungi Kami",
                              index: 7,
                              onTap: () => Get.toNamed(Routes.contactUsScreen),
                            ),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.contact_support_rounded,
                              title: "Kontak & Laporan",
                              index: 71,
                              onTap: () =>
                                  Get.toNamed(Routes.contactListScreen),
                            ),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.privacy_tip_outlined,
                              title: "Kebijakan Privasi",
                              index: 8,
                              onTap: () =>
                                  Get.toNamed(Routes.privacyPolicyScreen),
                            ),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.gavel_outlined,
                              title: "Syarat & Ketentuan",
                              index: 9,
                              onTap: () =>
                                  Get.toNamed(Routes.termsAndConditionScreen),
                            ),
                          ],
                        ),

                        _buildMenuSection(
                          context: context,
                          title: "Sekolah",
                          icon: Icons.school_outlined,
                          iconColor:
                              const Color(0xFF8B0000).withValues(alpha: 0.9),
                          index: 4,
                          menus: [
                            _buildMenuItem(
                              context: context,
                              icon: Icons.swap_horiz,
                              title: "Pindah Sekolah",
                              index: 10,
                              onTap: () async {
                                // Show loading dialog
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) {
                                    return const Dialog(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Color(0xFF8B1F41),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );

                                try {
                                  final authCubit = context.read<AuthCubit>();
                                  final userDetails =
                                      authCubit.getUserDetails();

                                  final schoolsData =
                                      await authCubit.getSchoolsData();

                                  debugPrint(
                                      'DEBUG: schoolsData type: ${schoolsData.runtimeType}');
                                  debugPrint(
                                      'DEBUG: schoolsData length: ${schoolsData.length}');
                                  if (schoolsData.isNotEmpty) {
                                    debugPrint(
                                        'DEBUG: first school type: ${schoolsData.first.runtimeType}');
                                    debugPrint(
                                        'DEBUG: first school keys: ${schoolsData.first.keys}');
                                  }

                                  // Validate schools data
                                  if (schoolsData.isEmpty) {
                                    throw Exception(
                                        'Data sekolah tidak tersedia. Silakan coba lagi.');
                                  }

                                  final userData = {
                                    'data': {
                                      'first_name': userDetails.firstName,
                                      'last_name': userDetails.lastName,
                                      'email': userDetails.email,
                                      'mobile': userDetails.mobile,
                                      'image': userDetails.image,
                                      'id': userDetails.id,
                                      'schools': schoolsData,
                                    },
                                  };

                                  debugPrint(
                                      'DEBUG: userData created successfully');
                                  debugPrint(
                                      'DEBUG: userData[data][schools] type: ${userData['data']?['schools']?.runtimeType}');

                                  if (!context.mounted) return;

                                  // Close loading dialog
                                  Navigator.of(context).pop();

                                  // Navigate to school list
                                  Get.to(() =>
                                      SchoolListScreen(userData: userData));
                                } catch (e) {
                                  if (!context.mounted) return;

                                  // Close loading dialog
                                  Navigator.of(context).pop();

                                  // Show error message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Terjadi kesalahan: ${e.toString()}',
                                        style: GoogleFonts.poppins(),
                                      ),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 4),
                                      action: SnackBarAction(
                                        label: 'Tutup',
                                        textColor: Colors.white,
                                        onPressed: () {
                                          ScaffoldMessenger.of(context)
                                              .hideCurrentSnackBar();
                                        },
                                      ),
                                    ),
                                  );

                                  debugPrint('Error in Pindah Sekolah: $e');
                                }
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        _buildLogoutButton(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Enhanced Curved App Bar
            _buildDramaticCurvedAppBar(context: context),
          ],
        );
      },
    );
  }

  // Widget _buildWelcomeSection(BuildContext context) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //         colors: [
  //           Colors.white,
  //           AppColorPalette.warmBeige.withValues(alpha: 0.4),
  //         ],
  //       ),
  //       borderRadius: BorderRadius.circular(24),
  //       boxShadow: [
  //         BoxShadow(
  //           color: AppColorPalette.primaryMaroon.withValues(alpha: 0.05),
  //           blurRadius: 15,
  //           offset: const Offset(0, 8),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.all(10),
  //               decoration: BoxDecoration(
  //                 color: AppColorPalette.primaryMaroon.withValues(alpha: 0.1),
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: Icon(
  //                 Icons.waving_hand_rounded,
  //                 color: Color(0xFF8B0000).withValues(alpha: 0.9),
  //                 size: 22,
  //               ),
  //             ),
  //             const SizedBox(width: 14),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     "Selamat datang,",
  //                     style: GoogleFonts.poppins(
  //                       fontSize: 15,
  //                       fontWeight: FontWeight.w500,
  //                       color:
  //                           Colors.black.withValues(alpha: 0.7), // Changed to black
  //                     ),
  //                   ),
  //                   const SizedBox(height: 4),
  //                   Text(
  //                     context.read<AuthCubit>().getUserDetails().firstName ??
  //                         "Pengguna",
  //                     style: GoogleFonts.poppins(
  //                       fontSize: 24,
  //                       fontWeight: FontWeight.bold,
  //                       color: Colors.black, // Changed to black
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildMenuSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required int index,
    required List<Widget> menus,
  }) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 400),
      child: SlideAnimation(
        verticalOffset: 40,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.only(
                bottom: 25,
                left: 15,
                right: 15), // Membuat kotak lebih ramping sesuai Akademik
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,

              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color:
                      iconColor.withValues(alpha: 0.12), // Sedikit lebih pekat
                  blurRadius: 20, // Samakan dengan akademik
                  offset: const Offset(0, 8), // Samakan dengan akademik
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              iconColor.withValues(alpha: 0.2),
                              iconColor.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: iconColor.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFFF3D60)
                              : iconColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        iconColor.withValues(alpha: 0.05),
                        iconColor.withValues(alpha: 0.2),
                        iconColor.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
                ...menus,
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int index,
    required VoidCallback onTap,
  }) {
    final isHovered = _hoveredMenuIndex == index;

    return StatefulBuilder(builder: (context, setState) {
      return MouseRegion(
        onEnter: (_) => this.setState(() => _hoveredMenuIndex = index),
        onExit: (_) => this.setState(() => _hoveredMenuIndex = -1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: isHovered
                ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColorPalette.primaryMaroon.withValues(alpha: 0.05),
                      AppColorPalette.secondaryMaroon.withValues(alpha: 0.1),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
            border: isHovered
                ? Border.all(
                    color: AppColorPalette.primaryMaroon.withValues(alpha: 0.1),
                    width: 1,
                  )
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              splashColor: AppColorPalette.primaryMaroon.withValues(alpha: 0.1),
              highlightColor: Colors.transparent,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isHovered
                            ? AppColorPalette.primaryMaroon
                                .withValues(alpha: 0.1)
                            : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.08)
                                : AppColorPalette.warmBeige.withValues(alpha: 0.5)),
                        shape: BoxShape.circle,
                        boxShadow: isHovered
                            ? [
                                BoxShadow(
                                  color: AppColorPalette.primaryMaroon
                                      .withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        icon,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFFFF3D60)
                            : (isHovered
                                ? AppColorPalette.primaryMaroon
                                : AppColorPalette.secondaryMaroon),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight:
                              isHovered ? FontWeight.w600 : FontWeight.w500,
                          color: isHovered
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurface
                                  .withValues(alpha: 0.8), // Changed to black
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      transform: Matrix4.translationValues(
                          isHovered ? 8.0 : 0.0, 0.0, 0.0),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFFFF3D60).withValues(alpha: 0.6)
                            : (isHovered
                                ? AppColorPalette.primaryMaroon
                                : AppColorPalette.secondaryMaroon
                                    .withValues(alpha: 0.5)),
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  void _showNotificationSettingsBottomSheet(BuildContext context) {
    final settingsRepository = SettingsRepository();
    bool vibrationEnabled = settingsRepository.getVibrationEnabled();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.notifications_active_outlined,
                        color: AppColorPalette.primaryMaroon,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Pengaturan Notifikasi',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColorPalette.primaryMaroon,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColorPalette.warmBeige.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColorPalette.primaryMaroon
                            .withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.vibration,
                          color: AppColorPalette.primaryMaroon,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Getar Saat Notifikasi',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColorPalette.primaryMaroon,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Aktifkan getaran saat menerima notifikasi baru',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: vibrationEnabled,
                          onChanged: (value) async {
                            setState(() {
                              vibrationEnabled = value;
                            });
                            await settingsRepository.setVibrationEnabled(value);
                          },
                          activeThumbColor: AppColorPalette.primaryMaroon,
                          activeTrackColor: AppColorPalette.secondaryMaroon
                              .withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorPalette.primaryMaroon,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Tutup',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const LogoutConfirmationDialog(),
          ).then((value) {
            final logoutUser = (value as bool?) ?? false;
            if (logoutUser && context.mounted) {
              context.read<AuthCubit>().signOut();
              Get.offNamed(Routes.loginScreen);
            }
          });
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppColorPalette.primaryMaroon,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              "Keluar",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(BuildContext context) {
    final bool isTeacher = context.read<AuthCubit>().isTeacher();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.15) : maroonPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.2) : maroonPrimary.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTeacher
                ? Icons.assignment_ind_rounded
                : Icons.work_outline_rounded,
            size: 11,
            color: isDark ? Colors.white : maroonPrimary,
          ),
          const SizedBox(width: 4),
          Text(
            isTeacher ? "Guru" : "Staff",
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : maroonPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDramaticCurvedAppBar({required BuildContext context}) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: 140 +
            MediaQuery.of(context)
                .padding
                .top, // Matching Academics and Beranda height
        width: MediaQuery.of(context).size.width,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            // Solid foundation to ensure content scroll under the curves is hidden
            Positioned.fill(
              child: Container(
                color: isDark ? const Color(0xFF121212) : Colors.grey[50],
              ),
            ),
            // Background with dramatically curved bottom
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomPaint(
                painter: DramaticCurvedGradientPainter(
                  colors: [
                    maroonDark,
                    maroonPrimary,
                    Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF4A0E17)
                        : const Color(0xFF9A1E3C),
                    Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF121212)
                        : maroonLight,
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
                          (sin(_glowAnimation.value * 2 * pi) * 5),
                      right: -60 + (cos(_glowAnimation.value * 2 * pi) * 3),
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
                                    alpha:
                                        0.15 + (_glowAnimation.value * 0.05)),
                                Colors.white.withValues(
                                    alpha:
                                        0.08 + (_glowAnimation.value * 0.03)),
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
                          (sin(_glowAnimation.value * 2 * pi + 1.5) * 4),
                      left:
                          -30 + (cos(_glowAnimation.value * 2 * pi + 1.5) * 2),
                      child: Transform.scale(
                        scale: 1.0 + (sin(_pulseAnimation.value * pi) * 0.05),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withValues(
                                    alpha:
                                        0.12 + (_glowAnimation.value * 0.04)),
                                Colors.white.withValues(
                                    alpha:
                                        0.06 + (_glowAnimation.value * 0.02)),
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
                          (sin(_glowAnimation.value * 2 * pi + 3) * 3),
                      right: -15 + (cos(_glowAnimation.value * 2 * pi + 3) * 2),
                      child: Transform.rotate(
                        angle: _rotationAnimation.value * 0.3,
                        child: Transform.scale(
                          scale: 0.9 +
                              (sin(_pulseAnimation.value * pi + 2) * 0.08),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withValues(
                                      alpha:
                                          0.08 + (_glowAnimation.value * 0.03)),
                                  Colors.white.withValues(
                                      alpha: 0.04 +
                                          (_glowAnimation.value * 0.015)),
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

            // Profile card
            Positioned(
              bottom: 10,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Get.toNamed(Routes.editProfileScreen),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                    border: Border.all(
                      color: maroonPrimary.withValues(alpha: 0.05),
                      width: 1,
                    ),
                  ),
                  child: _buildProfileInfo(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context) {
    return Row(
      children: [
        // Profile image with tap to zoom
        GestureDetector(
          onTap: () {
            final profileImage =
                context.read<AuthCubit>().getUserDetails().image ?? "";
            ProfileImagePreview.show(context, profileImage, 'profile_avatar');
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
              tag: 'profile_avatar',
              child: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.surface,
                radius: 28,
                backgroundImage:
                    (context.read<AuthCubit>().getUserDetails().image ?? "")
                            .isNotEmpty
                        ? CachedNetworkImageProvider(
                            context.read<AuthCubit>().getUserDetails().image ??
                                "",
                          )
                        : null,
                child: (context.read<AuthCubit>().getUserDetails().image ?? "")
                        .isEmpty
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
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
// User Name
              Builder(
                builder: (context) {
                  final userDetails =
                      context.read<AuthCubit>().getUserDetails();
                  final fullName = (userDetails.firstName ?? "").trim();
                  return Text(
                    fullName.isEmpty ? "Pengguna" : fullName,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFFF3D60)
                          : maroonPrimary,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
              const SizedBox(height: 4),

              // Role Badge
              _buildRoleBadge(context),
              const SizedBox(height: 5),

              // School Info
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: maroonPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.school_outlined,
                      size: 11,
                      color: isDark ? Colors.white.withValues(alpha: 0.9) : maroonPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.read<AuthCubit>().getUserDetails().school?.name ??
                          "Belum ada sekolah",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Email Info
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: maroonPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.email_outlined,
                      size: 11,
                      color: isDark ? Colors.white.withValues(alpha: 0.9) : maroonPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.read<AuthCubit>().getUserDetails().email ??
                          "Belum ada email",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  void _showThemeSelectionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Pilih Tampilan",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, state) {
                return Column(
                  children: [
                    _buildThemeTile(
                      context,
                      title: "Terang",
                      icon: Icons.light_mode_outlined,
                      mode: ThemeMode.light,
                      isSelected: state.themeMode == ThemeMode.light,
                    ),
                    _buildThemeTile(
                      context,
                      title: "Gelap",
                      icon: Icons.dark_mode_outlined,
                      mode: ThemeMode.dark,
                      isSelected: state.themeMode == ThemeMode.dark,
                    ),
                    _buildThemeTile(
                      context,
                      title: "Ikuti Sistem",
                      icon: Icons.settings_brightness_outlined,
                      mode: ThemeMode.system,
                      isSelected: state.themeMode == ThemeMode.system,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required ThemeMode mode,
    required bool isSelected,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? maroonPrimary.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? maroonPrimary : Colors.grey,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? maroonPrimary : null,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: maroonPrimary)
          : const Icon(Icons.circle_outlined, color: Colors.grey),
      onTap: () {
        context.read<ThemeCubit>().changeTheme(mode);
        Navigator.pop(context);
      },
    );
  }
}


class BackgroundPatternPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primaryColor;
  final Color accentColor;

  BackgroundPatternPainter({
    required this.animation,
    required this.primaryColor,
    required this.accentColor,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Draw dots pattern
    final dotPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    for (var x = 0; x < width; x += 30) {
      for (var y = 0; y < height; y += 30) {
        final offset = sin(x * 0.05 + y * 0.05 + animation.value) * 3;
        final radius = 1 + sin(x * 0.04 + y * 0.04 + animation.value) * 0.5;
        canvas.drawCircle(
          Offset(x + offset, y + offset),
          radius,
          dotPaint,
        );
      }
    }

    // Draw animated wave
    final wavePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var startY = 0; startY < height; startY += 200) {
      final path = Path();
      var startX = 0.0;
      path.moveTo(startX, startY.toDouble());

      for (var x = 0; x < width; x += 10) {
        final y = startY + sin(x * 0.02 + animation.value) * 20;
        path.lineTo(x.toDouble(), y);
      }

      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(BackgroundPatternPainter oldDelegate) => true;
}

class AppLanguagesBottomsheet extends StatelessWidget {
  const AppLanguagesBottomsheet({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomBottomsheet(
        titleLabelKey: changeLanguageKey,
        child: BlocBuilder<AppLocalizationCubit, AppLocalizationState>(
          builder: (context, state) {
            return Padding(
              padding: EdgeInsets.all(appContentHorizontalPadding),
              child: Column(
                children: appLanguages
                    .map((language) => FilterSelectionTile(
                        onTap: () {
                          context
                              .read<AppLocalizationCubit>()
                              .changeLanguage(language.languageCode);
                        },
                        isSelected: state.language.languageCode ==
                            language.languageCode,
                        title: language.languageName))
                    .toList(),
              ),
            );
          },
        ));
  }
}

class LogoutConfirmationDialog extends StatelessWidget {
  const LogoutConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: FadeInUp(
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.surface,
                AppColorPalette.warmBeige.withValues(alpha: 0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColorPalette.primaryMaroon.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Illustration
              Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(bottom: 20),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 60,
                  color: AppColorPalette.primaryMaroon,
                ),
              ),

              // Title
              Text(
                "Konfirmasi Keluar",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColorPalette.primaryMaroon,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Message
              Text(
                "Apakah Anda yakin ingin keluar dari aplikasi?",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Buttons
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: false),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Batal",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Confirm button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: AppColorPalette.primaryMaroon,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Keluar",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for dramatically curved gradient background
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
    path.lineTo(0, size.height - 60);

    // First dramatic curve
    final firstControlPoint = Offset(size.width * 0.25, size.height + 30);
    final firstEndPoint = Offset(size.width * 0.5, size.height - 40);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    // Second dramatic curve
    final secondControlPoint = Offset(size.width * 0.75, size.height - 110);
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
        'center': Offset(size.width * (0.88 + sin(glowValue * 2 * pi) * 0.01),
            size.height * (0.22 + cos(glowValue * 2 * pi) * 0.008)),
        'radius': 25 * (0.9 + sin(pulseValue * pi) * 0.15),
        'hasGlow': true,
      },
      {
        'center': Offset(
            size.width * (0.12 + cos(glowValue * 2 * pi + 1.5) * 0.008),
            size.height * (0.78 + sin(glowValue * 2 * pi + 1.5) * 0.01)),
        'radius': 18 * (0.95 + sin(pulseValue * pi + 0.5) * 0.1),
        'hasGlow': false,
      },
      {
        'center': Offset(
            size.width * (0.52 + sin(glowValue * 2 * pi + 3) * 0.012),
            size.height * (0.18 + cos(glowValue * 2 * pi + 3) * 0.006)),
        'radius': 12 * (1.0 + sin(pulseValue * pi + 1) * 0.2),
        'hasGlow': true,
      },
      {
        'center': Offset(
            size.width * (0.72 + cos(glowValue * 2 * pi + 4.5) * 0.008),
            size.height * (0.68 + sin(glowValue * 2 * pi + 4.5) * 0.01)),
        'radius': 8 * (0.8 + sin(pulseValue * pi + 1.5) * 0.3),
        'hasGlow': false,
      },
      {
        'center': Offset(
            size.width * (0.25 + sin(glowValue * 2 * pi + 6) * 0.01),
            size.height * (0.42 + cos(glowValue * 2 * pi + 6) * 0.008)),
        'radius': 6 * (1.0 + sin(pulseValue * pi + 2) * 0.15),
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
