import 'package:eschool_saas_staff/cubits/announcement/localNotificationsCubit.dart';
import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/data/models/system/notificationDetails.dart'
    as notificationDetails;
import 'package:eschool_saas_staff/data/repositories/announcement/announcementRepository.dart';
import 'package:eschool_saas_staff/data/repositories/auth/authRepository.dart';
import 'package:eschool_saas_staff/firebase_options.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/in_appbanner.dart';
import 'package:eschool_saas_staff/utils/system/logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();

  static NotificationService get instance => _instance;

  NotificationService._internal();

  /// Initialize Firebase and FCM
  Future<void> init() async {
    AppLogger.info('NotificationService', 'Starting FCM setup...');

    // Init Firebase if needed
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      AppLogger.info('NotificationService', 'Firebase initialized');
    } else {
      AppLogger.info('NotificationService', 'Firebase already initialized');
    }

    // Request permissions
    final settings = await FirebaseMessaging.instance.requestPermission();
    AppLogger.info('NotificationService',
        'Permission status: ${settings.authorizationStatus}');

    // Debug Token
    await _logFCMToken();

    // Register device token with backend if user is already logged in
    if (AuthRepository.getIsLogIn()) {
      AppLogger.info('NotificationService',
          'User already logged in, registering device token...');
      AuthRepository().registerDeviceToken();
    }

    // Listen for token refresh — re-register when Firebase rotates the token
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      AppLogger.info('NotificationService',
          'FCM token refreshed, re-registering with backend...');
      if (AuthRepository.getIsLogIn()) {
        AuthRepository().registerDeviceToken();
      }
    });

    // Subscribe to topics
    await subscribeToTopics([staffNotificationsTopic, allNotificationsTopic]);

    // Setup listeners
    _setupListeners();

    // Handle background launch
    _checkInitialMessage();

    AppLogger.info('NotificationService', 'FCM setup completed successfully');
  }

  Future<void> _logFCMToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      AppLogger.info('NotificationService', 'FCM Token: $token');
      // Uncomment to print for easy copy-paste in dev
      // debugPrint('[FCM-TOKEN] $token');
    } catch (e) {
      AppLogger.error('NotificationService', 'Error getting token', error: e);
    }
  }

  void _setupListeners() {
    // Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.info('NotificationService', 'Received foreground message');
      logRemoteMessageAndroid(message, tag: 'FCM-FOREGROUND');

      final type = (message.data['type'] ?? '').toString();
      final title = (message.notification?.title ?? 'Notifikasi').toString();
      final body = (message.notification?.body ?? '').toString();
      final status = message.data['status'];
      final PushType style = _mapPushType(type, status: status);

      // Simpan ke riwayat notifikasi lokal (Hive)
      _saveNotificationLocally(message);

      // Show banner
      showPushBanner(title: title, body: body, type: style);
    });

    // App Opened from Notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.info('NotificationService', 'App opened from notification');
      logRemoteMessageAndroid(message, tag: 'FCM-OPENED');

      // Simpan ke riwayat jika belum tersimpan
      _saveNotificationLocally(message);

      _handleNavigation(message);
    });
  }

  Future<void> _checkInitialMessage() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      AppLogger.info(
          'NotificationService', 'App launched from terminated state');
      logRemoteMessageAndroid(initialMessage, tag: 'FCM-INITIAL');

      // Navigate after init
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Simpan ke riwayat
        _saveNotificationLocally(initialMessage);

        _handleNavigation(initialMessage);
      });
    }
  }

  void _handleNavigation(RemoteMessage message) {
    var type = (message.data['type'] ?? '').toString();
    // Normalize type string
    type = type.trim().toLowerCase().replaceAll('-', '_');

    debugPrint("🚀 [NOTIF-NAV] Type received: $type");

    switch (type) {
      // Student leave
      case 'student_leave':
      case 'student_leave_request':
        debugPrint("🚀 [NOTIF-NAV] Navigating to generalPermissionScreen");
        Get.toNamed(Routes.generalPermissionScreen);
        break;
      // Announcement & General
      case 'announcement':
      case 'announcement_created':
      case 'announcement_updated':
      case 'notification':
        debugPrint("🚀 [NOTIF-NAV] Navigating to NotificationsScreen");
        Get.toNamed(Routes.notificationsScreen);
        break;

      // Submission / Pengumpulan Tugas -> Now go to NotificationsScreen as fallback for detail
      case 'submission':
      case 'assignment_submission':
      case 'student_submitted':
      case 'assignment':
      case 'assignment_created':
      case 'assignment_updated':
      case 'tugas':
        debugPrint("🚀 [NOTIF-NAV] Navigating to NotificationsScreen (Assignment type)");
        // Before it went directly to ManageAssignment, but user says it's better in Notif History
        Get.toNamed(Routes.notificationsScreen);
        break;

      // Attendance / Absensi
      case 'attendance':
      case 'attendance_update':
      case 'attendance_marked':
        Get.toNamed(Routes.teacherViewAttendanceScreen);
        break;

      // ... existing cases ...
      default:
        debugPrint("🚀 [NOTIF-NAV] Default navigation to NotificationsScreen");
        Get.toNamed(Routes.notificationsScreen);
    }
  }

  /// Memasukkan notifikasi ke dalam riwayat lokal (Hive)
  void _saveNotificationLocally(RemoteMessage? message) {
    if (message == null) return;
    try {
      final additionalData = message.data;
      final type = (additionalData['type'] ?? '').toString();
      
      // Ambil title & body dari notification object ATAU dari data payload (fallback)
      String title = (message.notification?.title ?? additionalData['title'] ?? 'Notifikasi').toString();
      String body = (message.notification?.body ?? additionalData['body'] ?? additionalData['message'] ?? '').toString();
      
      final image = (additionalData['image'] ?? '').toString();

      debugPrint("📥 [FCM-SERVICE] Menangkap Notifikasi Baru:");
      debugPrint("   - Judul: $title");
      debugPrint("   - Isi: $body");
      debugPrint("   - Tipe: $type");
      debugPrint("   - Data: $additionalData");

      AnnouncementRepository.addNotification(
        notificationDetails: notificationDetails.NotificationDetails(
          createdAt: DateTime.now().toString(),
          id: 0, // Fallback ID generic
          image: image,
          message: body,
          title: title,
          sendTo: type,
        ),
      ).then((_) {
        // Jika sedang di halaman notifikasi, refresh cubit
        try {
          if (Get.isRegistered<LocalNotificationsCubit>()) {
            Get.find<LocalNotificationsCubit>().getLocalNotifications();
          }
        } catch (_) {}
      });
    } catch (e) {
      debugPrint("❌ [FCM-SERVICE] Error saat memproses simpan lokal: $e");
    }
  }

  /// Helper to subscribe to topics
  Future<void> subscribeToTopics(List<String> topics) async {
    for (final topic in topics) {
      try {
        await FirebaseMessaging.instance.subscribeToTopic(topic);
        AppLogger.info('NotificationService', 'Subscribed to topic: $topic');
      } catch (e) {
        AppLogger.error('NotificationService', 'Error subscribing to $topic',
            error: e);
      }
    }
  }

  /// Helper to unsubscribe from topics
  Future<void> unsubscribeFromTopics(List<String> topics) async {
    for (final topic in topics) {
      try {
        await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
        AppLogger.info(
            'NotificationService', 'Unsubscribed from topic: $topic');
      } catch (e) {
        AppLogger.error(
            'NotificationService', 'Error unsubscribing from $topic',
            error: e);
      }
    }
  }

  int? _normalizeLeaveStatus(dynamic status) {
    if (status == null) return null;
    if (status is int) return status;

    final s = status.toString().trim().toLowerCase();
    switch (s) {
      case '1':
      case 'approved':
      case 'disetujui':
        return 1;
      case '2':
      case 'pending':
      case 'tertunda':
        return 2;
      case '3':
      case 'rejected':
      case 'ditolak':
        return 3;
      default:
        return null;
    }
  }

  PushType _mapPushType(String? rawType, {dynamic status}) {
    final key = (rawType ?? '').trim().toLowerCase().replaceAll('-', '_');

    return switch (key) {
      'assignment' ||
      'assignment_created' ||
      'assignment_updated' ||
      'tugas' =>
        PushType.info,
      'assignment_submission' || 'student_submitted' => PushType.success,
      'attendance' || 'attendance_update' => PushType.info,
      'attendance_marked' => PushType.success,
      'exam_created' => PushType.info,
      'exam_result_published' => PushType.success,
      'exam_marks_updated' => PushType.info,
      'online_exam_created' => PushType.success,
      'online_exam_updated' => PushType.info,
      'online_exam_cancelled' => PushType.error,
      'online_exam_questions_ready' => PushType.success,
      'online_exam_corrected' => PushType.success,
      'student_leave' || 'student_leave_request' => PushType.warning,
      'student_leave_status' => PushType.info,
      'leave_approved' || 'staff_leave_approved' => PushType.success,
      'leave_rejected' || 'staff_leave_rejected' => PushType.error,
      'leave_status' => switch (_normalizeLeaveStatus(status)) {
          1 => PushType.success,
          2 => PushType.warning,
          3 => PushType.error,
          _ => PushType.info,
        },
      'lesson_created' || 'lesson_updated' => PushType.info,
      'topic_created' || 'topic_updated' => PushType.info,
      'announcement' ||
      'announcement_created' ||
      'announcement_updated' =>
        PushType.info,
      'student_promoted' => PushType.success,
      'student_transferred' => PushType.warning,
      'message' || 'chat' => PushType.success,
      _ => PushType.success,
    };
  }

  void simulateNotification({required String type, required String title, required String body}) {
    try {
      debugPrint("🚀 [SIMULATE-NOTIF] Memulai simulasi...");
      final Map<String, dynamic> extraData = {
        'type': type,
        'title': title,
        'body': body,
        'message': body,
      };
      
      // Simpan ke riwayat notifikasi lokal (Hive)
      debugPrint("🚀 [SIMULATE-NOTIF] Menyimpan ke Hive lokal...");
      AnnouncementRepository.addNotification(
        notificationDetails: notificationDetails.NotificationDetails(
          createdAt: DateTime.now().toString(),
          id: 0, // Fallback ID generic
          image: '',
          message: body,
          title: title,
          sendTo: type,
        ),
      );
      
      final pushType = _mapPushType(type);
      debugPrint("🚀 [SIMULATE-NOTIF] Type map: $pushType");
      
      // Tampilkan banner in-app
      debugPrint("🚀 [SIMULATE-NOTIF] Memanggil showPushBanner...");
      showPushBanner(
        title: title,
        body: body,
        type: pushType,
        onTap: () {
          debugPrint("🚀 [SIMULATE-NOTIF] Banner ditap, menjalankan navigasi...");
          _handleNavigation(
            RemoteMessage(
              data: extraData,
            ),
          );
        },
      );
      debugPrint("🚀 [SIMULATE-NOTIF] Berhasil memicu showPushBanner");
    } catch (e, stack) {
      debugPrint("❌ [SIMULATE-NOTIF] Error dalam simulasi: $e");
      debugPrint(stack.toString());
    }
  }
}
