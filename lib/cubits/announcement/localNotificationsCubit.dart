import 'package:eschool_saas_staff/data/models/system/notificationDetails.dart';
import 'package:eschool_saas_staff/data/repositories/announcement/announcementRepository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class LocalNotificationsState {}

class LocalNotificationsInitial extends LocalNotificationsState {}

class LocalNotificationsFetchInProgress extends LocalNotificationsState {}

class LocalNotificationsFetchSuccess extends LocalNotificationsState {
  final List<NotificationDetails> notifications;

  LocalNotificationsFetchSuccess({required this.notifications});
}

class LocalNotificationsFetchFailure extends LocalNotificationsState {
  final String errorMessage;

  LocalNotificationsFetchFailure(this.errorMessage);
}

class LocalNotificationsCubit extends Cubit<LocalNotificationsState> {
  final AnnouncementRepository _announcementRepository;

  LocalNotificationsCubit([AnnouncementRepository? announcementRepository])
      : _announcementRepository = announcementRepository ?? AnnouncementRepository(),
        super(LocalNotificationsInitial()) {
    debugPrint("🏗️ [NOTIF-CUBIT] LocalNotificationsCubit created");
  }

  void getLocalNotifications() async {
    try {
      debugPrint("🚀 [NOTIF-CUBIT] getLocalNotifications initiated");
      emit(LocalNotificationsFetchInProgress());

      // 0. Ambil parameter filter (daftar hitam & waktu pembersihan terakhir)
      final deletedKeys = await _announcementRepository.getDeletedNotificationKeys();
      final lastClearedStr = await _announcementRepository.getLastClearedTimestamp();
      final lastClearedAt = lastClearedStr != null ? DateTime.tryParse(lastClearedStr) : null;

      bool isFiltered(NotificationDetails n) {
        final key = _getNotifKey(n);
        // Cek apakah ada di blacklist
        if (deletedKeys.contains(key)) return true;
        
        // Cek apakah dibuat sebelum waktu pembersihan terakhir
        if (lastClearedAt != null && n.createdAt != null) {
          final createdAt = DateTime.tryParse(n.createdAt!);
          if (createdAt != null && createdAt.isBefore(lastClearedAt)) {
            return true;
          }
        }
        return false;
      }

      // 1. Fetch from Local (Hive) first
      List<NotificationDetails> localNotifications = [];
      try {
        final allLocal = await _announcementRepository.getLocalNotifications();
        localNotifications = allLocal.where((n) => !isFiltered(n)).toList();
        debugPrint("💾 [NOTIF-CUBIT] Local notifications (filtered) count: ${localNotifications.length}");
      } catch (e) {
        debugPrint("❌ [NOTIF-CUBIT] Error getting local notifications: $e");
      }

      _sortNotifications(localNotifications);
      if (localNotifications.isNotEmpty) {
        emit(LocalNotificationsFetchSuccess(notifications: List.from(localNotifications)));
      }

      // 2. Fetch from Server
      List<NotificationDetails> serverNotifications = [];
      try {
        debugPrint("📡 [NOTIF-CUBIT] Fetching server notifications...");
        final serverResult = await _announcementRepository.getNotifications();
        serverNotifications = serverResult.notifications.where((n) => !isFiltered(n)).toList();
        debugPrint("📡 [NOTIF-CUBIT] Server notifications (filtered) count: ${serverNotifications.length}");
      } catch (e) {
        debugPrint("⚠️ [NOTIF-CUBIT] Failed to fetch from server: $e");
      }

      // 3. Merge and Deduplicate
      final Map<String, NotificationDetails> mergedMap = {};
      
      for (var notif in localNotifications) {
        mergedMap[_getNotifKey(notif)] = notif;
      }
      
      for (var notif in serverNotifications) {
        final key = _getNotifKey(notif);
        if (!mergedMap.containsKey(key)) {
          mergedMap[key] = notif;
        }
      }

      final allNotifications = mergedMap.values.toList();
      _sortNotifications(allNotifications);
      
      debugPrint("✅ [NOTIF-CUBIT] Final merged notifications count: ${allNotifications.length}");
      emit(LocalNotificationsFetchSuccess(notifications: allNotifications));

    } catch (e, st) {
      debugPrint("❌ [NOTIF-CUBIT] Fatal error in getLocalNotifications: $e\n$st");
      emit(LocalNotificationsFetchFailure(e.toString()));
    }
  }

  String _getNotifKey(NotificationDetails notif) {
    return notif.createdAt.toString();
  }

  void _sortNotifications(List<NotificationDetails> list) {
    list.sort((first, second) {
      try {
        final a = first.createdAt ?? "";
        final b = second.createdAt ?? "";
        return b.compareTo(a);
      } catch (e) {
        return 0;
      }
    });
  }

  void clearAllLocalNotifications() async {
    try {
      await _announcementRepository.clearLocalNotifications();
      emit(LocalNotificationsFetchSuccess(notifications: []));
      getLocalNotifications();
    } catch (e) {
      emit(LocalNotificationsFetchFailure(e.toString()));
    }
  }

  void removeNotification(String key) async {
    try {
      await _announcementRepository.deleteLocalNotification(key);
      getLocalNotifications(); // Refresh list
    } catch (e) {
      debugPrint("Gagal hapus notifikasi di cubit: $e");
    }
  }
}
