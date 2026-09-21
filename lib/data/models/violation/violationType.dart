class ViolationType {
  final int id;
  final String name;
  final String category; // Ringan, Sedang, Berat
  final int points;
  final String? description;

  ViolationType({
    required this.id,
    required this.name,
    required this.category,
    required this.points,
    this.description,
  });

  factory ViolationType.fromJson(Map<String, dynamic> json) {
    return ViolationType(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ??
          json['title']?.toString() ??
          json['violation_name']?.toString() ??
          '',
      category: json['category']?.toString() ??
          json['type']?.toString() ??
          'Ringan',
      points: int.tryParse(json['points']?.toString() ?? '') ??
          int.tryParse(json['point']?.toString() ?? '') ??
          0,
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'points': points,
      'description': description,
    };
  }
}
