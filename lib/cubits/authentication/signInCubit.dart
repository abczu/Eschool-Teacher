import 'package:eschool_saas_staff/data/models/auth/userDetails.dart';
import 'package:eschool_saas_staff/data/repositories/auth/authRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

abstract class SignInState {}

class SignInInitial extends SignInState {}

class SignInInProgress extends SignInState {}

class SignInSuccess extends SignInState {
  final String authToken;
  final UserDetails userDetails;
  final Map<String, dynamic> responseJson;

  SignInSuccess({
    required this.authToken,
    required this.userDetails,
    required this.responseJson,
  });
}

class SignInFailure extends SignInState {
  final String errorMessage;

  SignInFailure(this.errorMessage);
}

class SignInCubit extends Cubit<SignInState> {
  final AuthRepository _authRepository;

  SignInCubit([AuthRepository? authRepository])
      : _authRepository = authRepository ?? AuthRepository(),
        super(SignInInitial());
  Future<void> signInUser({
    required String email,
    required String password,
  }) async {
    emit(SignInInProgress());

    try {
      final result = await _authRepository.loginUser(
        email: email,
        password: password,
      );
      emit(
        SignInSuccess(
          authToken: result.token,
          userDetails: result.userDetails,
          responseJson: result.responseJson,
        ),
      );
    } catch (e) {
      debugPrint("ERRORNYA PT 2");
      debugPrint(e.toString());
      emit(SignInFailure(e.toString()));
    }
  }
}
