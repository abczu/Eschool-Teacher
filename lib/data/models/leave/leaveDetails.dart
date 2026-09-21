import 'dart:convert';
import 'package:eschool_saas_staff/data/models/auth/role.dart';
import 'package:flutter/foundation.dart';

class LeaveDetails {
  final int? id;
  final int? leaveId;
  final String? date;
  final String? type;
  final int? schoolId;
  final String? leaveDate;
  final Leave? leave;
  final int? status;
  final String? statusLabel;
  final String? rejectionReason;
  final String? decidedAt;
  final String? requestedAt;

  LeaveDetails({
    this.id,
    this.leaveId,
    this.date,
    this.type,
    this.schoolId,
    this.leaveDate,
    this.leave,
    this.status,
    this.statusLabel,
    this.rejectionReason,
    this.decidedAt,
    this.requestedAt,
  });

  LeaveDetails copyWith({
    int? id,
    int? leaveId,
    String? date,
    String? type,
    int? schoolId,
    String? leaveDate,
    Leave? leave,
    int? status,
    String? statusLabel,
    String? rejectionReason,
    String? decidedAt,
    String? requestedAt,
  }) {
    return LeaveDetails(
      id: id ?? this.id,
      leaveId: leaveId ?? this.leaveId,
      date: date ?? this.date,
      type: type ?? this.type,
      schoolId: schoolId ?? this.schoolId,
      leaveDate: leaveDate ?? this.leaveDate,
      leave: leave ?? this.leave,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      decidedAt: decidedAt ?? this.decidedAt,
      requestedAt: requestedAt ?? this.requestedAt,
    );
  }

  LeaveDetails.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        leaveId = json['leave_id'] as int?,
        date = json['date'] as String?,
        type = json['type'] as String?,
        schoolId = json['school_id'] as int?,
        leaveDate = json['leave_date'] as String?,
        leave = (json['leave'] as Map<String, dynamic>?) != null
            ? Leave.fromJson(json['leave'] as Map<String, dynamic>)
            : null,
        status = json['status'] as int?,
        statusLabel = json['status_label'] as String?,
        rejectionReason = json['rejection_reason'] as String?,
        decidedAt = json['decided_at'] as String?,
        requestedAt = json['requested_at'] as String? {
    debugPrint('\n=== DEBUG: LeaveDetails.fromJson() ===');
    debugPrint('Parsing JSON:');
    debugPrint(const JsonEncoder.withIndent('  ').convert(json));
    debugPrint('Parsed data:');
    debugPrint('id: $id');
    debugPrint('leaveId: $leaveId');
    debugPrint('date: $date');
    debugPrint('type: $type');
    debugPrint('schoolId: $schoolId');
    debugPrint('leaveDate: $leaveDate');
    debugPrint('status: $status');
    debugPrint('statusLabel: $statusLabel');
    debugPrint('rejectionReason: $rejectionReason');
    debugPrint('decidedAt: $decidedAt');
    debugPrint('requestedAt: $requestedAt');
    debugPrint('leave: ${leave?.toJson()}');
    debugPrint('=== DEBUG: End LeaveDetails.fromJson() ===\n');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'leave_id': leaveId,
        'date': date,
        'type': type,
        'school_id': schoolId,
        'leave_date': leaveDate,
        'leave': leave?.toJson(),
        'status': status,
        'status_label': statusLabel,
        'rejection_reason': rejectionReason,
        'decided_at': decidedAt,
        'requested_at': requestedAt,
      };
}

class Leave {
  final int? id;
  final int? userId;
  final String? reason;
  final String? fromDate;
  final String? toDate;
  final int? status;
  final String? rejectionReason;
  final String? updatedAt;
  final String? createdAt;
  final User? user;
  final List<LeaveFile>? file;

  Leave({
    this.id,
    this.userId,
    this.reason,
    this.fromDate,
    this.toDate,
    this.status,
    this.rejectionReason,
    this.updatedAt,
    this.createdAt,
    this.user,
    this.file,
  });

