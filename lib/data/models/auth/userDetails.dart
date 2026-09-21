import 'package:eschool_saas_staff/data/models/auth/additionalUserDetails.dart';
import 'package:eschool_saas_staff/data/models/auth/role.dart';
import 'package:eschool_saas_staff/data/models/academic/school.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';

class UserDetails {
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
  final String? emailVerifiedAt;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final String? fullName;
  final School? school;
  final AdditionalUserDetails? teacher;
  final AdditionalUserDetails? staff;
  final List<Role>? roles;

  UserDetails(
      {this.id,
      this.roles,
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
      this.emailVerifiedAt,
      this.createdAt,
      this.updatedAt,
      this.deletedAt,
      this.fullName,
      this.school,
      this.staff,
      this.teacher});

  UserDetails copyWith({
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
    String? emailVerifiedAt,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    String? fullName,
    School? school,
    AdditionalUserDetails? staff,
    AdditionalUserDetails? teacher,
    List<Role>? roles,
  }) {
    return UserDetails(
      id: id ?? this.id,
      roles: roles ?? this.roles,
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
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      fullName: fullName ?? this.fullName,
      school: school ?? this.school,
      staff: staff ?? this.staff,
      teacher: teacher ?? this.teacher,
    );
  }

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    // Flatten nested 'user' data if it exists
    Map<String, dynamic> data = json;
    if (json.containsKey('user') && json['user'] is Map) {
      data = {
        ...json,
        ...Map<String, dynamic>.from(json['user'] as Map),
      };
    }

    // Ensure we have school data with fallbacks for name and ID
    Map<String, dynamic> schoolMap = Map.from(data['school'] ?? {});
    if (schoolMap.isEmpty) {
      // Fallback for when school info is at the same level (e.g. login school list)
      schoolMap['id'] = data['school_id'] ?? json['id'];
      schoolMap['name'] = json['school_name'] ?? json['name'];
      schoolMap['code'] = json['school_code'];
    } else {
      // Ensure specific fields are prioritised from the top level if missing in nested school
      schoolMap['name'] ??= json['school_name'] ?? json['name'];
      schoolMap['id'] ??= data['school_id'];
    }

    return UserDetails(
      id: data['id'] as int?,
      firstName: data['first_name'] as String?,
      lastName: data['last_name'] as String?,
      mobile: data['mobile'] as String?,
      email: data['email'] as String?,
      gender: data['gender'] as String?,
      image: data['image'] as String?,
      dob: data['dob'] as String?,
      currentAddress: data['current_address'] as String?,
      permanentAddress: data['permanent_address'] as String?,
      occupation: data['occupation'] as String?,
      status: data['status'] as int?,
      resetRequest: data['reset_request'] as int?,
      fcmId: data['fcm_id'] as String?,
      schoolId: data['school_id'] as int?,
      emailVerifiedAt: data['email_verified_at'] as String?,
      createdAt: data['created_at'] as String?,
      updatedAt: data['updated_at'] as String?,
      deletedAt: data['deleted_at'] as String?,
      roles: ((data['roles'] ?? []) as List)
          .map((role) => Role.fromJson(Map.from(role ?? {})))
          .toList(),
      school: School.fromJson(schoolMap),
      teacher: AdditionalUserDetails.fromJson(Map.from(data['teacher'] ?? {})),
      staff: AdditionalUserDetails.fromJson(Map.from(data['staff'] ?? {})),
      fullName: data['full_name'] as String?,
    );
  }

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
        'email_verified_at': emailVerifiedAt,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
        'full_name': fullName,
        'school': school?.toJson(),
        'teacher': teacher?.toJson(),
        'staff': staff?.toJson(),
        'roles': roles?.map((e) => e.toJson()).toList()
      };

  bool isActive() {
    return (status == 1);
  }

  String getGender() {
    if (gender == "male") {
      return "Laki-Laki";
    }

    if (gender == "female") {
      return "Perempuan";
    }
    return gender ?? "-";
  }

  String getRoles() {
    return (roles ?? []).map((item) => item.name).toList().join(",");
  }

  bool isSchoolAdmin() {
    return (roles ?? [])
        .map((item) => item.name)
        .toList()
        .contains(schoolAdminRoleKey);
  }

  String getFullName() {
    final first = (firstName ?? "").trim();
    final last = (lastName ?? "").trim();
    final full = (fullName ?? "").trim();

    String rawName = "";
    if (first.isNotEmpty && last.isNotEmpty) {
      if (first.toLowerCase() == last.toLowerCase()) {
        rawName = first;
      } else if (first.toLowerCase().contains(last.toLowerCase())) {
        rawName = first;
      } else if (last.toLowerCase().contains(first.toLowerCase())) {
        rawName = last;
      } else {
        rawName = "$first $last";
      }
    } else if (first.isNotEmpty) {
      rawName = first;
    } else if (full.isNotEmpty) {
      rawName = full;
    } else if (last.isNotEmpty) {
      rawName = last;
    }

    if (rawName.isEmpty) return "";

    // Hapus pengulangan kata duplikat jika ada kata yang terulang
    final words = rawName.split(RegExp(r'\s+'));
    final seen = <String>{};
    final uniqueWords = <String>[];
    for (final w in words) {
      final lower = w.toLowerCase();
      if (!seen.contains(lower)) {
        seen.add(lower);
        uniqueWords.add(w);
      }
    }

    return uniqueWords.join(' ');
  }
}
