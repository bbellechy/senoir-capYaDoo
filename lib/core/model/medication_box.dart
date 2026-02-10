class MedicationBox {
  final String? id;
  final String name;
  final String? description;
  final String? imagePath;
  final List<String> medicationIds;
  final List<Map<String, dynamic>> medications; // Store medications array from API
  final List<int> days;
  final List<String> intakePeriods;
  final String? intakeTiming;

  MedicationBox({
    this.id,
    required this.name,
    this.description,
    this.imagePath,
    this.medicationIds = const [],
    this.medications = const [],
    this.days = const [],
    this.intakePeriods = const [],
    this.intakeTiming,
  });

  factory MedicationBox.fromJson(Map<String, dynamic> json) {
    // Determine medication IDs:
    // If 'medications' array exists, extract IDs. Otherwise use 'medicationIds'.
    List<String> ids = [];
    List<Map<String, dynamic>> medicationsList = [];
    
    if (json['medications'] != null && json['medications'] is List) {
      final medsList = json['medications'] as List;
      medicationsList = medsList.map((e) {
        if (e is Map<String, dynamic>) {
          return Map<String, dynamic>.from(e);
        }
        return <String, dynamic>{};
      }).toList();
      
      ids = medicationsList.map((e) {
        if (e.containsKey('id')) return e['id'].toString();
        return '';
      }).where((id) => id.isNotEmpty).toList();
    } else if (json['medicationIds'] != null) {
      ids = (json['medicationIds'] as List).map((e) => e.toString()).toList();
    }

    // Parse days
    List<int> daysList = [];
    if (json['days'] != null && json['days'] is List) {
      daysList = (json['days'] as List).map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).where((e) => e > 0).toList();
    }

    // Parse intakePeriods
    List<String> periodsList = [];
    if (json['intakePeriods'] != null && json['intakePeriods'] is List) {
      periodsList = (json['intakePeriods'] as List).map((e) => e.toString()).toList();
    }

    return MedicationBox(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      imagePath: json['imagePath'],
      medicationIds: ids,
      medications: medicationsList,
      days: daysList,
      intakePeriods: periodsList,
      intakeTiming: json['intakeTiming'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'imagePath': imagePath,
      'medicationIds': medicationIds,
      'days': days,
      'intakePeriods': intakePeriods,
      if (intakeTiming != null) 'intakeTiming': intakeTiming,
    };
  }

  MedicationBox copyWith({
    String? id,
    String? name,
    String? description,
    String? imagePath,
    List<String>? medicationIds,
    List<Map<String, dynamic>>? medications,
    List<int>? days,
    List<String>? intakePeriods,
    String? intakeTiming,
  }) {
    return MedicationBox(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      medicationIds: medicationIds ?? this.medicationIds,
      medications: medications ?? this.medications,
      days: days ?? this.days,
      intakePeriods: intakePeriods ?? this.intakePeriods,
      intakeTiming: intakeTiming ?? this.intakeTiming,
    );
  }
}
