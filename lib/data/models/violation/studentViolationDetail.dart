import 'package:eschool_saas_staff/data/models/violation/studentAvatarHelper.dart';
import 'package:eschool_saas_staff/data/models/violation/violationSanctionLevel.dart';

class ViolationRecord {
  final int id;
  final int? violationTypeId;
  final String violationName;
  final String category;
  final int points;
  final String incidentDate;
  final String? description;
  final String? notes;
  final String? photoUrl;
  final String? reportedByName;
  final String? createdAt;

  ViolationRecord({
    required this.id,
    this.violationTypeId,
    required this.violationName,
    required this.category,
    required this.points,
    required this.incidentDate,
    this.description,
    this.notes,
    this.photoUrl,
    this.reportedByName,
    this.createdAt,
  });

  factory ViolationRecord.fromJson(Map<String, dynamic> json) {
    // violation_type might be an object or flattened
    final vType = json['violation_type'] is Map ? json['violation_type'] : {};

    final vName = json['violation_name']?.toString() ??
        vType['name']?.toString() ??
        json['name']?.toString() ??
        'Pelanggaran';

    final cat = json['category']?.toString() ??
        vType['category']?.toString() ??
        'Ringan';

    final pts = int.tryParse(json['points']?.toString() ?? '') ??
        int.tryParse(vType['points']?.toString() ?? '') ??
        0;

    // Reporter (toleransi key web)
    final reporter = json['reporter'] is Map
        ? json['reporter']
        : (json['user'] is Map ? json['user'] : null);
    final repName = json['reporter_name']?.toString() ??
        json['reported_by_name']?.toString() ??
        json['reported_by']?.toString() ??
        reporter?['name']?.toString();

    // Incident Date parsing with multiple fallback keys
    final rawDate = json['occurred_at'] ??
        json['incident_date'] ??
        json['date'] ??
        json['violation_date'] ??
        json['incident_at'] ??
        json['tanggal'] ??
        json['created_at'] ??
        (json['pivot'] is Map
            ? (json['pivot']['occurred_at'] ?? json['pivot']['incident_date'] ?? json['pivot']['created_at'])
            : null);

    // Detail tiap riwayat = description jika ada else notes (samakan web)
    final desc = json['description']?.toString() ??
        json['desc']?.toString() ??
        json['deskripsi']?.toString() ??
        json['keterangan']?.toString();
    final noteVal = json['notes']?.toString() ?? json['chronology']?.toString();

    return ViolationRecord(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      violationTypeId: int.tryParse(json['violation_type_id']?.toString() ?? '') ??
          int.tryParse(vType['id']?.toString() ?? ''),
      violationName: vName,
      category: cat,
      points: pts,
      incidentDate: rawDate?.toString() ?? '',
      description: desc,
      notes: noteVal,
      photoUrl: json['photo_url']?.toString() ??
          json['photo']?.toString() ??
          json['image']?.toString(),
      reportedByName: repName,
      createdAt: json['created_at']?.toString(),
    );
  }

  /// Detail riwayat samakan web: description jika ada else notes.
  String? get detailText {
    if (description != null && description!.trim().isNotEmpty) {
      return description;
    }
    return notes;
  }

  /// Formatted date in Indonesian without relying on intl locale initialization
  String get formattedIncidentDate {
    if (incidentDate.trim().isEmpty) return "Tanggal tidak tercatat";
    try {
      final cleaned = incidentDate.trim().replaceAll('/', '-');
      final parsed = DateTime.tryParse(cleaned);
      if (parsed != null) {
        const months = [
          '',
          'Januari',
          'Februari',
          'Maret',
          'April',
          'Mei',
          'Juni',
          'Juli',
          'Agustus',
          'September',
          'Oktober',
          'November',
          'Desember'
        ];
        return "${parsed.day} ${months[parsed.month]} ${parsed.year}";
      }
    } catch (_) {}
    return incidentDate;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'violation_type_id': violationTypeId,
      'violation_name': violationName,
      'category': category,
      'points': points,
      'incident_date': incidentDate,
      'description': description,
      'notes': notes,
      'photo_url': photoUrl,
      'reported_by_name': reportedByName,
      'created_at': createdAt,
    };
  }
}

