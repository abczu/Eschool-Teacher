/// Model level sanksi DINAMIS dari server (samakan web).
/// Jangan hardcode rentang poin di app — semua batas dari `sanction_levels`.
class SanctionLevelConfig {
  final int id;
  final String name;
  final int minPoints;
  final int? maxPoints;
  final String actionType;
  final String description;

  const SanctionLevelConfig({
    this.id = 0,
    required this.name,
    required this.minPoints,
    this.maxPoints,
    this.actionType = '',
    this.description = '',
  });

  /// p >= min && (max == null || p <= max)
  bool contains(int p) => p >= minPoints && (maxPoints == null || p <= maxPoints!);

  /// "0–10 Poin" atau "≥ 85 Poin" saat max null (tanpa batas atas).
  String get displayRange {
    if (maxPoints == null) return '≥ $minPoints Poin';
    return '$minPoints–$maxPoints Poin';
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    final s = v.toString().trim().toLowerCase();
    if (s.isEmpty || s == 'null' || s == 'nil' || s == '-') return null;
    return int.tryParse(s);
  }

  factory SanctionLevelConfig.fromJson(Map<String, dynamic> json) {
    final name = _pickString(json, [
      'nama',
      'name',
      'level',
      'title',
    ], fallback: 'Level');
    final min = _pickInt(json, [
      'poin_minimum',
      'min_points',
      'minPoints',
      'poin_min',
      'minimum_poin',
      'min',
      'from',
    ]) ??
        0;
    final max = _pickInt(json, [
      'poin_maksimum',
      'max_points',
      'maxPoints',
      'poin_maks',
      'maksimum_poin',
      'max',
      'to',
      'up_to',
    ]);
    final action = _pickString(json, [
      'jenis_tindakan',
      'action_type',
      'actionType',
      'jenisTindakan',
      'tindakan',
      'action',
    ]);
    final desc = _pickString(json, [
      'deskripsi',
      'description',
      'desc',
      'keterangan',
    ]);
    return SanctionLevelConfig(
      id: _parseInt(json['id']) ?? 0,
      name: name,
      minPoints: min,
      maxPoints: max,
      actionType: action,
      description: desc,
    );
  }

  static String _pickString(Map<String, dynamic> json, List<String> keys,
      {String fallback = ''}) {
    for (final k in keys) {
      if (json.containsKey(k) && json[k] != null) {
        final s = json[k].toString().trim();
        if (s.isNotEmpty && s.toLowerCase() != 'null') return s;
      }
    }
    return fallback;
  }

  static int? _pickInt(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      if (json.containsKey(k)) {
        final v = _parseInt(json[k]);
        // null berarti key ada tapi unbounded (khusus max) -> kembalikan null
        // hanya untuk max; untuk min, null dianggap tidak ada -> lanjut.
        if (v != null) return v;
        // Jika value eksplisit null, anggap unbounded dan berhenti.
        if (json[k] == null) return null;
      }
    }
    return null;
  }

  /// Alur penentuan level aktif (wajib sama dengan web):
  /// 1) cari level pertama yang contains(totalPoints) (levels terurut min ASC)
  /// 2) fallback samakan nama persis (lowercase) dengan sanction_level API
  /// 3) fallback samakan action_type persis
  /// 4) levels kosong / tidak cocok -> null (caller anggap Aman, 0 poin)
  static SanctionLevelConfig? activeSanctionFor(
    List<SanctionLevelConfig> levels,
    int totalPoints,
    String? sanctionName,
    String? actionType,
  ) {
    if (levels.isEmpty) return null;
    final sorted = List<SanctionLevelConfig>.from(levels)
      ..sort((a, b) => a.minPoints.compareTo(b.minPoints));
    for (final l in sorted) {
      if (l.contains(totalPoints)) return l;
    }
    final sName = (sanctionName ?? '').trim().toLowerCase();
    if (sName.isNotEmpty) {
      for (final l in sorted) {
        if (l.name.trim().toLowerCase() == sName) return l;
      }
    }
    final aType = (actionType ?? '').trim().toLowerCase();
    if (aType.isNotEmpty) {
      for (final l in sorted) {
        if (l.actionType.trim().toLowerCase() == aType) return l;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': name,
        'poin_minimum': minPoints,
        'poin_maksimum': maxPoints,
        'jenis_tindakan': actionType,
        'deskripsi': description,
      };
}
