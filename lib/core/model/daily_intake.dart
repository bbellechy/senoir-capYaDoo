enum IntakeStatus { PENDING, TAKEN, MISSED, NOT_TAKEN, OVERDUE }

class DailyIntake {
  final String intakeId;
  final String medicationName;
  final String time;
  /// ช่วงเวลาเชิงตรรกะ (ยึดตาม intakePeriods) เพื่อให้ไม่หลุดช่วงเวลาถึงแม้เวลาเลื่อนจาก intakeTiming
  /// ค่าที่ใช้: MORNING, NOON, EVENING, BEDTIME
  final String? periodKey;
  /// intakeTiming ของยา (BEFORE_MEAL/AFTER_MEAL/WITH_MEAL/IMMEDIATE)
  final String? intakeTiming;
  final IntakeStatus status;
  final String? imagePath;
  final int? remainingQuantity;
  final String? medicationId; // For matching with backend

  DailyIntake({
    required this.intakeId,
    required this.medicationName,
    required this.time,
    this.periodKey,
    this.intakeTiming,
    required this.status,
    this.imagePath,
    this.remainingQuantity,
    this.medicationId,
  });

  factory DailyIntake.fromJson(Map<String, dynamic> json) {
    // Backend sends 'id' instead of 'intakeId'
    final intakeId = json['intakeId'] ?? json['id'] ?? '';

    // Backend sends 'intakeTime' instead of 'time'
    final time = json['time'] ?? json['intakeTime'] ?? '00:00:00';

    // Get medicationId from medication object or medicationId field
    String? medicationId;
    if (json['medicationId'] != null) {
      medicationId = json['medicationId'].toString();
    } else if (json['medication'] != null) {
      final medication = json['medication'];
      if (medication is Map) {
        medicationId = medication['id']?.toString();
      }
    }

    // Backend may have medication object or medicationName directly
    String medicationName = '';
    if (json['medicationName'] != null) {
      medicationName = json['medicationName'].toString();
    } else if (json['medication'] != null) {
      final medication = json['medication'];
      if (medication is Map) {
        medicationName = medication['name']?.toString() ?? '';
      }
    }

    // Get remainingQuantity from medication if available
    int? remainingQuantity;
    if (json['remainingQuantity'] != null) {
      remainingQuantity = int.tryParse(json['remainingQuantity'].toString());
    } else if (json['medication'] != null && json['medication'] is Map) {
      final medication = json['medication'] as Map;
      if (medication['remainingQuantity'] != null) {
        remainingQuantity = int.tryParse(
          medication['remainingQuantity'].toString(),
        );
      }
    }

    // Get imagePath from medication if available
    String? imagePath = json['imagePath']?.toString();
    if (imagePath == null &&
        json['medication'] != null &&
        json['medication'] is Map) {
      final medication = json['medication'] as Map;
      imagePath = medication['imagePath']?.toString();
    }

    // intakeTiming may exist at root or in medication object
    String? intakeTiming = json['intakeTiming']?.toString();
    if (intakeTiming == null &&
        json['medication'] != null &&
        json['medication'] is Map) {
      final medication = json['medication'] as Map;
      intakeTiming = medication['intakeTiming']?.toString();
    }

    return DailyIntake(
      intakeId: intakeId,
      medicationName: medicationName,
      time: time,
      periodKey: json['periodKey']?.toString(),
      intakeTiming: intakeTiming,
      status: _parseStatus(json['status']),
      imagePath: imagePath,
      remainingQuantity: remainingQuantity,
      medicationId: medicationId,
    );
  }

  static IntakeStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'TAKEN':
        return IntakeStatus.TAKEN;
      case 'MISSED':
        return IntakeStatus.MISSED;
      case 'NOT_TAKEN':
        return IntakeStatus.NOT_TAKEN;
      case 'OVERDUE':
        return IntakeStatus.OVERDUE;
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
      'periodKey': periodKey,
      'intakeTiming': intakeTiming,
      'status': status.name,
      'imagePath': imagePath,
      'remainingQuantity': remainingQuantity,
      'medicationId': medicationId,
    };
  }
}
