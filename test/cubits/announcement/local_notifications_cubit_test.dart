import 'package:bloc_test/bloc_test.dart';
import 'package:eschool_saas_staff/cubits/announcement/localNotificationsCubit.dart';
import 'package:eschool_saas_staff/data/models/system/notificationDetails.dart';
import 'package:eschool_saas_staff/data/repositories/announcement/announcementRepository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Failures in generation: if this fails, we can use manual mocks.
import 'local_notifications_cubit_test.mocks.dart';

@GenerateMocks([AnnouncementRepository])
void main() {
  late LocalNotificationsCubit cubit;
  late MockAnnouncementRepository mockRepository;

  setUp(() {
    mockRepository = MockAnnouncementRepository();
    // Kita berikan mockRepository ke Cubit (Dependency Injection)
    cubit = LocalNotificationsCubit(mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('LocalNotificationsCubit Tests', () {
    final mockNotif1 = NotificationDetails(
      id: 1,
      title: "Promo Baru",
      message: "Cek diskon hari ini",
      createdAt: "2024-01-01 10:00:00",
    );

    final mockNotif2 = NotificationDetails(
      id: 2,
      title: "Update Keamanan",
      message: "Segera ganti password",
      createdAt: "2024-01-02 11:00:00",
    );

    test('State awal harus LocalNotificationsInitial', () {
      expect(cubit.state, isA<LocalNotificationsInitial>());
    });

    blocTest<LocalNotificationsCubit, LocalNotificationsState>(
      'Harus emit [InProgress, Success] dan menyaring notifikasi yang di-blacklist',
      build: () {
        // Simulasi: Repository mengembalikan 2 notifikasi
        when(mockRepository.getLocalNotifications())
            .thenAnswer((_) async => [mockNotif1, mockNotif2]);
        
        // Simulasi: Server mengembalikan data kosong
        when(mockRepository.getNotifications())
            .thenAnswer((_) async => (notifications: <NotificationDetails>[], currentPage: 1, totalPage: 1));

        // Simulasi: mockNotif1 ada dalam blacklist (deleted notifications)
        when(mockRepository.getDeletedNotificationKeys())
            .thenAnswer((_) async => ["2024-01-01 10:00:00"]);
        
        when(mockRepository.getLastClearedTimestamp())
            .thenAnswer((_) async => null);

        return cubit;
      },
      act: (cubit) => cubit.getLocalNotifications(),
      expect: () => [
        isA<LocalNotificationsFetchInProgress>(),
        isA<LocalNotificationsFetchSuccess>().having(
            (s) => s.notifications.length, "Hanya 1 notifikasi tersisa", 1),
      ],
      verify: (cubit) {
        // Pastikan mockNotif1 yang di-blacklist tidak ada di state akhir
        final successState = cubit.state as LocalNotificationsFetchSuccess;
        expect(successState.notifications.first.id, 2);
      },
    );

    blocTest<LocalNotificationsCubit, LocalNotificationsState>(
      'Harus menyaring notifikasi yang dibuat SEBELUM waktu clear massal',
      build: () {
        when(mockRepository.getLocalNotifications())
            .thenAnswer((_) async => [mockNotif1, mockNotif2]);
        
        when(mockRepository.getNotifications())
            .thenAnswer((_) async => (notifications: <NotificationDetails>[], currentPage: 1, totalPage: 1));

        when(mockRepository.getDeletedNotificationKeys())
            .thenAnswer((_) async => []);

        // Simulasi: Waktu pembersihan terakhir adalah 1.5 Januari
        // Jadi notif1 (1 Jan) harus hilang, notif2 (2 Jan) harus tetap ada.
        when(mockRepository.getLastClearedTimestamp())
            .thenAnswer((_) async => "2024-01-01 15:00:00");

        return cubit;
      },
      act: (cubit) => cubit.getLocalNotifications(),
      verify: (cubit) {
        final successState = cubit.state as LocalNotificationsFetchSuccess;
        expect(successState.notifications.length, 1);
        expect(successState.notifications.first.id, 2);
      },
    );
  });
}
