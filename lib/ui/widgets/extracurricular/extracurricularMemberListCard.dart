import 'package:eschool_saas_staff/data/models/extracurricular/extracurricularMember.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ExtracurricularMemberListCard extends StatelessWidget {
  final ExtracurricularMember member;
  final VoidCallback onTap;

  // Define theme colors - Dynamic for dark/light mode
  static Color maroonPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFE53935)
          : const Color(0xffd22f3c);
  static Color maroonLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFEF5350)
          : const Color(0xffd22f3c);
  static const Color accentColor = Color(0xFFF5EBE0);
  final Color cardColor = Colors.white;
  static const Color textDarkColor = Color(0xFF2D2D2D);
  static const Color textMediumColor = Color(0xFF717171);
  static const Color borderColor = Color(0xFFE8E8E8);

  const ExtracurricularMemberListCard({super.key, 
    required this.member,
    required this.onTap,
  });

  // Helper method to build info columns
  Widget _buildInfoColumn({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color currentTextDarkColor = isDark ? Colors.white70 : textDarkColor;
    final Color currentTextMediumColor = isDark ? Colors.white54 : textMediumColor;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: currentTextDarkColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'Poppins',
              color: currentTextMediumColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (member.status) {
      case '0': // Pending
        return Colors.orange;
      case '1': // Approved
        return Colors.green;
      case '2': // Rejected
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (member.status) {
      case '0': // Pending
        return Icons.schedule_rounded;
      case '1': // Approved
        return Icons.check_circle_rounded;
      case '2': // Rejected
        return Icons.cancel_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  bool _isRTLEnabled(BuildContext context) {
    return Directionality.of(context) == TextDirection.rtl;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color currentCardColor = isDark ? Theme.of(context).cardColor : cardColor;
    final Color currentTextDarkColor = isDark ? Colors.white70 : textDarkColor;
    final Color currentTextMediumColor = isDark ? Colors.white54 : textMediumColor;
    final Color currentBorderColor = isDark ? Colors.white.withValues(alpha: 0.08) : borderColor;
    
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.maxFinite,
        decoration: BoxDecoration(
          color: currentCardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Status indicator strip
            Positioned(
              top: 0,
              left: 0,
              bottom: 0,
              child: Container(
                width: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                children: [
                  // Header section with profile image and name
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: currentBorderColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Hero(
                          tag: "member_profile_${member.id}",
                          child: Container(
                            width: 65,
                            height: 65,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [maroonLight(context), maroonPrimary(context)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: maroonPrimary(context).withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                (member.studentName?.isNotEmpty == true)
                                    ? member.studentName![0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: statusColor.withValues(alpha: 0.6),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            statusIcon,
                                            color: statusColor,
                                            size: 12,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              member.statusText,
                                              style: TextStyle(
                                                color: statusColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'Poppins',
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (member.extracurricularName != null &&
                                      member.extracurricularName != '-') ...[
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: maroonPrimary(context).withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color:
                                                maroonPrimary(context).withValues(alpha: 0.6),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.sports_soccer,
                                              size: 12,
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                member.extracurricularName!,
                                                style: TextStyle(
                                                  color: maroonPrimary(context),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'Poppins',
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                member.studentName ?? "Nama tidak tersedia",
                                style: TextStyle(
                                  fontSize: 17.0,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                  color: currentTextDarkColor,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.badge_outlined,
                                    size: 14,
                                    color: textMediumColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "NISN: ${member.studentNisn ?? '-'}",
                                    style: TextStyle(
                                      color: currentTextMediumColor,
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Information section
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoColumn(
                          context: context,
                          icon: Icons.school_outlined,
                          iconColor: Colors.blue,
                          label: "Kelas",
                          value: member.className ?? "-",
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: currentBorderColor,
                        ),
                        _buildInfoColumn(
                          context: context,
                          icon: Icons.calendar_today_outlined,
                          iconColor: Colors.orange,
                          label: "Bergabung",
                          value: member.joinDate ?? "-",
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: currentBorderColor,
                        ),
                        _buildInfoColumn(
                          context: context,
                          icon: Icons.sports_soccer,
                          iconColor: maroonPrimary(context),
                          label: "Ekstrakurikuler",
                          value: (member.extracurricularName != null &&
                                  member.extracurricularName != '-')
                              ? member.extracurricularName!
                              : "Belum Ada",
                        ),
                      ],
                    ),
                  ),

                  // Action row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : accentColor.withValues(alpha: 0.3),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          member.isPending
                              ? Icons.pending_actions
                              : Icons.info_outline,
                          size: 16,
                          color: maroonPrimary(context).withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          member.isPending
                              ? "Tap untuk approve/reject"
                              : "Lihat detail anggota",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: maroonPrimary(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: member.isPending
                                ? Colors.orange
                                : maroonPrimary(context),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            member.isPending
                                ? Icons.touch_app
                                : (_isRTLEnabled(context)
                                    ? CupertinoIcons.arrow_left
                                    : CupertinoIcons.arrow_right),
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
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
