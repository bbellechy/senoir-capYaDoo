import 'medication.dart';

class UserMedication {
  final String? id;
  final String name;
  final double? dosage;
  final String? unit;
  final int? timesPerDay;
  final String? intakeTiming;
  final String? intakePeriods;
  final String? expiryDate;
  final String? userId;
  final Medication? masterMedicationEntity;

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
      intakePeriods: json['intakePeriods'],
      expiryDate: json['expiryDate'],
      userId: json['userId']?.toString(),
      masterMedicationEntity: json['masterMedicationEntity'] != null
          ? Medication.fromJson(json['masterMedicationEntity'])
          : null,
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
    };
  }
}
