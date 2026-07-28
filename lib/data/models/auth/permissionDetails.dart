import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/models/leave/leave.dart';
import 'package:eschool_saas_staff/data/models/system/file.dart';
import 'package:eschool_saas_staff/data/models/leave/leaveRequest.dart';

class PermissionDetails {
  final int? id;
  final int? userId;
  final int? classSectionId;
  final String? admissionNo;
  final int? rollNumber;
  final String? admissionDate;
  final int? schoolId;
  final int? guardianId;
  final int? sessionYearId;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final User? user;
  final List<Leave> leaves;

  PermissionDetails({
    this.id,
    this.userId,
    this.classSectionId,
    this.admissionNo,
    this.rollNumber,
    this.admissionDate,
    this.schoolId,
    this.guardianId,
    this.sessionYearId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.firstName,
    this.lastName,
    this.fullName,
    this.user,
    required this.leaves,
  });

  PermissionDetails copyWith({
    int? id,
    int? userId,
    int? classSectionId,
    String? admissionNo,
    int? rollNumber,
    String? admissionDate,
    int? schoolId,
    int? guardianId,
    int? sessionYearId,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    String? firstName,
    String? lastName,
    String? fullName,
    User? user,
    List<Leave>? leaves,
    ClassSection? classSection,
  }) {
    return PermissionDetails(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      classSectionId: classSectionId ?? this.classSectionId,
      admissionNo: admissionNo ?? this.admissionNo,
      rollNumber: rollNumber ?? this.rollNumber,
      admissionDate: admissionDate ?? this.admissionDate,
      schoolId: schoolId ?? this.schoolId,
      guardianId: guardianId ?? this.guardianId,
      sessionYearId: sessionYearId ?? this.sessionYearId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
      user: user ?? this.user,
      leaves: leaves ?? this.leaves,
    );
  }

  // Fungsi untuk menerjemahkan tipe cuti
  String translateLeaveType(String? leaveType) {
    final Map<String, String> leaveTranslations = {
      "fullDay": "Sehari Penuh",
      "firstHalf": "Paruh Pertama",
      "secondHalf": "Paruh Kedua",
    };
    return leaveTranslations[leaveType] ?? leaveType ?? '';
  }

  PermissionDetails.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        userId = json['leave_id'] as int?,
        classSectionId = json['class_section_id'] as int?,
        admissionNo = json['admission_no'] as String?,
        rollNumber = json['roll_number'] as int?,
        admissionDate = json['admission_date'] as String?,
        schoolId = json['school_id'] as int?,
        guardianId = json['guardian_id'] as int?,
        sessionYearId = json['session_year_id'] as int?,
        createdAt = json['created_at'] as String?,
        updatedAt = json['updated_at'] as String?,
        deletedAt = json['deleted_at'] as String?,
        firstName = json['first_name'] as String?,
        lastName = json['last_name'] as String?,
        fullName = json['full_name'] as String?,
        user = (json['user'] as Map<String, dynamic>?) != null
            ? User.fromJson(json['user'] as Map<String, dynamic>)
            : null,
        leaves = (json['leaves'] as List<dynamic>?)
                ?.map((leave) => Leave.fromJson(leave as Map<String, dynamic>))
                .toList() ??
            [];

  // Alternative constructor for direct API data structure
  PermissionDetails.fromApiData(Map<String, dynamic> json)
      : id = json['student_id'] as int?,
        userId = json['user_id'] as int?,
        classSectionId = json['class_section_id'] as int?,
        admissionNo = null,
        rollNumber = json['roll_number'] as int?,
        admissionDate = null,
        schoolId = json['school_id'] as int?,
        guardianId = null,
        sessionYearId = null,
        createdAt = null,
        updatedAt = null,
        deletedAt = null,
        firstName = json['student_name'] as String?,
        lastName = null,
        fullName = json['student_name'] as String?,
        user = User(
          id: json['user_id'] as int?,
          firstName: json['student_name'] as String?,
          lastName: null,
          fullName: json['student_name'] as String?,
          image: json['image'] as String?,
          mobile: null,
          email: null,
          gender: null,
          dob: null,
          currentAddress: null,
          permanentAddress: null,
          occupation: null,
          createdAt: null,
          updatedAt: null,
        ),
        leaves = [
          Leave(
            id: json['leave_id'] as int?,
            userId: json['user_id'] as int?,
            reason: json['reason'] as String?,
            fromDate: json['from_date'] as String?,
            toDate: json['to_date'] as String?,
            status: json['status'] as int?,
            schoolId: json['school_id'] as int?,
            leaveMasterId: null,
            createdAt: null,
            updatedAt: null,
            file: (() {
              final rawFiles = json['files'] ?? json['file'];
              print("DEBUG PermissionDetails.fromApiData - leaveId: ${json['leave_id']} - rawFiles: $rawFiles (type: ${rawFiles?.runtimeType})");
              if (rawFiles != null) {
                if (rawFiles is List && rawFiles.isNotEmpty) {
                  if (rawFiles[0] is List) {
                    return (rawFiles[0] as List<dynamic>)
                        .map((fileData) => File.fromJson(fileData as Map<String, dynamic>))
                        .toList();
                  } else {
                    return (rawFiles as List<dynamic>)
                        .map((fileData) => File.fromJson(fileData as Map<String, dynamic>))
                        .toList();
                  }
                } else if (rawFiles is Map) {
                  return [File.fromJson(Map<String, dynamic>.from(rawFiles))];
                }
              }
              return null;
            })(),
            leaveDetail: ((json['leave_details'] ?? json['leave_detail']) as List<dynamic>?)
                ?.map((detail) =>
                    LeaveDetail.fromJson(detail as Map<String, dynamic>))
                .toList(),
          )
        ];

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'class_section_id': classSectionId,
        'admission_no': admissionNo,
        'roll_number': rollNumber,
        'admission_date': admissionDate,
        'school_id': schoolId,
        'guardian_id': guardianId,
        'session_year_id': sessionYearId,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
        'first_name': firstName,
        'last_name': lastName,
        'full_name': fullName,
        'user': user?.toJson(),
        'leaves': leaves.map((leave) => leave.toJson()).toList(),
      };
}

