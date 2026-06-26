import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/repositories/academics/teacherAcademicRepository.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

abstract class TeacherClassSectionDetailsState {}

class TeacherClassSectionDetailsInitial
    extends TeacherClassSectionDetailsState {}

class TeacherClassSectionDetailsFetchInProgress
    extends TeacherClassSectionDetailsState {}

class TeacherClassSectionDetailsFetchSuccess
    extends TeacherClassSectionDetailsState {
  final List<ClassSection> classSectionDetails;

  TeacherClassSectionDetailsFetchSuccess({required this.classSectionDetails});
}

class TeacherClassSectionDetailsFetchFailure
    extends TeacherClassSectionDetailsState {
  final String errorMessage;
  TeacherClassSectionDetailsFetchFailure(this.errorMessage);
}

class TeacherClassSectionDetailsCubit
    extends Cubit<TeacherClassSectionDetailsState> {
  final TeacherAcademicsRepository _teacherAcademicsRepository =
      TeacherAcademicsRepository();

  TeacherClassSectionDetailsCubit()
      : super(TeacherClassSectionDetailsInitial());

  void getTeacherClassSectionDetails({int? classId, int? gradeLevelId}) async {
    try {
      emit(TeacherClassSectionDetailsFetchInProgress());
      emit(TeacherClassSectionDetailsFetchSuccess(
          classSectionDetails:
              await _teacherAcademicsRepository.getClassSectionDetails(
                  classId: classId, gradeLevelId: gradeLevelId)));
    } catch (e) {
      final userFriendlyMessage = ErrorMessageUtils.getReadableErrorMessage(e);
      emit(TeacherClassSectionDetailsFetchFailure(userFriendlyMessage));
      debugPrint(
          'Technical error: ${ErrorMessageUtils.getTechnicalErrorMessage(e)}');
    }
  }
}
