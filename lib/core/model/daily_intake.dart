enum IntakeStatus { PENDING, TAKEN, MISSED }

class DailyIntake {
  final String intakeId;
  final String medicationName;
  final String time;
  final IntakeStatus status;

  DailyIntake({
    required this.intakeId,
    required this.medicationName,
    required this.time,
    required this.status,
  });

  factory DailyIntake.fromJson(Map<String, dynamic> json) {
    return DailyIntake(
      intakeId: json['intakeId'] ?? '',
      medicationName: json['medicationName'] ?? '',
      time: json['time'] ?? '00:00:00',
      status: _parseStatus(json['status']),
    );
  }

  static IntakeStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'TAKEN':
        return IntakeStatus.TAKEN;
      case 'MISSED':
        return IntakeStatus.MISSED;
      case 'PENDING':
      default:
        return IntakeStatus.PENDING;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'intakeId': intakeId,
      'medicationName': medicationName,
      'time': time,
      'status': status.name,
    };
  }
}
