// ignore_for_file: library_prefixes

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/data/models/system/notificationDetails.dart'
    as notificationDetails;
import 'package:eschool_saas_staff/data/repositories/announcement/announcementRepository.dart';
import 'package:eschool_saas_staff/data/repositories/auth/authRepository.dart';
import 'package:eschool_saas_staff/data/repositories/system/settingsRepository.dart';
import 'package:eschool_saas_staff/utils/system/api.dart';
import 'package:eschool_saas_staff/utils/system/hiveBoxKeys.dart';
import 'package:eschool_saas_staff/utils/system/logger.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vibration/vibration.dart';

class NotificationUtility {
  static String notificationType = "Notification";
  static String leaveType = "Leave";
  static String messageType = "Message";

  //
  @pragma('vm:entry-point')
  static Future<void> onBackgroundMessage(RemoteMessage remoteMessage) async {
    // Log semua notifikasi yang masuk di background
    logRemoteMessageAndroid(remoteMessage, tag: 'FCM-UTILITY-BACKGROUND');

    final additionalData = remoteMessage.data;

    if (kDebugMode) {
      debugPrint(remoteMessage.data.toString());
    }

    final type = (additionalData['type'] ?? "").toString().toLowerCase().replaceAll('-', '_');

    if (kDebugMode) {
      debugPrint("Background notification received. Type: $type");
    }

    if (type.isNotEmpty) {
      await Hive.initFlutter();
      await Hive.openBox(authBoxKey);
      await AnnouncementRepository.addNotificationTemporarily(
          data: notificationDetails.NotificationDetails(
        createdAt: DateTime.now().toString(),
        id: AuthRepository.getUserDetails().id,
        image: remoteMessage.data['image'] ?? "",
        message: remoteMessage.notification?.body ?? "",
        title: remoteMessage.notification?.title ?? "",
        sendTo: type,
      ).toJson());
    }
  }

  static void _onTapNotificationScreenNavigateCallback({
    required Map<String, dynamic> notificationData,
  }) {
    var type = (notificationData['type'] ?? "").toString();
    type = type.trim().toLowerCase().replaceAll('-', '_');

    if (type.isNotEmpty) {
      // Sesuai dengan pembagian di NotificationService
      switch (type) {
        case 'student_leave':
        case 'student_leave_request':
          Get.toNamed(Routes.leaveRequestScreen);
          break;
          
        case 'student_leave_status':
          Get.toNamed(Routes.generalPermissionScreen);
          break;

        case 'leave':
        case 'leave_status':
        case 'staff_leave_approved':
        case 'staff_leave_rejected':
          Get.toNamed(Routes.leavesScreen, arguments: {'showMyLeaves': true});
          break;

        case 'assignment':
        case 'tugas':
        case 'assignment_submission':
        case 'student_submitted':
          Get.toNamed(Routes.teacherManageAssignmentScreen);
          break;

        case 'extracurricular_registration':
          Get.toNamed(Routes.extracurricularMember);
          break;

        case 'attendance':
        case 'attendance_update':
        case 'attendance_marked':
          Get.toNamed(Routes.teacherViewAttendanceScreen);
          break;

        case 'message':
        case 'chat':
          if (Get.currentRoute != Routes.chatContacts) {
            Get.toNamed(Routes.chatContacts);
          }
          break;

        default:
          Get.toNamed(Routes.notificationsScreen);
      }
    }
  }

  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  //

  //Ask notification permission here
  static Future<NotificationSettings> _getNotificationPermission() async {
    return await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
  }

  static Future<void> setUpNotificationService() async {
    if (kDebugMode) {
      debugPrint("Setting up notification service...");
    }
    NotificationSettings notificationSettings =
        await FirebaseMessaging.instance.getNotificationSettings();

    //ask for permission
    if (notificationSettings.authorizationStatus ==
        AuthorizationStatus.notDetermined) {
      notificationSettings = await _getNotificationPermission();

      //if permission is provisionnal or authorised
      if (notificationSettings.authorizationStatus ==
              AuthorizationStatus.authorized ||
          notificationSettings.authorizationStatus ==
              AuthorizationStatus.provisional) {
        _initNotificationListener();
      }

      //if permission denied
    } else if (notificationSettings.authorizationStatus ==
        AuthorizationStatus.denied) {
      //If user denied then ask again
      notificationSettings = await _getNotificationPermission();
      if (notificationSettings.authorizationStatus ==
          AuthorizationStatus.denied) {
        return;
      }
    }
    _initNotificationListener();
  }

  static void _initNotificationListener() {
    if (kDebugMode) {
      debugPrint("Notification setup done");
    }
    // Log FCM Token for debugging
    FirebaseMessaging.instance.getToken().then((token) {
      if (kDebugMode) {
        debugPrint('FCM Token: $token');
      }
    });
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, // Required to display a heads up notification
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen(foregroundMessageListener);
    FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedAppListener);

