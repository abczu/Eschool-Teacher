import 'dart:io';
import 'package:eschool_saas_staff/data/repositories/violation/violationRepository.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class GiveViolationPointsState {}

class GiveViolationPointsInitial extends GiveViolationPointsState {}

class GiveViolationPointsInProgress extends GiveViolationPointsState {}

class GiveViolationPointsSuccess extends GiveViolationPointsState {
  final Map<String, dynamic> response;

  GiveViolationPointsSuccess(this.response);
}

class GiveViolationPointsFailure extends GiveViolationPointsState {
  final String errorMessage;

  GiveViolationPointsFailure(this.errorMessage);
}

class GiveViolationPointsCubit extends Cubit<GiveViolationPointsState> {
  final ViolationRepository _violationRepository = ViolationRepository();

  GiveViolationPointsCubit() : super(GiveViolationPointsInitial());

  Future<void> submitViolationPoints({
    required int studentId,
    required int violationTypeId,
    required String incidentDate,
    String? notes,
    File? photo,
  }) async {
    try {
      emit(GiveViolationPointsInProgress());
      final result = await _violationRepository.giveViolationPoints(
        studentId: studentId,
        violationTypeId: violationTypeId,
        incidentDate: incidentDate,
        notes: notes,
        photo: photo,
      );
      emit(GiveViolationPointsSuccess(result));
    } catch (e) {
      emit(GiveViolationPointsFailure(
          ErrorMessageUtils.getReadableErrorMessage(e)));
    }
  }

  void reset() {
    emit(GiveViolationPointsInitial());
  }
}
