import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipe notifikasi untuk styling yang berbeda
enum PushType {
  info,
  success,
  warning,
  error,
}

/// Menampilkan banner push notification dengan desain clean dan elegan
/// Menggunakan Get.snackbar dengan custom widget untuk tampilan yang refined
void showPushBanner({
  required String title,
  required String body,
  PushType type = PushType.info,
  Duration duration = const Duration(seconds: 5),
  VoidCallback? onTap,
}) {
  // Haptic feedback untuk interaksi yang lebih responsive
  HapticFeedback.lightImpact();

  final config = _getNotificationConfig(type);

  Get.rawSnackbar(
    messageText: _CleanNotificationCard(
      title: title,
      body: body,
      config: config,
      onTap: onTap,
    ),
    snackPosition: SnackPosition.TOP,
    backgroundColor: Colors.transparent,
    borderRadius: 0,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    padding: EdgeInsets.zero,
    duration: duration,
    animationDuration: const Duration(milliseconds: 400),
    isDismissible: true,
  );
}

/// Widget custom untuk notification card dengan desain clean dan elegan
class _CleanNotificationCard extends StatefulWidget {
  final String title;
  final String body;
  final _NotificationConfig config;
  final VoidCallback? onTap;

  const _CleanNotificationCard({
    required this.title,
    required this.body,
    required this.config,
    this.onTap,
  });

  @override
  State<_CleanNotificationCard> createState() => _CleanNotificationCardState();
}

class _CleanNotificationCardState extends State<_CleanNotificationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildNotificationCard(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap?.call();
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.config.backgroundColor.withValues(alpha: 0.98),
                Colors.white.withValues(alpha: 0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Colors.white,
              width: 1.2,
            ),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIconSection(),
              const SizedBox(width: 14),
              Expanded(child: _buildContentSection()),
              if (widget.onTap != null) ...[
                const SizedBox(width: 10),
                _buildActionSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconSection() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: widget.config.iconBackgroundColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: widget.config.iconBackgroundColor.withValues(alpha: 0.09),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          widget.config.icon,
          color: widget.config.iconBackgroundColor,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: GoogleFonts.poppins(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: widget.config.titleColor,
              height: 1.13,
              letterSpacing: -0.18,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Text(
            widget.body,
            style: GoogleFonts.poppins(
              fontSize: 12.7,
              fontWeight: FontWeight.w400,
              color: widget.config.bodyColor,
              height: 1.45,
              letterSpacing: -0.04,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: widget.config.actionBackgroundColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: widget.config.actionBackgroundColor.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Lihat',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: widget.config.actionTextColor,
              letterSpacing: -0.04,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: widget.config.actionTextColor,
            size: 11,
          ),
        ],
      ),
    );
  }
}

/// Konfigurasi clean untuk notification dengan warna solid yang lembut
class _NotificationConfig {
  final Color backgroundColor;
  final Color iconBackgroundColor;
  final Color iconColor;
  final Color titleColor;
  final Color bodyColor;
  final Color actionBackgroundColor;
  final Color actionTextColor;
  final IconData icon;

  const _NotificationConfig({
    required this.backgroundColor,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.titleColor,
    required this.bodyColor,
    required this.actionBackgroundColor,
    required this.actionTextColor,
    required this.icon,
  });
}

/// Mendapatkan konfigurasi clean berdasarkan tipe notifikasi
_NotificationConfig _getNotificationConfig(PushType type) {
  switch (type) {
    case PushType.info:
      return const _NotificationConfig(
        backgroundColor: Color(0xFFF0F7FF), // Light blue background
        iconBackgroundColor: Color(0xFF3B82F6), // Blue icon background
        iconColor: Colors.white,
        titleColor: Color(0xFF1E40AF), // Dark blue title
        bodyColor: Color(0xFF475569), // Slate gray body
        actionBackgroundColor: Color(0xFFE0F2FE), // Light blue action bg
        actionTextColor: Color(0xFF0C4A6E), // Dark blue action text
        icon: Icons.info_outline_rounded,
      );
    case PushType.success:
      return const _NotificationConfig(
        backgroundColor: Color(0xFFF0FDF4), // Light green background
        iconBackgroundColor: Color(0xFF10B981), // Green icon background
        iconColor: Colors.white,
        titleColor: Color(0xFF047857), // Dark green title
        bodyColor: Color(0xFF475569), // Slate gray body
        actionBackgroundColor: Color(0xFFDCFCE7), // Light green action bg
        actionTextColor: Color(0xFF064E3B), // Dark green action text
        icon: Icons.check_circle_outline_rounded,
      );
    case PushType.warning:
      return const _NotificationConfig(
        backgroundColor: Color(0xFFFEFBF0), // Light amber background
        iconBackgroundColor: Color(0xFFF59E0B), // Amber icon background
        iconColor: Colors.white,
        titleColor: Color(0xFF92400E), // Dark amber title
        bodyColor: Color(0xFF475569), // Slate gray body
        actionBackgroundColor: Color(0xFFFEF3C7), // Light amber action bg
        actionTextColor: Color(0xFF78350F), // Dark amber action text
        icon: Icons.warning_amber_outlined,
      );
    case PushType.error:
      return const _NotificationConfig(
        backgroundColor: Color(0xFFFEF2F2), // Light red background
        iconBackgroundColor: Color(0xFFEF4444), // Red icon background
        iconColor: Colors.white,
        titleColor: Color(0xFFDC2626), // Dark red title
        bodyColor: Color(0xFF475569), // Slate gray body
        actionBackgroundColor: Color(0xFFFEE2E2), // Light red action bg
        actionTextColor: Color(0xFF991B1B), // Dark red action text
        icon: Icons.error_outline_rounded,
      );
  }
}