  Leave copyWith({
    int? id,
    int? userId,
    String? reason,
    String? fromDate,
    String? toDate,
    int? status,
    String? rejectionReason,
    String? updatedAt,
    String? createdAt,
    User? user,
    List<LeaveFile>? file,
  }) {
    return Leave(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      reason: reason ?? this.reason,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      user: user ?? this.user,
      file: file ?? this.file,
    );
  }

  Leave.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        userId = json['user_id'] as int?,
        reason = json['reason'] as String?,
        fromDate = json['from_date'] as String?,
        toDate = json['to_date'] as String?,
        status = json['status'] as int?,
        rejectionReason = json['rejection_reason'] as String?,
        updatedAt = json['updated_at'] as String?,
        createdAt = json['created_at'] as String?,
        user = (json['user'] as Map<String, dynamic>?) != null
            ? User.fromJson(json['user'] as Map<String, dynamic>)
            : null,
        file = (json['file'] as List?)
            ?.map((f) => LeaveFile.fromJson(f as Map<String, dynamic>))
            .toList();

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'reason': reason,
        'from_date': fromDate,
        'to_date': toDate,
        'status': status,
        'rejection_reason': rejectionReason,
        'updated_at': updatedAt,
        'created_at': createdAt,
        'user': user?.toJson(),
        'file': file?.map((f) => f.toJson()).toList(),
      };
}

class User {
  final int? id;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? image;
  final List<Role>? roles;

  User(
      {this.id,
      this.firstName,
      this.lastName,
      this.fullName,
      this.image,
      this.roles});

  User copyWith(
      {int? id,
      String? firstName,
      String? lastName,
      String? fullName,
      String? image}) {
    return User(
      image: image ?? this.image,
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
    );
  }

  User.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        firstName = json['first_name'] as String?,
        lastName = json['last_name'] as String?,
        image = json['image'] as String?,
        roles = ((json['roles'] ?? []) as List)
            .map((role) => Role.fromJson(Map.from(role ?? {})))
            .toList(),
        fullName = json['full_name'] as String?;

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'full_name': fullName,
        'image': image
      };
}

class LeaveFile {
  final int? id;
  final int? modalId;
  final String? fileName;
  final String? fileUrl;
  final String? type;
  final String? fileExtension;
  final String? typeDetail;
  final String? youtubeUrlAction;

  LeaveFile({
    this.id,
    this.modalId,
    this.fileName,
    this.fileUrl,
    this.type,
    this.fileExtension,
    this.typeDetail,
    this.youtubeUrlAction,
  });

  LeaveFile copyWith({
    int? id,
    int? modalId,
    String? fileName,
    String? fileUrl,
    String? type,
    String? fileExtension,
    String? typeDetail,
    String? youtubeUrlAction,
  }) {
    return LeaveFile(
      id: id ?? this.id,
      modalId: modalId ?? this.modalId,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      type: type ?? this.type,
      fileExtension: fileExtension ?? this.fileExtension,
      typeDetail: typeDetail ?? this.typeDetail,
      youtubeUrlAction: youtubeUrlAction ?? this.youtubeUrlAction,
    );
  }

  LeaveFile.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        modalId = json['modal_id'] as int?,
        fileName = json['file_name'] as String?,
        fileUrl = json['file_url'] as String?,
        type = json['type'] as String?,
        fileExtension = json['file_extension'] as String?,
        typeDetail = json['type_detail'] as String?,
        youtubeUrlAction = json['youtube_url_action'] as String?;

  Map<String, dynamic> toJson() => {
        'id': id,
        'modal_id': modalId,
        'file_name': fileName,
        'file_url': fileUrl,
        'type': type,
        'file_extension': fileExtension,
        'type_detail': typeDetail,
        'youtube_url_action': youtubeUrlAction,
      };

  bool get isImage {
    if (fileExtension == null) return false;
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return imageExtensions.contains(fileExtension!.toLowerCase());
  }
}
