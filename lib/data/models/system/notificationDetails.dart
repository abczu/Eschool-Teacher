class NotificationDetails {
  final int? id;
  final String? title;
  final String? message;
  final String? image;
  final String? sendTo;
  final int? sessionYearId;
  final int? schoolId;
  final String? createdAt;
  final String? updatedAt;

  NotificationDetails({
    this.id,
    this.title,
    this.message,
    this.image,
    this.sendTo,
    this.sessionYearId,
    this.schoolId,
    this.createdAt,
    this.updatedAt,
  });

  NotificationDetails copyWith({
    int? id,
    String? title,
    String? message,
    String? image,
    String? sendTo,
    int? sessionYearId,
    int? schoolId,
    String? createdAt,
    String? updatedAt,
  }) {
    return NotificationDetails(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      image: image ?? this.image,
      sendTo: sendTo ?? this.sendTo,
      sessionYearId: sessionYearId ?? this.sessionYearId,
      schoolId: schoolId ?? this.schoolId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  NotificationDetails.fromJson(Map<String, dynamic> json)
      : id = int.tryParse(json['id']?.toString() ?? ""),
        title = json['title'] as String?,
        message = json['message'] as String?,
        image = json['image'] as String?,
        sendTo = json['send_to'] as String?,
        sessionYearId = int.tryParse(json['session_year_id']?.toString() ?? ""),
        schoolId = int.tryParse(json['school_id']?.toString() ?? ""),
        createdAt = json['created_at'] as String?,
        updatedAt = json['updated_at'] as String?;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'image': image,
        'send_to': sendTo,
        'session_year_id': sessionYearId,
        'school_id': schoolId,
        'created_at': createdAt,
        'updated_at': updatedAt
      };
}
