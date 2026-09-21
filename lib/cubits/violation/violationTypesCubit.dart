import 'package:eschool_saas_staff/data/models/violation/violationType.dart';
import 'package:eschool_saas_staff/data/repositories/violation/violationRepository.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ViolationTypesState {}

class ViolationTypesInitial extends ViolationTypesState {}

class ViolationTypesFetchInProgress extends ViolationTypesState {}

class ViolationTypesFetchSuccess extends ViolationTypesState {
  final List<ViolationType> violationTypes;

  ViolationTypesFetchSuccess(this.violationTypes);
}

class ViolationTypesFetchFailure extends ViolationTypesState {
  final String errorMessage;

  ViolationTypesFetchFailure(this.errorMessage);
}

class ViolationTypesCubit extends Cubit<ViolationTypesState> {
  final ViolationRepository _violationRepository = ViolationRepository();

  ViolationTypesCubit() : super(ViolationTypesInitial());

  Future<void> getViolationTypes() async {
    try {
      emit(ViolationTypesFetchInProgress());
      final result = await _violationRepository.getViolationTypes();
      emit(ViolationTypesFetchSuccess(result));
    } catch (e) {
      emit(ViolationTypesFetchFailure(ErrorMessageUtils.getReadableErrorMessage(e)));
    }
  }
}
