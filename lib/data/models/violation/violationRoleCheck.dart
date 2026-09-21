class HomeroomClass {
  final int classId;
  final String className;

  HomeroomClass({
    required this.classId,
    required this.className,
  });

  factory HomeroomClass.fromJson(Map<String, dynamic> json) {
    return HomeroomClass(
      classId: int.tryParse(json['class_id']?.toString() ?? '') ??
          int.tryParse(json['id']?.toString() ?? '') ??
          0,
      className: json['class_name']?.toString() ??
          json['name']?.toString() ??
          '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'class_name': className,
    };
  }
}

class ViolationRoleCheck {
  final bool isKesiswaan;
  final bool isHomeroom;
  final List<HomeroomClass> homeroomClasses;

  ViolationRoleCheck({
    this.isKesiswaan = false,
    this.isHomeroom = false,
    this.homeroomClasses = const [],
  });

  factory ViolationRoleCheck.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic val) {
      if (val == null) return false;
      if (val is bool) return val;
      if (val is num) return val == 1;
      final str = val.toString().toLowerCase().trim();
      return str == 'true' || str == '1';
    }

    final rawClasses = json['homeroom_classes'] ?? json['classes'];
    List<HomeroomClass> classes = [];
    if (rawClasses is List) {
      classes = rawClasses
          .map((e) => HomeroomClass.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return ViolationRoleCheck(
      isKesiswaan: parseBool(json['is_kesiswaan']),
      isHomeroom: parseBool(json['is_homeroom']),
      homeroomClasses: classes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_kesiswaan': isKesiswaan,
      'is_homeroom': isHomeroom,
      'homeroom_classes': homeroomClasses.map((e) => e.toJson()).toList(),
    };
  }
}
