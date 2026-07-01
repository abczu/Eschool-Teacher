import '../../../data/models/system/notificationDetails.dart';
import '../../../data/repositories/announcement/announcementRepository.dart';
import 'package:eschool_saas_staff/cubits/announcement/localNotificationsCubit.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customCircularProgressIndicator.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/errorContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/notificationItemContainer.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  static Widget getRouteInstance() {
    //final arguments = Get.arguments as Map<String,dynamic>;
    return BlocProvider(
      create: (context) => LocalNotificationsCubit(),
      child: const NotificationsScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    Future.delayed(Duration.zero, () {
      if (mounted) {
        context.read<LocalNotificationsCubit>().getLocalNotifications();
      }
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: CustomModernAppBar(
        title: Utils.getTranslatedLabel(notificationsKey),
        onBackPressed: () => Navigator.of(context).pop(),
        icon: Icons.notifications_rounded,
        fabAnimationController: _fabAnimationController,
        showArchiveButton: true,
        archiveIcon: Icons.delete_sweep_rounded,
        onArchivePressed: () {
          _showClearConfirmationDialog(context);
        },
      ),
      body: Container(
        color: const Color(0xFFF9F9F9), // Very light grey backround
        child: BlocBuilder<LocalNotificationsCubit, LocalNotificationsState>(
          builder: (context, state) {
            if (state is LocalNotificationsFetchSuccess) {
              if (state.notifications.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async {
                    context
                        .read<LocalNotificationsCubit>()
                        .getLocalNotifications();
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.2),
                      const Center(
                        child: Icon(Icons.notifications_none_rounded,
                            size: 80, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          "Belum Ada Notifikasi",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<LocalNotificationsCubit>()
                      .getLocalNotifications();
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.notifications.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notification = state.notifications[index];
                    return GestureDetector(
                      onLongPress: () => _showDeleteSingleConfirmation(context, notification),
                      child: NotificationItemContainer(
                        notificationDetails: notification,
                        index: index,
                      ),
                    );
                  },
                ),
              );
            }

            if (state is LocalNotificationsFetchFailure) {
              return Center(
                child: ErrorContainer(
                  errorMessage: state.errorMessage,
                  onTapRetry: () {
                    context
                        .read<LocalNotificationsCubit>()
                        .getLocalNotifications();
                  },
                ),
              );
            }

            return Center(
              child: CustomCircularProgressIndicator(
                indicatorColor: primaryColor,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showClearConfirmationDialog(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text("Hapus Semua?"),
          ],
        ),
        content: const Text(
          "Apakah Anda yakin ingin menghapus semua riwayat notifikasi lokal? Tindakan ini tidak dapat dibatalkan.",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              "Batal",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context
                  .read<LocalNotificationsCubit>()
                  .clearAllLocalNotifications();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Hapus Semua"),
          ),
        ],
      ),
    );
  }

  void _showDeleteSingleConfirmation(BuildContext context, NotificationDetails notification) {
    showDialog(
      context: context,
      builder: (confirmContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Notifikasi?"),
        content: const Text("Apakah Anda yakin ingin menghapus notifikasi ini saja?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmContext),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              context.read<LocalNotificationsCubit>().removeNotification(
                notification.createdAt.toString()
              );
              Navigator.pop(confirmContext);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
