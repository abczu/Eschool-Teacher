
import 'package:eschool_saas_staff/data/models/exam/offlineExamSubjectResult.dart';
import 'package:eschool_saas_staff/data/models/fee/paidFeeDetails.dart';
import 'package:eschool_saas_staff/data/models/fee/payment.dart';
import 'package:eschool_saas_staff/data/models/student/student.dart';
import 'package:flutter/foundation.dart';

class StudentDetails {
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
  final Student? student;
  final ClassSection? classSection;
  final PaymentStatus? paymentStatus;
  final List<OfflineExamSubjectResult>? offlineExamMarks;
  final List<ExamMarks>? examMarks;
  final PaidFeeDetails? paidFeeDetails;
  final String? profileUrl;
  final String? rollNumber;
  final List<PaymentHistory>? paymentHistory;

  StudentDetails({
    this.id,
    this.student,
    this.firstName,
    this.lastName,
    this.mobile,
    this.paidFeeDetails,
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
    this.offlineExamMarks,
    this.examMarks,
    this.profileUrl,
    this.rollNumber,
    this.classSection,
    this.paymentStatus,
    this.paymentHistory,
  });

  StudentDetails copyWith({
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
    Student? student,
    String? profileUrl,
    String? rollNumber,
    ClassSection? classSection,
    PaymentStatus? paymentStatus,
    List<PaymentHistory>? paymentHistory,
  }) {
    return StudentDetails(
      id: id ?? this.id,
      student: student ?? this.student,
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
      profileUrl: profileUrl ?? this.profileUrl,
      rollNumber: rollNumber ?? this.rollNumber,
      classSection: classSection ?? this.classSection,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentHistory: paymentHistory ?? this.paymentHistory,
    );
  }

