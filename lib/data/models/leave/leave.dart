import 'package:eschool_saas_staff/data/models/system/file.dart';
import 'package:eschool_saas_staff/data/models/leave/leaveRequest.dart';

class Leave {
  final int? id;
  final int? userId;
  final String? reason;
  final String? fromDate;
  final String? toDate;
  final int? status;
  final int? schoolId;
  final int? leaveMasterId;
  final String? createdAt;
  final String? updatedAt;
  final String? rejectionReason;
  final List<File>? file;
  final List<LeaveDetail>? leaveDetail;

  Leave(
      {this.id,
      this.userId,
      this.reason,
      this.fromDate,
      this.toDate,
      this.status,
      this.schoolId,
      this.leaveMasterId,
      this.createdAt,
      this.updatedAt,
      this.rejectionReason,
      this.file,
      this.leaveDetail});

  Leave copyWith(
      {int? id,
      int? userId,
      String? reason,
      String? fromDate,
      String? toDate,
      int? status,
      int? schoolId,
      int? leaveMasterId,
      String? createdAt,
      String? updatedAt,
      String? rejectionReason,
      List<File>? file,
      List<LeaveDetail>? leaveDetail}) {
    return Leave(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        reason: reason ?? this.reason,
        fromDate: fromDate ?? this.fromDate,
        toDate: toDate ?? this.toDate,
        status: status ?? this.status,
        schoolId: schoolId ?? this.schoolId,
        leaveMasterId: leaveMasterId ?? this.leaveMasterId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        rejectionReason: rejectionReason ?? this.rejectionReason,
        file: file ?? this.file,
        leaveDetail: leaveDetail ?? this.leaveDetail);
  }

  Leave.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        userId = json['user_id'] as int?,
        reason = json['reason'] as String?,
        fromDate = json['from_date'] as String?,
        toDate = json['to_date'] as String?,
        status = json['status'] as int?,
        schoolId = json['school_id'] as int?,
        leaveMasterId = json['leave_master_id'] as int?,
        createdAt = json['created_at'] as String?,
        updatedAt = json['updated_at'] as String?,
        rejectionReason = json['rejection_reason'] as String?,
        file = (() {
          final rawFiles = json['files'] ?? json['file'];
          // Use import-free print/debugPrint if available, standard dart print since foundation is not imported
          print("DEBUG Leave.fromJson - leaveId: ${json['id']} - rawFiles: $rawFiles (type: ${rawFiles?.runtimeType})");
          if (rawFiles != null) {
            if (rawFiles is List && rawFiles.isNotEmpty) {
              if (rawFiles[0] is List) {
                return (rawFiles[0] as List<dynamic>)
                    .map((e) => File.fromJson(e as Map<String, dynamic>))
                    .toList();
              } else {
                return (rawFiles as List<dynamic>)
                    .map((e) => File.fromJson(e as Map<String, dynamic>))
                    .toList();
              }
            } else if (rawFiles is Map) {
              return [File.fromJson(Map<String, dynamic>.from(rawFiles))];
            }
          }
          return null;
        })(),
        leaveDetail = ((json['leave_details'] ?? json['leave_detail']) as List<dynamic>?)
            ?.map((e) => LeaveDetail.fromJson(e as Map<String, dynamic>))
            .toList();

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'reason': reason,
        'from_date': fromDate,
        'to_date': toDate,
        'status': status,
        'school_id': schoolId,
        'leave_master_id': leaveMasterId,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'rejection_reason': rejectionReason
      };
}
