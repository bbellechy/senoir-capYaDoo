class MedicationBox {
  final String? id;
  final String name;
  final String? description;
  final String? imagePath;
  final List<String> medicationIds;

  MedicationBox({
    this.id,
    required this.name,
    this.description,
    this.imagePath,
    this.medicationIds = const [],
  });

  factory MedicationBox.fromJson(Map<String, dynamic> json) {
    // Determine medication IDs:
    // If 'medications' array exists, extract IDs. Otherwise use 'medicationIds'.
    List<String> ids = [];
    if (json['medications'] != null && json['medications'] is List) {
      ids = (json['medications'] as List).map((e) {
        if (e is Map && e.containsKey('id')) return e['id'].toString();
        return e.toString();
      }).toList();
    } else if (json['medicationIds'] != null) {
      ids = (json['medicationIds'] as List).map((e) => e.toString()).toList();
    }

    return MedicationBox(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      imagePath: json['imagePath'],
      medicationIds: ids,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'imagePath': imagePath,
      'medicationIds': medicationIds,
    };
  }

  MedicationBox copyWith({
    String? id,
    String? name,
    String? description,
    String? imagePath,
    List<String>? medicationIds,
  }) {
    return MedicationBox(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      medicationIds: medicationIds ?? this.medicationIds,
    );
  }
}
