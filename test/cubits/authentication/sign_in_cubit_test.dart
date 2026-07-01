import 'package:bloc_test/bloc_test.dart';
import 'package:eschool_saas_staff/cubits/authentication/signInCubit.dart';
import 'package:eschool_saas_staff/data/models/auth/userDetails.dart';
import 'package:eschool_saas_staff/data/repositories/auth/authRepository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'sign_in_cubit_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late SignInCubit cubit;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    cubit = SignInCubit(mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('SignInCubit Tests', () {
    const email = 'teacher@eschool.com';
    const password = 'password123';
    
    final mockUser = UserDetails(
      id: 123,
      firstName: "Budi",
      lastName: "Guru",
      email: email,
    );

    test('Initial state harus SignInInitial', () {
      expect(cubit.state, isA<SignInInitial>());
    });

    blocTest<SignInCubit, SignInState>(
      'Harus emit [SignInInProgress, SignInSuccess] ketika login berhasil',
      build: () {
        when(mockRepository.loginUser(email: email, password: password))
            .thenAnswer((_) async => (
                  token: "mock_token_abc_123",
                  userDetails: mockUser,
                  responseJson: {"status": 200, "message": "Success"}
                ));
        return cubit;
      },
      act: (cubit) => cubit.signInUser(email: email, password: password),
      expect: () => [
        isA<SignInInProgress>(),
        isA<SignInSuccess>().having((s) => s.authToken, "Token harus sesuai", "mock_token_abc_123"),
      ],
      verify: (cubit) {
        verify(mockRepository.loginUser(email: email, password: password)).called(1);
      },
    );

    blocTest<SignInCubit, SignInState>(
      'Harus emit [SignInInProgress, SignInFailure] ketika login gagal',
      build: () {
        when(mockRepository.loginUser(email: email, password: password))
            .thenThrow(Exception("Email atau Password salah"));
        return cubit;
      },
      act: (cubit) => cubit.signInUser(email: email, password: password),
      expect: () => [
        isA<SignInInProgress>(),
        isA<SignInFailure>().having((s) => s.errorMessage, "Konten error harus sesuai", contains("Email atau Password salah")),
      ],
    );
  });
}