    FirebaseMessaging.instance.getInitialMessage().then((value) {
      if (value != null) {
        // Log initial message ketika app dibuka dari terminated state
        logRemoteMessageAndroid(value, tag: 'FCM-UTILITY-INITIAL');
      }
      if (kDebugMode) {
        debugPrint("Initial notification");
        debugPrint(value?.data.toString());
      }
      _onTapNotificationScreenNavigateCallback(
        notificationData: value?.data ?? {},
      );
    });

    if (!kIsWeb) {
      _initLocalNotification();
    }
  }

  static void foregroundMessageListener(RemoteMessage remoteMessage) async {
    // Log semua notifikasi yang masuk
    logRemoteMessageAndroid(remoteMessage, tag: 'FCM-UTILITY-FOREGROUND');

    //await FirebaseMessaging.instance.getToken();

    final additionalData = remoteMessage.data;

    final type = (additionalData['type'] ?? "").toString();

    // Simpan semua jenis notifikasi penting ke riwayat (Notification, Leave, Message)
    if (type == notificationType || type == leaveType || type == messageType) {
      AnnouncementRepository.addNotification(
          notificationDetails: notificationDetails.NotificationDetails(
        createdAt: DateTime.now().toString(),
        id: AuthRepository.getUserDetails().id,
        image: remoteMessage.data['image'] ?? "",
        message: remoteMessage.notification?.body ?? "",
        title: remoteMessage.notification?.title ?? "",
        sendTo: type, // Simpan type agar bisa dibedakan di riwayat
      ));
    }

    createLocalNotification(
        dismissable: true,
        imageUrl: (additionalData['image'] ?? "").toString(),
        title: remoteMessage.notification?.title ?? "You have new notification",
        body: remoteMessage.notification?.body ?? "",
        payload: jsonEncode(additionalData));

    // Trigger vibration if enabled and device supports it
    _triggerVibration();
  }

  static Future<void> _triggerVibration() async {
    final settingsRepository = SettingsRepository();
    final vibrationEnabled = settingsRepository.getVibrationEnabled();

    if (vibrationEnabled) {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        Vibration.vibrate(duration: 500);
      }
    }
  }

  static void onMessageOpenedAppListener(RemoteMessage remoteMessage) {
    // Log notifikasi yang dibuka dari background/terminated
    logRemoteMessageAndroid(remoteMessage, tag: 'FCM-UTILITY-OPENED');

    _onTapNotificationScreenNavigateCallback(
        notificationData: remoteMessage.data);
  }

  static void _initLocalNotification() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    InitializationSettings initializationSettings =
        const InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    _requestPermissionsForIos();
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) async {
        _onTapNotificationScreenNavigateCallback(
            notificationData:
                Map<String, dynamic>.from(jsonDecode(details.payload ?? "")));
      },
    );
  }

  static Future<void> _requestPermissionsForIos() async {
    if (Platform.isIOS) {
      _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions();
    }
  }

  static Future<void> createLocalNotification(
      {required String title,
      required bool dismissable, //User can clear it
      required String body,
      required String imageUrl,
      required String payload}) async {
    late AndroidNotificationDetails androidPlatformChannelSpecifics;
    if (imageUrl.isNotEmpty) {
      final downloadedImagePath = await _downloadAndSaveFile(imageUrl);
      if (downloadedImagePath.isEmpty) {
        //If somwhow failed to download image
        androidPlatformChannelSpecifics = AndroidNotificationDetails(
            'com.global.talent.competition', //channel id
            'Local notification',

            //channel name
            importance: Importance.max,
            priority: Priority.high,
            ongoing: !dismissable,
            ticker: 'ticker');
      } else {
        var bigPictureStyleInformation = BigPictureStyleInformation(
            FilePathAndroidBitmap(downloadedImagePath),
            hideExpandedLargeIcon: true,
            contentTitle: title,
            htmlFormatContentTitle: true,
            summaryText: title,
            htmlFormatSummaryText: true);

        androidPlatformChannelSpecifics = AndroidNotificationDetails(
            'com.global.talent.competition', //channel id
            'Local notification', //channel name

            importance: Importance.max,
            priority: Priority.high,
            largeIcon: FilePathAndroidBitmap(downloadedImagePath),
            styleInformation: bigPictureStyleInformation,
            ongoing: !dismissable,
            ticker: 'ticker');
      }
    } else {
      androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'com.global.talent.competition', //channel id
          'Local notification', //channel name

          importance: Importance.max,
          priority: Priority.high,
          ongoing: !dismissable,
          ticker: 'ticker');
    }
    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails();

    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics, iOS: iosNotificationDetails);
    await _flutterLocalNotificationsPlugin
        .show(0, title, body, platformChannelSpecifics, payload: payload);
  }

  static Future<String> _downloadAndSaveFile(String url) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/temp.jpg';

    try {
      await Api.download(
          url: url,
          cancelToken: CancelToken(),
          savePath: filePath,
          updateDownloadedPercentage: (value) {});

      return filePath;
    } catch (e) {
      return "";
    }
  }
}