class StudentViolationDetail {
  final int studentId;
  final String studentName;
  final String? nisn;
  final String? nis;
  final String? admissionNo;
  final int? classId;
  final String? className;
  final int? rollNumber;
  final String? avatarUrl;
  final int totalPoints;
  final int totalViolations;
  final String? sanctionStatus;
  final String? sanctionLevel;
  final String? sanctionDescription;
  final String? actionType;
  final List<SanctionLevelConfig> sanctionLevels;
  final List<ViolationRecord> violations;

  StudentViolationDetail({
    required this.studentId,
    required this.studentName,
    this.nisn,
    this.nis,
    this.admissionNo,
    this.classId,
    this.className,
    this.rollNumber,
    this.avatarUrl,
    this.totalPoints = 0,
    this.totalViolations = 0,
    this.sanctionStatus,
    this.sanctionLevel,
    this.sanctionDescription,
    this.actionType,
    this.sanctionLevels = const [],
    this.violations = const [],
  });

  /// Teks identitas siswa: NISN -> NIS -> No. Pendaftaran.
  String? get identityText {
    if (nisn != null && nisn!.trim().isNotEmpty) {
      return "NISN: ${nisn!.trim()}";
    }
    if (nis != null && nis!.trim().isNotEmpty) {
      return "NIS: ${nis!.trim()}";
    }
    if (admissionNo != null && admissionNo!.trim().isNotEmpty) {
      return "No. Pendaftaran: ${admissionNo!.trim()}";
    }
    return null;
  }

  /// Level aktif sesuai alur web (rentang poin dinamis + fallback nama/action).
  /// null = Aman (0 poin / levels kosong / tidak cocok).
  SanctionLevelConfig? get activeSanction => SanctionLevelConfig.activeSanctionFor(
        sanctionLevels,
        totalPoints,
        sanctionLevel ?? sanctionStatus,
        actionType,
      );

  /// Nama level untuk UI: sanctionStatus kosong -> pakai nama level aktif.
  String get displaySanctionName {
    if (sanctionStatus != null && sanctionStatus!.trim().isNotEmpty) {
      return sanctionStatus!;
    }
    if (sanctionLevel != null && sanctionLevel!.trim().isNotEmpty) {
      return sanctionLevel!;
    }
    final active = activeSanction;
    if (active != null) return active.name;
    return 'Aman';
  }

  /// Deskripsi sanksi dari server (sanction_description).
  String? get displaySanctionDescription => sanctionDescription;

  /// Jenis tindakan dari server (action_type) atau level aktif.
  String? get displayActionType {
    if (actionType != null && actionType!.trim().isNotEmpty) return actionType;
    return activeSanction?.actionType;
  }

  String? get displayAvatarUrl =>
      avatarUrl ??
      StudentAvatarHelper.getAvatarUrl(
        studentId: studentId,
        studentName: studentName,
        classId: classId,
      );

