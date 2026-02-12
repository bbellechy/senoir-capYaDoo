class MedicationBox {
  final String? id;
  final String name;
  final String? description;
  final String? imagePath;
  final List<String> medicationIds;
  final List<Map<String, dynamic>>
  medications; // Store medications array from API
  final List<int> days;
  final List<String> intakePeriods;
  final String? intakeTiming;

  /// วันที่สร้างกล่อง (จาก API) เพื่อแสดงเฉพาะตั้งแต่วันนี้เป็นต้นไป
  final DateTime? createdAt;

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
    this.createdAt,
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

      ids = medicationsList
          .map((e) {
            if (e.containsKey('id')) return e['id'].toString();
            return '';
          })
          .where((id) => id.isNotEmpty)
          .toList();
    } else if (json['medicationIds'] != null) {
      ids = (json['medicationIds'] as List).map((e) => e.toString()).toList();
    }

    // Parse days
    List<int> daysList = [];
    if (json['days'] != null && json['days'] is List) {
      daysList = (json['days'] as List)
          .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
          .where((e) => e > 0)
          .toList();
    }

    // Parse intakePeriods
    // รองรับได้หลายรูปแบบ:
    // - intakePeriods: ["MORNING","NOON"]
    // - intakePeriods: "MORNING,NOON"
    // - intake_periods: "MORNING,NOON" (เผื่อ backend ส่ง snake_case)
    List<String> periodsList = [];
    final rawPeriods =
        json['intakePeriods'] ?? json['intake_periods'] ?? json['intakePeriod'];

    List<String> _normalizePeriods(Iterable<dynamic> periods) {
      return periods
          .map((e) => e.toString().trim())
          .where((p) => p.isNotEmpty)
          .map((p) {
            // normalize (support Thai labels just in case)
            switch (p.toUpperCase()) {
              case 'เช้า':
              case 'MORNING':
                return 'MORNING';
              case 'กลางวัน':
              case 'NOON':
              case 'AFTERNOON':
                return 'NOON';
              case 'เย็น':
              case 'EVENING':
                return 'EVENING';
              case 'ก่อนนอน':
              case 'BEDTIME':
              case 'NIGHT':
                return 'BEDTIME';
              default:
                return p.toUpperCase();
            }
          })
          .toSet() // de-dup
          .toList();
    }

    if (rawPeriods is List) {
      periodsList = _normalizePeriods(rawPeriods);
    } else if (rawPeriods is String) {
      periodsList = _normalizePeriods(rawPeriods.split(','));
    }

    // Parse createdAt (รองรับทั้ง createdAt และ created_at)
    DateTime? createdAt;
    if (json['createdAt'] != null) {
      try {
        createdAt = DateTime.tryParse(json['createdAt'].toString());
      } catch (_) {}
    }
    if (createdAt == null && json['created_at'] != null) {
      try {
        createdAt = DateTime.tryParse(json['created_at'].toString());
      } catch (_) {}
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
      createdAt: createdAt,
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
    DateTime? createdAt,
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
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
