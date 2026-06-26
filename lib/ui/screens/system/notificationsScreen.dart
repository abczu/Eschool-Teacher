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
    return Scaffold(
      appBar: CustomModernAppBar(
        title: Utils.getTranslatedLabel(notificationsKey),
        icon: Icons.notifications,
        fabAnimationController: _fabAnimationController,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: BlocBuilder<LocalNotificationsCubit, LocalNotificationsState>(
        builder: (context, state) {
          if (state is LocalNotificationsFetchSuccess) {
            if (state.notifications.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<LocalNotificationsCubit>().getLocalNotifications();
                },
                child: ListView(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                    const Center(
                      child: Icon(Icons.notifications_off_outlined,
                          size: 80, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        "Belum Ada Notifikasi",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700]),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        "Notifikasi baru untuk Anda akan muncul di sini.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<LocalNotificationsCubit>().getLocalNotifications();
              },
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 15, bottom: 20, left: 16, right: 16),
                itemCount: state.notifications.length,
                itemBuilder: (context, index) {
                  return NotificationItemContainer(
                    notificationDetails: state.notifications[index],
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
              indicatorColor: Theme.of(context).colorScheme.primary,
            ),
          );
        },
      ),
    );
  }
}
