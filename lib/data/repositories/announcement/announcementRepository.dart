import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eschool_saas_staff/data/models/announcement/announcement.dart';
import 'package:eschool_saas_staff/data/models/system/notificationDetails.dart';
import 'package:eschool_saas_staff/data/repositories/auth/authRepository.dart';
import 'package:eschool_saas_staff/utils/system/api.dart';
import 'package:eschool_saas_staff/utils/system/hiveBoxKeys.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String notificationsBoxKey = "notifications";
const String deletedNotificationsBoxKey = "deleted_notifications";
const String temporarilyStoredNotificationsKey =
    "temporarilyStoredNotifications";

class AnnouncementRepository {
  Future<
      ({
        List<NotificationDetails> notifications,
        int currentPage,
        int totalPage
      })> getNotifications({int? page}) async {
    try {
      debugPrint('📡 [NOTIFICATION REPO] Fetching notifications, page: ${page ?? 1}');
      final result = await Api.get(url: Api.getNotifications, queryParameters: {
        "page": page ?? 1,
      });
      
      debugPrint('📡 [NOTIFICATION REPO] Raw response received');
      
      dynamic notificationsData = result['data'];
      List notificationsList = [];
      int currentPage = 1;
      int totalPage = 1;

      if (notificationsData is Map) {
        if (notificationsData['data'] is List) {
          notificationsList = notificationsData['data'];
          currentPage = int.parse((notificationsData['current_page'] ?? 1).toString());
          totalPage = int.parse((notificationsData['last_page'] ?? 1).toString());
        }
      } else if (notificationsData is List) {
        notificationsList = notificationsData;
      }

      debugPrint('✅ [NOTIFICATION REPO] Parsed ${notificationsList.length} items');

      return (
        notifications: notificationsList
            .map((notification) =>
                NotificationDetails.fromJson(Map.from(notification ?? {})))
            .toList(),
        currentPage: currentPage,
        totalPage: totalPage,
      );
    } catch (e) {
      debugPrint('❌ [NOTIFICATION REPO] Error: $e');
      throw ApiException(e.toString());
    }
  }

