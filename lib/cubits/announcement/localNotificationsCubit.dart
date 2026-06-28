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
  final AnnouncementRepository _announcementRepository =
      AnnouncementRepository();

  LocalNotificationsCubit() : super(LocalNotificationsInitial()) {
    debugPrint("🏗️ [NOTIF-CUBIT] LocalNotificationsCubit created");
  }

  void getLocalNotifications() async {
    try {
      debugPrint("🚀 [NOTIF-CUBIT] getLocalNotifications initiated");
      emit(LocalNotificationsFetchInProgress());

      // 1. Fetch from Local (Hive) first as it should be fast
      List<NotificationDetails> localNotifications = [];
      try {
        localNotifications = await _announcementRepository.getLocalNotifications();
        debugPrint("💾 [NOTIF-CUBIT] Local notifications count: ${localNotifications.length}");
      } catch (e) {
        debugPrint("❌ [NOTIF-CUBIT] Error getting local notifications: $e");
      }

      // ALWAYS emit success (either local data or empty list) 
      // so the user doesn't see a stuck loader while waiting for server
      _sortNotifications(localNotifications);
      emit(LocalNotificationsFetchSuccess(notifications: List.from(localNotifications)));

      // 2. Fetch from Server
      List<NotificationDetails> serverNotifications = [];
      try {
        debugPrint("📡 [NOTIF-CUBIT] Fetching server notifications...");
        final serverResult = await _announcementRepository.getNotifications();
        serverNotifications = serverResult.notifications;
        debugPrint("📡 [NOTIF-CUBIT] Server notifications count: ${serverNotifications.length}");
      } catch (e) {
        debugPrint("⚠️ [NOTIF-CUBIT] Failed to fetch from server: $e");
      }

      // 3. Merge and Deduplicate
      final Map<String, NotificationDetails> mergedMap = {};
      
      // Start with local ones we already have
      for (var notif in localNotifications) {
        final key = _getNotifKey(notif);
        mergedMap[key] = notif;
      }
      
      // Add server ones, deduplicating
      for (var notif in serverNotifications) {
        final key = _getNotifKey(notif);
        // If not present in map by key, check for title/message similarity
        if (!mergedMap.containsKey(key)) {
          bool isDuplicate = mergedMap.values.any((existing) => 
            existing.title == notif.title && existing.message == notif.message);
          if (!isDuplicate) {
            mergedMap[key] = notif;
          }
        } else {
          // If already present, server data might have more info (like proper ID), so update it
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
    return '${notif.title ?? ""}_${notif.message ?? ""}_${notif.createdAt ?? ""}';
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
}
