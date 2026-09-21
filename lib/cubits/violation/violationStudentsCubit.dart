import 'package:eschool_saas_staff/data/models/violation/studentViolationItem.dart';
import 'package:eschool_saas_staff/data/repositories/violation/violationRepository.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ViolationStudentsState {}

class ViolationStudentsInitial extends ViolationStudentsState {}

class ViolationStudentsFetchInProgress extends ViolationStudentsState {}

class ViolationStudentsFetchSuccess extends ViolationStudentsState {
  final List<StudentViolationItem> students;
  final bool isHomeroomView;
  final int total;
  final int currentPage;
  final int lastPage;
  final bool isLoadingMore;
  final bool hasMore;

  // Selected filters
  final int? selectedClassId;
  final String? selectedSortBy;
  final String? selectedFilter; // for homeroom: all, with_points, clean
  final String? searchQuery;

  ViolationStudentsFetchSuccess({
    required this.students,
    required this.isHomeroomView,
    this.total = 0,
    this.currentPage = 1,
    this.lastPage = 1,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.selectedClassId,
    this.selectedSortBy,
    this.selectedFilter,
    this.searchQuery,
  });

  ViolationStudentsFetchSuccess copyWith({
    List<StudentViolationItem>? students,
    bool? isHomeroomView,
    int? total,
    int? currentPage,
    int? lastPage,
    bool? isLoadingMore,
    bool? hasMore,
    int? selectedClassId,
    String? selectedSortBy,
    String? selectedFilter,
    String? searchQuery,
  }) {
    return ViolationStudentsFetchSuccess(
      students: students ?? this.students,
      isHomeroomView: isHomeroomView ?? this.isHomeroomView,
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      selectedClassId: selectedClassId ?? this.selectedClassId,
      selectedSortBy: selectedSortBy ?? this.selectedSortBy,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ViolationStudentsFetchFailure extends ViolationStudentsState {
  final String errorMessage;

  ViolationStudentsFetchFailure(this.errorMessage);
}

class ViolationStudentsCubit extends Cubit<ViolationStudentsState> {
  final ViolationRepository _violationRepository = ViolationRepository();

  ViolationStudentsCubit() : super(ViolationStudentsInitial());

  /// Fetch untuk Kesiswaan (Semua siswa satu sekolah dengan poin > 0)
  Future<void> getKesiswaanStudents({
    int? classSectionId,
    int? classId,
    String? sortBy, // highest_points / lowest_points / alphabetical / latest
    String? search,
    bool isRefresh = false,
  }) async {
    final targetClassSectionId = classSectionId ?? classId;
    try {
      if (!isRefresh) {
        emit(ViolationStudentsFetchInProgress());
      }

      final result = await _violationRepository.getAllStudentsViolations(
        classSectionId: targetClassSectionId,
        sortBy: sortBy ?? 'highest_points',
        search: search,
        page: 1,
        perPage: 20,
      );

      emit(ViolationStudentsFetchSuccess(
        students: result.students,
        isHomeroomView: false,
        total: result.total,
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        hasMore: result.currentPage < result.lastPage,
        selectedClassId: targetClassSectionId,
        selectedSortBy: sortBy ?? 'highest_points',
        searchQuery: search,
      ));
    } catch (e) {
      emit(ViolationStudentsFetchFailure(
          ErrorMessageUtils.getReadableErrorMessage(e)));
    }
  }

  /// Load more untuk Kesiswaan pagination
  Future<void> loadMoreKesiswaanStudents() async {
    if (state is! ViolationStudentsFetchSuccess) return;
    final currentState = state as ViolationStudentsFetchSuccess;
    if (currentState.isHomeroomView ||
        currentState.isLoadingMore ||
        !currentState.hasMore) {
      return;
    }

    try {
      emit(currentState.copyWith(isLoadingMore: true));
      final nextPage = currentState.currentPage + 1;

      final result = await _violationRepository.getAllStudentsViolations(
        classSectionId: currentState.selectedClassId,
        sortBy: currentState.selectedSortBy,
        search: currentState.searchQuery,
        page: nextPage,
        perPage: 20,
      );

      emit(currentState.copyWith(
        students: [...currentState.students, ...result.students],
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        hasMore: result.currentPage < result.lastPage,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  /// Fetch untuk Wali Kelas (Kelas perwalian)
  Future<void> getHomeroomStudents({
    int? classSectionId,
    int? classId,
    String? filter, // all / with_points / clean
    String? sortBy, // attendance_number / alphabetical / highest_points
    bool isRefresh = false,
  }) async {
    final targetClassSectionId = classSectionId ?? classId;
    try {
      if (!isRefresh) {
        emit(ViolationStudentsFetchInProgress());
      }

      final result = await _violationRepository.getHomeroomStudentsViolations(
        classSectionId: targetClassSectionId,
        filter: filter ?? 'all',
        sortBy: sortBy ?? 'attendance_number',
      );

      emit(ViolationStudentsFetchSuccess(
        students: result,
        isHomeroomView: true,
        total: result.length,
        currentPage: 1,
        lastPage: 1,
        hasMore: false,
        selectedClassId: targetClassSectionId,
        selectedFilter: filter ?? 'all',
        selectedSortBy: sortBy ?? 'attendance_number',
      ));
    } catch (e) {
      emit(ViolationStudentsFetchFailure(
          ErrorMessageUtils.getReadableErrorMessage(e)));
    }
  }
}