  factory StudentDetails.fromJson(Map<String, dynamic> json) {

   
    
    int? parsedStatus;
    if (json['status'] is int) {
      parsedStatus = json['status'] as int;
    } else {
      parsedStatus = int.tryParse(json['status']?.toString() ?? '');
    }
    debugPrint("Parsed status: $parsedStatus");

    // Handle new API format with class_section and payment_status
    ClassSection? classSection;
    if (json.containsKey('class_section')) {
      classSection = ClassSection.fromJson(
          Map<String, dynamic>.from(json['class_section'] ?? {}));
    }

    PaymentStatus? paymentStatus;
    if (json.containsKey('payment_status')) {
      paymentStatus = PaymentStatus.fromJson(
          Map<String, dynamic>.from(json['payment_status'] ?? {}));
    }

    List<PaymentHistory> paymentHistory = [];
    if (json.containsKey('payment_history')) {
      if (json['payment_history'] is List) {
        // Handle case where payment_history is a List (as expected)
        paymentHistory = (json['payment_history'] as List)
            .map((item) =>
                PaymentHistory.fromJson(Map<String, dynamic>.from(item ?? {})))
            .toList();
      } else if (json['payment_history'] is Map) {
        // Handle case where payment_history is a Map (not a List as expected)
        try {
          // If it's a map with numeric keys (like {0: {...}, 1: {...}}), try to extract values
          final Map<String, dynamic> paymentMap =
              Map<String, dynamic>.from(json['payment_history']);

          // Convert map values to a list if possible
          final values = paymentMap.values.toList();
          if (values.isNotEmpty) {
            paymentHistory = values
                .map((item) => PaymentHistory.fromJson(
                    Map<String, dynamic>.from(item ?? {})))
                .toList();
          }
        } catch (e) {
          // If any error occurs during conversion, just leave paymentHistory empty
          debugPrint("Error parsing payment_history in StudentDetails: $e");
        }
      }
    }

    // Create legacy PaidFeeDetails from new payment_status and payment_history if needed
    PaidFeeDetails? paidFeeDetails;
    if (json.containsKey('fees_paid')) {
      paidFeeDetails = PaidFeeDetails.fromJson(
          Map<String, dynamic>.from(json['fees_paid'] ?? {}));
    } else if (paymentStatus != null) {
      // Create a PaidFeeDetails from the new format
      paidFeeDetails = PaidFeeDetails(
        id: json['id'] as int?,
        feesId: json['fees_id'] as int?,
        studentId: json['id'] as int?,
        isFullyPaid: paymentStatus.isFullyPaid,
        totalAmount: paymentStatus.totalAmount,
        paidAmount: paymentStatus.paidAmount,
        remainingAmount: paymentStatus.remainingAmount,
        paymentHistory: paymentHistory,
      );
    }

    return StudentDetails(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? ''),
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      mobile: json['mobile']?.toString(),
      email: json['email']?.toString(),
      gender: json['gender']?.toString(),
      image: json['image']?.toString(),
      dob: json['dob']?.toString(),
      currentAddress: json['current_address']?.toString(),
      permanentAddress: json['permanent_address']?.toString(),
      occupation: json['occupation']?.toString(),
      status: json['status'] is int
          ? json['status'] as int
          : int.tryParse(json['status']?.toString() ?? ''),
      resetRequest: json['reset_request'] is int
          ? json['reset_request'] as int
          : int.tryParse(json['reset_request']?.toString() ?? ''),
      fcmId: json['fcm_id']?.toString(),
      schoolId: json['school_id'] is int
          ? json['school_id'] as int
          : int.tryParse(json['school_id']?.toString() ?? ''),
      language: json['language']?.toString(),
      emailVerifiedAt: json['email_verified_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      deletedAt: json['deleted_at']?.toString(),
      fullName: json['name']?.toString() ?? json['full_name']?.toString(),
      offlineExamMarks: ((json['exam_marks'] ?? []) as List)
          .map((offlineExamSubjectResult) => OfflineExamSubjectResult.fromJson(
              Map<String, dynamic>.from(offlineExamSubjectResult ?? {})))
          .toList(),
      student: json.containsKey('student')
          ? Student.fromJson(Map<String, dynamic>.from(json['student'] ?? {}))
          : null,
      schoolNames: json['school_names']?.toString(),
      paidFeeDetails: paidFeeDetails,
      examMarks: ((json['marks'] ?? []) as List)
          .map<ExamMarks>(
              (e) => ExamMarks.fromJson(Map<String, dynamic>.from(e ?? {})))
          .toList(),
      profileUrl: json['profileUrl']?.toString(),
      rollNumber:
          json['roll_number']?.toString() ?? json['rollNumber']?.toString(),
      classSection: classSection,
      paymentStatus: paymentStatus,
      paymentHistory: paymentHistory,
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
        'language': language,
        'email_verified_at': emailVerifiedAt,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
        'full_name': fullName,
        'school_names': schoolNames,
        'student': student?.toJson(),
        'profileUrl': profileUrl,
        'rollNumber': rollNumber,
      };

  @override
  String toString() {
    return 'StudentDetails(id: $id, firstName: $firstName, lastName: $lastName, rollNumber: $rollNumber)';
  }

  String get cleanFullName {
    final name = (fullName != null && fullName!.trim().isNotEmpty)
        ? fullName!
        : '${firstName ?? ''} ${lastName ?? ''}';
    return name.trim();
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

  bool isActive() {
    debugPrint("Student status check:");
    debugPrint("Status value: $status");
    debugPrint("Status type: ${status.runtimeType}");
    
    // Jika status null, kemungkinan ada masalah dengan API atau parsing
    if (status == null) {
      debugPrint("WARNING: Student status is null - check API response");
      return false; // Default ke non-aktif jika tidak ada data status
    }

    // debugPrint(">///<");
    // debugPrint(status.toString());
    
    // Status 1 = aktif, 0 = non-aktif
    bool isActiveStatus = (status == 1);
    debugPrint("Is student active: $isActiveStatus");
    return isActiveStatus;
  }
}

//For offline exam existing marks
class ExamMarks {
  int id;
  int examTimetableId;
  int studentId;
  int obtainedMarks;

  ExamMarks(
      {required this.id,
      required this.examTimetableId,
      required this.studentId,
      required this.obtainedMarks});

  factory ExamMarks.fromJson(Map json) {
    return ExamMarks(
        id: json['id'] ?? 0,
        examTimetableId: json['exam_timetable_id'] ?? 0,
        studentId: json['student_id'] ?? 0,
        obtainedMarks: json['obtained_marks'] ?? 0);
  }
}

