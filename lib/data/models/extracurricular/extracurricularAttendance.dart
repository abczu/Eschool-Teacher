import '../../../utils/system/dateFormatter.dart';
import '../../../utils/system/jsonUtils.dart';
import 'package:flutter/foundation.dart';

// Enum untuk status kehadiran dengan validasi yang ketat
enum AttendanceStatus {
  absent(0, 'Tidak Hadir', 'Alpa'),
  present(1, 'Hadir', 'Present'),
  sick(2, 'Sakit', 'Sick'),
  permission(3, 'Izin', 'Permission');

  const AttendanceStatus(this.value, this.label, this.englishLabel);

  final int value;
  final String label;
  final String englishLabel;

  /// Parse integer ke AttendanceStatus dengan logging dan fallback
  static AttendanceStatus fromInt(int value) {
    switch (value) {
      case 0:
        debugPrint(
            ' [ATTENDANCE_STATUS] Parsed status: $value -> ${AttendanceStatus.absent.label}');
        return AttendanceStatus.absent;
      case 1:
        debugPrint(
            ' [ATTENDANCE_STATUS] Parsed status: $value -> ${AttendanceStatus.present.label}');
        return AttendanceStatus.present;
      case 2:
        debugPrint(
            ' [ATTENDANCE_STATUS] Parsed status: $value -> ${AttendanceStatus.sick.label}');
        return AttendanceStatus.sick;
      case 3:
        debugPrint(
            ' [ATTENDANCE_STATUS] Parsed status: $value -> ${AttendanceStatus.permission.label}');
        return AttendanceStatus.permission;
      default:
        debugPrint(
            ' [ATTENDANCE_STATUS] Unknown status value: $value, defaulting to present');
        return AttendanceStatus.present;
    }
  }

  /// Parse integer nullable dengan safe handling
  static AttendanceStatus? fromIntNullable(int? value) {
    if (value == null) {
      debugPrint(' [ATTENDANCE_STATUS] Status value is null');
      return null;
    }
    return fromInt(value);
  }

  /// Parse dari berbagai field name yang mungkin ada di JSON
  static AttendanceStatus fromJsonField(Map<String, dynamic> json) {
    // Coba berbagai field name yang mungkin
    final statusValue = json['status'] ??
        json['attendance_status'] ??
        json['attendance_type'] ??
        json['type'] ??
        1; // Default ke present

    if (statusValue is int) {
      return fromInt(statusValue);
    } else if (statusValue is String) {
      final intValue = int.tryParse(statusValue);
      if (intValue != null) {
        return fromInt(intValue);
      }
    }

    debugPrint(
        ' [ATTENDANCE_STATUS] Invalid status value: $statusValue, defaulting to present');
    return AttendanceStatus.present;
  }

  /// Validasi apakah status value valid
  static bool isValidStatusValue(int value) {
    return value >= 0 && value <= 3;
  }
}

// Model untuk data absensi ekstrakurikuler
class ExtracurricularAttendance {
  final int attendanceId; // ID record absensi
  final int studentId; // ID siswa (REQUIRED)
  final String studentName; // Nama siswa (REQUIRED)
  final String? studentNisn; // NISN siswa
  final String? className; // Nama kelas
  final AttendanceStatus status; // Status kehadiran (ENUM)
  final DateTime date; // Tanggal absensi (REQUIRED)
  final int? extracurricularId; // ID ekstrakurikuler
  final String? extracurricularName; // Nama ekstrakurikuler

  const ExtracurricularAttendance({
    required this.attendanceId,
    required this.studentId,
    required this.studentName,
    this.studentNisn,
    this.className,
    required this.status,
    required this.date,
    this.extracurricularId,
    this.extracurricularName,
  });

