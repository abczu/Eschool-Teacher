import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/repositories/academics/academicRepository.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

abstract class ClassesState {}

class ClassesInitial extends ClassesState {}

class ClassesFetchInProgress extends ClassesState {}

class ClassesFetchSuccess extends ClassesState {
  final List<ClassSection> classes;
  final List<ClassSection> primaryClasses;

  ClassesFetchSuccess({required this.classes, required this.primaryClasses});
}

class ClassesFetchFailure extends ClassesState {
  final String errorMessage;

  ClassesFetchFailure(this.errorMessage);
}

class ClassesCubit extends Cubit<ClassesState> {
  final AcademicRepository _academicRepository = AcademicRepository();

  ClassesCubit() : super(ClassesInitial());

  void getClasses({bool forceRefresh = false}) async {
    // Prevent redundant fetching if already successful and not forced
    if (!forceRefresh && state is ClassesFetchSuccess) {
      return;
    }

    try {
      emit(ClassesFetchInProgress());
      final result = await _academicRepository.getClasses();
      emit(ClassesFetchSuccess(
          classes: result.classes, primaryClasses: result.primaryClasses));
    } catch (e) {
      debugPrint("Error fetching classes: $e"); // Debug log
      final userFriendlyMessage = ErrorMessageUtils.getReadableErrorMessage(e);
      emit(ClassesFetchFailure(userFriendlyMessage));
      debugPrint(
          'Technical error: ${ErrorMessageUtils.getTechnicalErrorMessage(e)}');
    }
  }

  List<ClassSection> getAllClasses() {
    if (state is ClassesFetchSuccess) {
      final currentState = state as ClassesFetchSuccess;

      // Gabungkan primaryClasses dan classes
      final allClasses = [
        ...currentState.primaryClasses,
        ...currentState.classes
      ];

      return allClasses;
    }
    return [];
  }
}