class User {
  final int? id;
  final String? firstName;
  final String? lastName;
  final String? mobile;
  final String? email;
  final String? gender;
  final String? image;
  final String? dob;
  final String? currentAddress;
  final String? permanentAddress;
  final String? occupation;
  final int? status;
  final int? resetRequest;
  final String? fcmId;
  final int? schoolId;
  final String? language;
  final String? emailVerifiedAt;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final String? fullName;
  final String? schoolNames;
  final String? role;

  User({
    this.id,
    this.firstName,
    this.lastName,
    this.mobile,
    this.email,
    this.gender,
    this.image,
    this.dob,
    this.currentAddress,
    this.permanentAddress,
    this.occupation,
    this.status,
    this.resetRequest,
    this.fcmId,
    this.schoolId,
    this.language,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.fullName,
    this.schoolNames,
    this.role,
  });

  User copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? mobile,
    String? email,
    String? gender,
    String? image,
    String? dob,
    String? currentAddress,
    String? permanentAddress,
    String? occupation,
    int? status,
    int? resetRequest,
    String? fcmId,
    int? schoolId,
    String? language,
    String? emailVerifiedAt,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    String? fullName,
    String? schoolNames,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      image: image ?? this.image,
      dob: dob ?? this.dob,
      currentAddress: currentAddress ?? this.currentAddress,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      occupation: occupation ?? this.occupation,
      status: status ?? this.status,
      resetRequest: resetRequest ?? this.resetRequest,
      fcmId: fcmId ?? this.fcmId,
      schoolId: schoolId ?? this.schoolId,
      language: language ?? this.language,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      fullName: fullName ?? this.fullName,
      schoolNames: schoolNames ?? this.schoolNames,
      role: role ?? this.role,
    );
  }

  User.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        firstName = json['first_name'] as String?,
        lastName = json['last_name'] as String?,
        mobile = json['mobile'] as String?,
        email = json['email'] as String?,
        gender = json['gender'] as String?,
        image = json['image'] as String?,
        dob = json['dob'] as String?,
        currentAddress = json['current_address'] as String?,
        permanentAddress = json['permanent_address'] as String?,
        occupation = json['occupation'] as String?,
        status = json['status'] as int?,
        resetRequest = json['reset_request'] as int?,
        fcmId = json['fcm_id'] as String?,
        schoolId = json['school_id'] as int?,
        language = json['language'] as String?,
        emailVerifiedAt = json['email_verified_at'] as String?,
        createdAt = json['created_at'] as String?,
        updatedAt = json['updated_at'] as String?,
        deletedAt = json['deleted_at'] as String?,
        fullName = json['full_name'] as String?,
        schoolNames = json['school_names'] as String?,
        role = json['role'] as String?;

  Map<String, dynamic> toJson() => {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'mobile': mobile,
        'email': email,
        'gender': gender,
        'image': image,
        'dob': dob,
        'current_address': currentAddress,
        'permanent_address': permanentAddress,
        'occupation': occupation,
        'status': status,
        'reset_request': resetRequest,
        'fcm_id': fcmId,
        'school_id': schoolId,
        'language': language,
        'email_verified_at': emailVerifiedAt,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
        'full_name': fullName,
        'school_names': schoolNames,
        'role': role,
      };
}