  // Factory constructor from JSON with proper error handling
  factory ExtracurricularAttendance.fromJson(Map<String, dynamic> json) {
    debugPrint(
        '🔍 [MODEL] Parsing ExtracurricularAttendance from JSON: ${json.toString()}');

    // Parse date using DateFormatter with robust error handling
    DateTime parsedDate;
    final dateString = json['date']?.toString();

    if (dateString != null && dateString.isNotEmpty) {
      final parsedFromApi = DateFormatter.fromApiFormat(dateString);
      if (parsedFromApi != null) {
        parsedDate = parsedFromApi;
        debugPrint(
            '🔍 [MODEL] Successfully parsed date: $dateString -> ${DateFormatter.toApiFormat(parsedDate)}');
      } else {
        debugPrint(
            '⚠️ [MODEL] Failed to parse date: $dateString, using current date');
        parsedDate = DateTime.now();
      }
    } else {
      debugPrint(
          '⚠️ [MODEL] Date is null/empty for attendance ID: ${json['attendance_id'] ?? json['id']}, using current date');
      parsedDate = DateTime.now();
    }

    // Parse status with fallback to Present if null/invalid
    AttendanceStatus parsedStatus;
    try {
      final statusValue =
          json['status'] ?? json['attendance_type'] ?? json['type'] ?? 1;
      parsedStatus = AttendanceStatus.fromInt(statusValue);
    } catch (e) {
      debugPrint(
          ' [MODEL] Failed to parse status: ${json['status']}, using Present as default');
      parsedStatus = AttendanceStatus.present;
    }

    // Validasi student_name terlebih dahulu
    final studentName =
        readText(json, ['student_name', 'name', 'studentName']) ??
            'Unknown Student';
    if (studentName == 'Unknown Student') {
      debugPrint(
          ' [MODEL] Student name not found, available fields: ${json.keys.toList()}');
    }

    // Validasi student_id - CRITICAL untuk mencegah id: 0
    // Debug: Print semua field yang tersedia untuk analisis
    debugPrint(' [MODEL] Available JSON fields: ${json.keys.toList()}');
    debugPrint(' [MODEL] Full JSON data: ${json.toString()}');

    // Coba berbagai kemungkinan field name untuk student_id
    int studentId = 0;

    // Prioritas pencarian field student_id
    final possibleStudentIdFields = [
      'student_id',
      'studentId',
      'siswa_id',
      'user_id',
      'member_id',
      'id'
    ];

    for (final field in possibleStudentIdFields) {
      final value = json[field];
      if (value != null) {
        if (value is int && value > 0) {
          studentId = value;
          debugPrint(
              ' [MODEL] Found valid student_id in field "$field": $studentId');
          break;
        } else if (value is String) {
          final parsedValue = int.tryParse(value);
          if (parsedValue != null && parsedValue > 0) {
            studentId = parsedValue;
            debugPrint(
                ' [MODEL] Found valid student_id in field "$field" (parsed from string): $studentId');
            break;
          }
        }
      }
    }

    if (studentId <= 0) {
      debugPrint(' [MODEL] CRITICAL: No valid student_id found!');
      debugPrint(' [MODEL] Available fields: ${json.keys.toList()}');
      debugPrint(' [MODEL] Field values:');
      for (final field in possibleStudentIdFields) {
        debugPrint('   - $field: ${json[field]} (${json[field].runtimeType})');
      }

      // Untuk debugging, gunakan attendance_id sebagai temporary student_id
      // HANYA untuk testing - ini bukan solusi final
      final tempId = json['attendance_id'] ?? json['id'] ?? 1;
      debugPrint(
          ' [MODEL] TEMPORARY: Using attendance_id as student_id for debugging: $tempId');
      studentId =
          tempId is int ? tempId : (int.tryParse(tempId.toString()) ?? 1);
    }

    final result = ExtracurricularAttendance(
      attendanceId: json['attendance_id'] ?? json['id'] ?? 0,
      studentId: studentId,
      studentName: studentName,
      // Field teks dibaca lewat readText agar aman terhadap nilai angka /
      // kosong (lihat lib/utils/system/jsonUtils.dart).
      studentNisn: readText(json, ['student_nisn', 'nisn']),
      className: readText(json, ['class_name', 'kelas', 'className']),
      status: parsedStatus,
      date: parsedDate,
      extracurricularId:
          json['extracurricular_id'] ?? json['ekstrakurikuler_id'],
      extracurricularName: readText(json, [
        'eskul_name',
        'extracurricular_name',
        'ekstrakurikuler_name',
      ]),
    );

    debugPrint('🔍 [MODEL] Created ExtracurricularAttendance: ${result.toString()}');
    return result;
  }

