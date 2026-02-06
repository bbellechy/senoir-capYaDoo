class SymptomRecord {
  final String? id;
  final String date; // yyyy-MM-dd
  final String time; // HH:mm:ss
  final String medicationName;
  final int severityLevel;
  final String? symptom;
  final String userId;

  SymptomRecord({
    this.id,
    required this.date,
    required this.time,
    required this.medicationName,
    required this.severityLevel,
    this.symptom,
    required this.userId,
  });

  factory SymptomRecord.fromJson(Map<String, dynamic> json) {
    return SymptomRecord(
      id: json['id']?.toString(),
      date: json['date'] ?? '',
      time: json['time'] ?? '00:00:00',
      medicationName: json['medicationName'] ?? '',
      severityLevel: json['severityLevel'] ?? 0,
      symptom: json['symptom'],
      userId: json['userId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'time': time,
      'medicationName': medicationName,
      'severityLevel': severityLevel,
      'symptom': symptom,
      'userId': userId,
    };
  }
}
