import 'medication.dart';

class UserMedication {
  final String? id;
  final String name;
  final double? dosage;
  final String? unit;
  final int? timesPerDay;
  final String? intakeTiming;
  final List<String>? intakePeriods;
  final String? expiryDate;
  final String? userId;
  final Medication? masterMedicationEntity;
  final String? imagePath;
  final String? recommendation;
  final String? notes;

  UserMedication({
    this.id,
    required this.name,
    this.dosage,
    this.unit,
    this.timesPerDay,
    this.intakeTiming,
    this.intakePeriods,
    this.expiryDate,
    this.userId,
    this.masterMedicationEntity,
    this.imagePath,
    this.recommendation,
    this.notes,
  });

  String get displayName {
    if (masterMedicationEntity != null) {
      return masterMedicationEntity!.name;
    }
    return name;
  }

  factory UserMedication.fromJson(Map<String, dynamic> json) {
    return UserMedication(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      dosage: json['dosage'] != null
          ? double.tryParse(json['dosage'].toString())
          : null,
      unit: json['unit'],
      timesPerDay: json['timesPerDay'],
      intakeTiming: json['intakeTiming'],
      intakePeriods: json['intakePeriods'] != null
          ? (json['intakePeriods'] is String
                ? (json['intakePeriods'] as String)
                    .split(RegExp(r'[,\s]+'))
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList()
                : List<String>.from(json['intakePeriods']))
          : null,
      expiryDate: json['expiryDate'],
      userId: json['userId']?.toString(),
      masterMedicationEntity: json['masterMedicationEntity'] != null
          ? Medication.fromJson(json['masterMedicationEntity'])
          : null,
      imagePath: (json['imagePath'] ?? json['image'])?.toString(),
      recommendation: json['recommendation']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  UserMedication copyWith({
    String? id,
    String? name,
    double? dosage,
    String? unit,
    int? timesPerDay,
    String? intakeTiming,
    List<String>? intakePeriods,
    String? expiryDate,
    String? userId,
    Medication? masterMedicationEntity,
    String? imagePath,
    String? recommendation,
    String? notes,
  }) {
    return UserMedication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      unit: unit ?? this.unit,
      timesPerDay: timesPerDay ?? this.timesPerDay,
      intakeTiming: intakeTiming ?? this.intakeTiming,
      intakePeriods: intakePeriods ?? this.intakePeriods,
      expiryDate: expiryDate ?? this.expiryDate,
      userId: userId ?? this.userId,
      masterMedicationEntity:
          masterMedicationEntity ?? this.masterMedicationEntity,
      imagePath: imagePath ?? this.imagePath,
      recommendation: recommendation ?? this.recommendation,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'unit': unit,
      'timesPerDay': timesPerDay,
      'intakeTiming': intakeTiming,
      'intakePeriods': intakePeriods,
      'expiryDate': expiryDate,
      'userId': userId,
      'masterMedicationEntity': masterMedicationEntity?.toJson(),
      'imagePath': imagePath,
      'recommendation': recommendation,
      'notes': notes,
    };
  }
}