  // Convert to JSON using DateFormatter
  Map<String, dynamic> toJson() {
    final json = {
      'attendance_id': attendanceId,
      'student_id': studentId,
      'student_name': studentName,
      'student_nisn': studentNisn,
      'class_name': className,
      'status': status.value,
      'date':
          DateFormatter.toApiFormat(date), // Use DateFormatter for consistency
      'extracurricular_id': extracurricularId,
      'extracurricular_name': extracurricularName,
    };

    debugPrint('🔍 [MODEL] Converting to JSON: $json');
    return json;
  }

  /// Validasi internal sebelum digunakan untuk request
  bool isValid() {
    final isValid = studentId > 0 &&
        studentName.isNotEmpty &&
        studentName != 'Unknown Student' &&
        AttendanceStatus.isValidStatusValue(status.value);

    if (!isValid) {
      debugPrint(
          '❌ [MODEL] Invalid ExtracurricularAttendance: studentId=$studentId, name=$studentName, status=${status.value}');
    }

    return isValid;
  }

  // Helper methods for attendance status
  bool get isPresent => status == AttendanceStatus.present;
  bool get isAbsent => status == AttendanceStatus.absent;
  bool get isSick => status == AttendanceStatus.sick;
  bool get isPermission => status == AttendanceStatus.permission;

  String get statusText => status.label;
  String get statusEnglishText => status.englishLabel;
  int get statusValue => status.value;

  // Copy with method
  ExtracurricularAttendance copyWith({
    int? attendanceId,
    int? studentId,
    String? studentName,
    String? studentNisn,
    String? className,
    AttendanceStatus? status,
    DateTime? date,
    int? extracurricularId,
    String? extracurricularName,
  }) {
    return ExtracurricularAttendance(
      attendanceId: attendanceId ?? this.attendanceId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentNisn: studentNisn ?? this.studentNisn,
      className: className ?? this.className,
      status: status ?? this.status,
      date: date ?? this.date,
      extracurricularId: extracurricularId ?? this.extracurricularId,
      extracurricularName: extracurricularName ?? this.extracurricularName,
    );
  }

  @override
  String toString() {
    return 'ExtracurricularAttendance(attendanceId: $attendanceId, studentId: $studentId, studentName: $studentName, status: ${status.label}, date: ${date.toIso8601String().split('T')[0]})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExtracurricularAttendance &&
        other.attendanceId == attendanceId &&
        other.studentId == studentId &&
        other.status == status &&
        other.date == date;
  }

  @override
  int get hashCode {
    return attendanceId.hashCode ^
        studentId.hashCode ^
        status.hashCode ^
        date.hashCode;
  }
}

// Model untuk response API show attendance
class ExtracurricularAttendanceResponse {
  final int? attendanceId;
  final int? extracurricularId;
  final String? date;
  final List<ExtracurricularAttendance> members;

  const ExtracurricularAttendanceResponse({
    this.attendanceId,
    this.extracurricularId,
    this.date,
    required this.members,
  });

  factory ExtracurricularAttendanceResponse.fromJson(
      Map<String, dynamic> json) {
    debugPrint('🔍 [ATTENDANCE_RESPONSE] Full API response: ${json.toString()}');

    // Handle both possible response structures
    List<dynamic> membersList = [];

    // Try 'rows' first (actual API response), then 'data.members' (fallback)
    if (json['rows'] != null) {
      membersList = json['rows'] as List<dynamic>;
      debugPrint(
          '🔍 [ATTENDANCE_RESPONSE] Using rows structure, found ${membersList.length} members');
    } else {
      final data = json['data'] ?? {};
      membersList = data['members'] as List<dynamic>? ?? [];
      debugPrint(
          '🔍 [ATTENDANCE_RESPONSE] Using data.members structure, found ${membersList.length} members');
    }

    // Debug: Print first member structure if available
    if (membersList.isNotEmpty) {
      debugPrint(
          '🔍 [ATTENDANCE_RESPONSE] First member structure: ${membersList.first.toString()}');
    }

    return ExtracurricularAttendanceResponse(
      attendanceId: json['attendance_id'] ?? json['data']?['attendance_id'],
      extracurricularId:
          json['ekstrakurikuler_id'] ?? json['data']?['ekstrakurikuler_id'],
      date: json['date'] ?? json['data']?['date'],
      members: membersList
          .map((memberJson) => ExtracurricularAttendance.fromJson(memberJson))
          .toList(),
    );
  }
}