  Future<({List<Announcement> announcements, int currentPage, int totalPage})>
      getAnnouncements({int? page, required int classSectionId}) async {
    try {
      final result = await Api.get(url: Api.getAnnouncements, queryParameters: {
        "page": page ?? 1,
        "class_section_id": classSectionId
      });

      // debugPrint("GETTING");

      // String formattedJson = JsonEncoder.withIndent("  ").convert(result);

      // // Cetak per baris
      // for (var line in formattedJson.split("\n")) {
      //   debugPrint(line.toString());
      // }

      return (
        announcements: ((result['data']['data'] ?? []) as List)
            .map((announcement) =>
                Announcement.fromJson(Map.from(announcement ?? {})))
            .toList(),
        currentPage: (result['data']['current_page'] ?? 1) as int,
        totalPage: (result['data']['last_page'] ?? 1) as int,
      );
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> deleteNotification({required int notificationId}) async {
    try {
      await Api.post(
          url: Api.deleteNotification,
          body: {"notification_id": notificationId});
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> deleteAnnouncement({required int announcementId}) async {
    try {
      await Api.post(
          url: Api.deleteGeneralAnnouncement,
          body: {"announcement_id": announcementId});
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> sendNotification(
      {required String title,
      required String message,
      required String sendTo,
      List<String>? roles,
      List<int>? userIds,
      String? filePath}) async {
    try {
      await Api.post(url: Api.sendNotification, body: {
        "title": title,
        "message": message,
        "type": sendTo,
        "user_id": userIds,
        "roles": roles,
        "file": (filePath ?? "").isEmpty
            ? null
            : (await MultipartFile.fromFile(filePath!))
      });
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> sendGeneralAnnouncement(
      {required String title,
      String? description,
      required List<int> classSectionIds,
      List<String>? filePaths}) async {
    try {
      List<MultipartFile>? files;

      if ((filePaths ?? []).isNotEmpty) {
        files = [];
        for (var filePath in filePaths!) {
          files.add(await MultipartFile.fromFile(filePath));
        }
      }
      await Api.post(url: Api.sendGeneralAnnouncement, body: {
        "title": title,
        "description": description,
        "class_section_id": classSectionIds,
        "file": files
      });
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> editGeneralAnnouncement(
      {required String title,
      String? description,
      required List<int> classSectionIds,
      required int announcementId,
      List<String>? filePaths}) async {
    try {
      List<MultipartFile>? files;

      if ((filePaths ?? []).isNotEmpty) {
        files = [];
        for (var filePath in filePaths!) {
          files.add(await MultipartFile.fromFile(filePath));
        }
      }
      await Api.post(url: Api.editGeneralAnnouncement, body: {
        "title": title,
        "description": description,
        "announcement_id": announcementId,
        "class_section_id": classSectionIds,
        "file": files
      });
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  static Future<void> addNotification(
      {required NotificationDetails notificationDetails}) async {
    try {
      if (!Hive.isBoxOpen(authBoxKey)) {
        await Hive.openBox(authBoxKey);
      }
      final userId = AuthRepository.getUserDetails().id ?? 0;
      final userBoxKey = "${notificationsBoxKey}_$userId";
      
      debugPrint("🔔 [NOTIFICATION-REPO] Simpan ke Box: $userBoxKey");
      
      if (!Hive.isBoxOpen(userBoxKey)) {
        await Hive.openBox(userBoxKey);
      }

      await Hive.box(userBoxKey).put(
          notificationDetails.createdAt.toString(),
          notificationDetails.toJson());
          
      debugPrint("✅ [NOTIFICATION-REPO] BERHASIL simpan ke Hive.");
    } catch (e) {
      debugPrint("❌ [NOTIFICATION-REPO] GAGAL simpan ke Hive! Error: $e");
    }
  }

  static Future<void> addNotificationTemporarily(
      {required Map<String, dynamic> data}) async {
    try {
      debugPrint("💾 [NOTIFICATION-REPO] Menyimpan ke Storage Sementara (SharedPrefs)...");
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      await sharedPreferences.reload();
      List<String> notifications =
          sharedPreferences.getStringList(temporarilyStoredNotificationsKey) ??
              List<String>.from([]);

      notifications.add(jsonEncode(data));

      await sharedPreferences.setStringList(
          temporarilyStoredNotificationsKey, notifications);
      debugPrint("✅ [NOTIFICATION-REPO] Berhasil simpan sementara. Total Antrean: ${notifications.length}");
    } catch (e) {
      debugPrint("❌ [NOTIFICATION-REPO] Gagal simpan sementara! Error: $e");
    }
  }

  static Future<List<Map<String, dynamic>>>
      getTemporarilyStoredNotifications() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.reload();
    List<String> notifications =
        sharedPreferences.getStringList(temporarilyStoredNotificationsKey) ??
            List<String>.from([]);

    return notifications
        .map((notificationData) =>
            Map<String, dynamic>.from(jsonDecode(notificationData) ?? {}))
        .toList();
  }

  static Future<void> clearTemporarilyNotification() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setStringList(temporarilyStoredNotificationsKey, []);
  }

  Future<List<NotificationDetails>> getLocalNotifications() async {
    try {
      if (!Hive.isBoxOpen(authBoxKey)) {
        await Hive.openBox(authBoxKey);
      }
      final userId = AuthRepository.getUserDetails().id ?? 0;
      final userBoxKey = "${notificationsBoxKey}_$userId";
      
      if (!Hive.isBoxOpen(userBoxKey)) {
        await Hive.openBox(userBoxKey);
      }
      
      Box notificationBox = Hive.box(userBoxKey);
      List<NotificationDetails> notifications = [];

      debugPrint("📖 [NOTIFICATION-REPO] Membaca data User: $userId");

      for (var notificationKey in notificationBox.keys.toList()) {
        try {
          final data = notificationBox.get(notificationKey);
          if (data != null) {
            notifications.add(NotificationDetails.fromJson(
              Map<String, dynamic>.from(data),
            ));
          }
        } catch (e) {
          debugPrint("❌ [NOTIFICATION-REPO] Gagal parse item Hive: $e");
        }
      }
      
      debugPrint("✅ [NOTIFICATION-REPO] Berhasil membaca ${notifications.length} notifikasi.");

      // Load from Temporary Storage (SharedPrefs)
      try {
        final tempNotifications = await getTemporarilyStoredNotifications();
        for (var temp in tempNotifications) {
          notifications.add(NotificationDetails.fromJson(temp));
        }
        // Optional: Move temp to hive or clear temp after loading if desired
        // For now, just merge to show data
      } catch (e) {
        debugPrint("Error loading temporary notifications: $e");
      }

      // REMOVED: Incorrect ID filtering logic that caused blank screens
      // element.id is the notification ID, not the user ID.
      // In a multi-school/multi-user environment, we should use a proper field,
      // but for now, showing all local notifications to ensure data is visible.

      // Sort by newest first
      notifications.sort((first, second) {
        try {
          return (second.createdAt ?? "").compareTo(first.createdAt ?? "");
        } catch (e) {
          return 0;
        }
      });

      return notifications;
    } catch (e) {
      debugPrint("getLocalNotifications error: $e");
      return [];
    }
  }

  Future<void> clearLocalNotifications() async {
    try {
      if (!Hive.isBoxOpen(authBoxKey)) {
        await Hive.openBox(authBoxKey);
      }
      final userId = AuthRepository.getUserDetails().id ?? 0;
      final userBoxKey = "${notificationsBoxKey}_$userId";
      final deletedBoxKey = "${deletedNotificationsBoxKey}_$userId";
      
      if (!Hive.isBoxOpen(userBoxKey)) {
        await Hive.openBox(userBoxKey);
      }
      if (!Hive.isBoxOpen(deletedBoxKey)) {
        await Hive.openBox(deletedBoxKey);
      }

      // Hapus data Hive
      await Hive.box(userBoxKey).clear();
      await clearTemporarilyNotification();

      // Catat waktu pembersihan terakhir
      await Hive.box(deletedBoxKey).put('last_cleared_at', DateTime.now().toString());
      
      debugPrint("✅ [NOTIFICATION-REPO] Berhasil pembersihan total untuk User: $userId");
    } catch (e) {
      debugPrint("❌ [NOTIFICATION-REPO] Gagal menghapus notifikasi! Error: $e");
    }
  }

  Future<String?> getLastClearedTimestamp() async {
    try {
      final userId = AuthRepository.getUserDetails().id ?? 0;
      final deletedBoxKey = "${deletedNotificationsBoxKey}_$userId";
      
      if (!Hive.isBoxOpen(deletedBoxKey)) {
        await Hive.openBox(deletedBoxKey);
      }
      
      return Hive.box(deletedBoxKey).get('last_cleared_at') as String?;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteLocalNotification(String notificationKey) async {
    try {
      if (!Hive.isBoxOpen(authBoxKey)) {
        await Hive.openBox(authBoxKey);
      }
      final userId = AuthRepository.getUserDetails().id ?? 0;
      final userBoxKey = "${notificationsBoxKey}_$userId";
      final deletedBoxKey = "${deletedNotificationsBoxKey}_$userId";

      if (!Hive.isBoxOpen(userBoxKey)) {
        await Hive.openBox(userBoxKey);
      }
      if (!Hive.isBoxOpen(deletedBoxKey)) {
        await Hive.openBox(deletedBoxKey);
      }
      
      // Hapus dari riwayat aktif
      await Hive.box(userBoxKey).delete(notificationKey);
      
      // Masukkan ke daftar hitam agar tidak muncul lagi dari server
      await Hive.box(deletedBoxKey).put(notificationKey, true);
      
      debugPrint("✅ [NOTIFICATION-REPO] Berhasil mem-blacklist notifikasi: $notificationKey");
    } catch (e) {
      debugPrint("❌ [NOTIFICATION-REPO] Gagal hapus notifikasi tunggal! Error: $e");
    }
  }

  Future<List<String>> getDeletedNotificationKeys() async {
    try {
      final userId = AuthRepository.getUserDetails().id ?? 0;
      final deletedBoxKey = "${deletedNotificationsBoxKey}_$userId";
      
      if (!Hive.isBoxOpen(deletedBoxKey)) {
        await Hive.openBox(deletedBoxKey);
      }
      
      return Hive.box(deletedBoxKey).keys.cast<String>().toList();
    } catch (e) {
      return [];
    }
  }
}
