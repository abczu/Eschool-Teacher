import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:eschool_saas_staff/data/models/system/notificationDetails.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationItemContainer extends StatelessWidget {
  final NotificationDetails notificationDetails;
  final int index;

  const NotificationItemContainer({
    super.key,
    required this.notificationDetails,
    this.index = 0,
  });

  IconData _getIcon() {
    final title = (notificationDetails.title ?? "").toLowerCase();
    final message = (notificationDetails.message ?? "").toLowerCase();

    if (title.contains("cuti") ||
        title.contains("leave") ||
        message.contains("cuti") ||
        message.contains("leave")) {
      return Icons.calendar_today_rounded;
    }
    if (title.contains("pesan") || title.contains("message")) {
      return Icons.message_rounded;
    }
    if (title.contains("pengumuman") || title.contains("announcement")) {
      return Icons.campaign_rounded;
    }
    if (title.contains("tugas") || title.contains("assignment")) {
      return Icons.assignment_rounded;
    }
    return Icons.notifications_rounded;
  }

  String _formatTimeAgo(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      return timeago.format(date, locale: 'id');
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return FadeInLeft(
      duration: Duration(milliseconds: 400 + (index * 80)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Accent Side Bar
              Container(
                width: 5,
                color: primaryColor,
              ),
              
              // Main Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // App Theme Icon Style
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getIcon(),
                              color: primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Title and Status
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notificationDetails.title ?? "Pemberitahuan",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey[900],
                                  ),
                                ),
                                Text(
                                  _formatTimeAgo(notificationDetails.createdAt),
                                  style: TextStyle(
                                    fontSize: 11.0,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Professional Message
                      Text(
                        notificationDetails.message ?? "-",
                        style: TextStyle(
                          color: Colors.blueGrey[800],
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),

                      // Image Display
                      if ((notificationDetails.image ?? "").isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            notificationDetails.image!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
