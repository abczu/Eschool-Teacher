import 'package:eschool_saas_staff/data/models/violation/violationRoleCheck.dart';
import 'package:eschool_saas_staff/data/repositories/violation/violationRepository.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ViolationRoleCheckState {}

class ViolationRoleCheckInitial extends ViolationRoleCheckState {}

class ViolationRoleCheckInProgress extends ViolationRoleCheckState {}

class ViolationRoleCheckSuccess extends ViolationRoleCheckState {
  final ViolationRoleCheck roleCheck;

  ViolationRoleCheckSuccess(this.roleCheck);
}

class ViolationRoleCheckFailure extends ViolationRoleCheckState {
  final String errorMessage;

  ViolationRoleCheckFailure(this.errorMessage);
}

class ViolationRoleCheckCubit extends Cubit<ViolationRoleCheckState> {
  final ViolationRepository _violationRepository = ViolationRepository();

  ViolationRoleCheckCubit() : super(ViolationRoleCheckInitial());

  Future<void> checkRoles() async {
    try {
      emit(ViolationRoleCheckInProgress());
      final result = await _violationRepository.checkRoles();
      emit(ViolationRoleCheckSuccess(result));
    } catch (e) {
      emit(ViolationRoleCheckFailure(ErrorMessageUtils.getReadableErrorMessage(e)));
    }
  }
}