// Model untuk request save attendance
class ExtracurricularAttendanceRequest {
  final int extracurricularId;
  final String date; // Format DD-MM-YYYY
  final List<AttendanceData> attendanceData;

  const ExtracurricularAttendanceRequest({
    required this.extracurricularId,
    required this.date,
    required this.attendanceData,
  });

  Map<String, dynamic> toJson() {
    // Convert attendance data list to object with student_id as key
    final Map<String, dynamic> attendanceDataMap = {};

    for (final data in attendanceData) {
      attendanceDataMap[data.studentId.toString()] = {
        'id': data.studentId.toString(), // Convert to string as per API spec
        'type': data.type.toString(), // Convert to string as per API spec
      };
    }

    final json = {
      'ekstrakurikuler_id':
          extracurricularId.toString(), // Convert to string as per API spec
      'date': date, // Already in DD-MM-YYYY format
      'attendance_data': attendanceDataMap,
    };

    debugPrint(' [REQUEST] Final request body: ${json.toString()}');
    return json;
  }
}

class AttendanceData {
  final int studentId; // student id (CRITICAL: must not be 0)
  final int type; // 0=absent, 1=present, 2=sick, 3=permit

  const AttendanceData({
    required this.studentId,
    required this.type,
  });

  // Factory from ExtracurricularAttendance with validation
  factory AttendanceData.fromAttendance(ExtracurricularAttendance attendance) {
    if (!attendance.isValid()) {
      debugPrint(
          '❌ [ATTENDANCE_DATA] Creating from invalid ExtracurricularAttendance: ${attendance.toString()}');
    }

    final data = AttendanceData(
      studentId: attendance.studentId,
      type: attendance.status.value,
    );

    debugPrint('🔍 [ATTENDANCE_DATA] Created from attendance: ${data.toString()}');
    return data;
  }

  // Factory with validation
  factory AttendanceData.create({
    required int studentId,
    required int type,
  }) {
    if (studentId <= 0) {
      throw ArgumentError('Student ID must be greater than 0, got: $studentId');
    }

    if (!AttendanceStatus.isValidStatusValue(type)) {
      throw ArgumentError('Invalid attendance type: $type. Must be 0-3');
    }

    return AttendanceData(studentId: studentId, type: type);
  }

  Map<String, dynamic> toJson() {
    final json = {
      'student_id': studentId, // CRITICAL: use 'student_id' not 'id'
      'type': type,
    };

    debugPrint('🔍 [ATTENDANCE_DATA] Converting to JSON: $json');
    return json;
  }

  /// Validasi data sebelum dikirim ke API
  bool isValid() {
    final valid = studentId > 0 && AttendanceStatus.isValidStatusValue(type);
    if (!valid) {
      debugPrint(
          '❌ [ATTENDANCE_DATA] Invalid data: studentId=$studentId, type=$type');
    }
    return valid;
  }

  @override
  String toString() {
    return 'AttendanceData(studentId: $studentId, type: $type, status: ${AttendanceStatus.fromInt(type).label})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AttendanceData &&
        other.studentId == studentId &&
        other.type == type;
  }

  @override
  int get hashCode => studentId.hashCode ^ type.hashCode;
}

// Model untuk response save attendance
class ExtracurricularAttendanceSaveResponse {
  final bool success;
  final String message;
  final int? attendanceId;
  final int? savedCount;

  const ExtracurricularAttendanceSaveResponse({
    required this.success,
    required this.message,
    this.attendanceId,
    this.savedCount,
  });

  factory ExtracurricularAttendanceSaveResponse.fromJson(
      Map<String, dynamic> json) {
    final data = json['data'] ?? {};

    return ExtracurricularAttendanceSaveResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      attendanceId: data['attendance_id'],
      savedCount: data['saved_count'],
    );
  }
}