  factory StudentViolationDetail.fromJson(Map<String, dynamic> json) {
    final studentData = json['student'] is Map ? json['student'] : json;
    final userData = studentData['user'] is Map ? studentData['user'] : studentData;

    final sId = int.tryParse(json['student_id']?.toString() ?? '') ??
        int.tryParse(studentData['id']?.toString() ?? '') ??
        int.tryParse(json['id']?.toString() ?? '') ??
        0;

    String sName = json['student_name']?.toString() ??
        studentData['name']?.toString() ??
        userData['name']?.toString() ??
        '';
    if (sName.isEmpty) {
      final first = (userData['first_name'] ?? studentData['first_name'] ?? '').toString();
      final last = (userData['last_name'] ?? studentData['last_name'] ?? '').toString();
      sName = "$first $last".trim();
    }

    final classSection = studentData['class_section'] ?? json['class_section'];
    String? cName;
    int? cId;
    if (classSection is Map) {
      cName = classSection['full_name']?.toString() ??
          classSection['name']?.toString() ??
          classSection['class_name']?.toString();
      cId = int.tryParse(classSection['id']?.toString() ?? '');
    } else {
      cName = json['class_name']?.toString() ??
          studentData['class_name']?.toString() ??
          json['class_section_name']?.toString();
      cId = int.tryParse(json['class_section_id']?.toString() ?? '') ??
          int.tryParse(studentData['class_section_id']?.toString() ?? '') ??
          int.tryParse(json['class_id']?.toString() ?? '') ??
          int.tryParse(studentData['class_id']?.toString() ?? '');
    }

    String? normalizeAvatar(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      if (s.isEmpty) return null;
      final lower = s.toLowerCase();
      if (lower == 'null' || lower == 'nil' || lower == '-') return null;
      if (lower.endsWith('default.png') || lower.endsWith('default.jpg')) {
        return null;
      }
      return s;
    }

    final pts = int.tryParse(json['total_points']?.toString() ?? '') ??
        int.tryParse(studentData['total_points']?.toString() ?? '') ??
        int.tryParse(json['points']?.toString() ?? '') ??
        0;

    // Riwayat: violations / violation_history / history / records (root atau data)
    final rawViolations = json['violations'] ??
        json['violation_history'] ??
        json['history'] ??
        json['records'] ??
        [];
    List<ViolationRecord> records = [];
    if (rawViolations is List) {
      records = rawViolations
          .map((e) => ViolationRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    // totalViolations fallback = jumlah violations
    final totalV = int.tryParse(json['total_violations']?.toString() ?? '') ??
        int.tryParse(studentData['total_violations']?.toString() ?? '') ??
        records.length;

    // sanction_levels dinamis (bisa di root/data, key alias sanctionLevels/levels)
    final rawLevels = json['sanction_levels'] ??
        json['sanctionLevels'] ??
        json['levels'] ??
        studentData['sanction_levels'] ??
        [];
    List<SanctionLevelConfig> levels = [];
    if (rawLevels is List) {
      levels = rawLevels
          .whereType<Map>()
          .map((e) => SanctionLevelConfig.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    String? pickStr(List<String> keys) {
      for (final k in keys) {
        final v = json[k] ?? studentData[k];
        if (v != null) {
          final s = v.toString().trim();
          if (s.isNotEmpty && s.toLowerCase() != 'null') return s;
        }
      }
      return null;
    }

    final sanctionLvl = pickStr(['sanction_level', 'sanctionLevel', 'level']);
    final sanctionDesc = pickStr(
        ['sanction_description', 'sanctionDescription', 'sanction_desc']);
    final actType = pickStr([
      'action_type',
      'actionType',
      'jenis_tindakan',
      'jenisTindakan',
      'tindakan',
      'action'
    ]);

    return StudentViolationDetail(
      studentId: sId,
      studentName: sName,
      nisn: (studentData['nisn'] ?? json['nisn'])?.toString(),
      nis: (studentData['nis'] ?? json['nis'])?.toString(),
      admissionNo: (studentData['admission_no'] ?? json['admission_no'])?.toString(),
      classId: cId,
      className: cName,
      rollNumber: int.tryParse((studentData['roll_number'] ?? json['roll_number'] ?? json['attendance_number'])?.toString() ?? ''),
      avatarUrl: normalizeAvatar(userData['image']) ??
          normalizeAvatar(userData['photo']) ??
          normalizeAvatar(userData['photo_url']) ??
          normalizeAvatar(userData['avatar']) ??
          normalizeAvatar(userData['profileUrl']) ??
          normalizeAvatar(userData['profile_url']) ??
          normalizeAvatar(studentData['image']) ??
          normalizeAvatar(studentData['photo']) ??
          normalizeAvatar(studentData['photo_url']) ??
          normalizeAvatar(studentData['avatar']) ??
          normalizeAvatar(studentData['profileUrl']) ??
          normalizeAvatar(studentData['profile_url']) ??
          normalizeAvatar(json['image']) ??
          normalizeAvatar(json['photo']) ??
          normalizeAvatar(json['photo_url']) ??
          normalizeAvatar(json['avatar']) ??
          normalizeAvatar(json['profileUrl']) ??
          normalizeAvatar(json['profile_url']),
      totalPoints: pts,
      totalViolations: totalV,
      sanctionStatus: json['sanction_status']?.toString() ??
          json['sanction_name']?.toString() ??
          json['status']?.toString() ??
          studentData['sanction_status']?.toString(),
      sanctionLevel: sanctionLvl,
      sanctionDescription: sanctionDesc,
      actionType: actType,
      sanctionLevels: levels,
      violations: records,
    );
  }
}
