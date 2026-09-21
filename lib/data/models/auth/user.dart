class User {
  final int? id;
  final String? firstName;
  final String? lastName;
  final String? image;
  final String? fullName;
  final String? schoolNames;
  final String? role;
  final Student? student;

  User({
    this.id,
    this.firstName,
    this.lastName,
    this.image,
    this.fullName,
    this.schoolNames,
    this.role,
    this.student,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      image: json['image'] as String?,
      fullName: json['full_name'] as String?,
      schoolNames: json['school_names'] as String?,
      role: json['role'] as String?,
      student: json['student'] == null
          ? null
          : Student.fromJson(json['student'] as Map<String, dynamic>),
    );
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'image': image,
        'full_name': fullName,
        'school_names': schoolNames,
        'role': role,
        'student': student?.toJson(),
      };
}

class Student {
  final int? id;
  final int? userId;
  final int? rollNumber;
  final String? firstName;
  final String? lastName;
  final String? fullName;

  Student({
    this.id,
    this.userId,
    this.rollNumber,
    this.firstName,
    this.lastName,
    this.fullName,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      rollNumber: json['roll_number'] as int?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      fullName: json['full_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'roll_number': rollNumber,
        'first_name': firstName,
        'last_name': lastName,
        'full_name': fullName,
      };
}
