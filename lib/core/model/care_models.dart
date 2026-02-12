class CareRequest {
  final String id;
  final String caregiverUsername;
  final String status; // e.g., "PENDING"

  CareRequest({
    required this.id,
    required this.caregiverUsername,
    required this.status,
  });

  factory CareRequest.fromJson(Map<String, dynamic> json) {
    return CareRequest(
      id: json['id'] ?? '',
      caregiverUsername: json['caregiverUsername'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

/// รายการคำขอที่ caregiver "ส่งออกไป" หา patient
class SentCareRequest {
  final String id;
  final String patientUsername;
  final String status; // e.g., "PENDING"

  SentCareRequest({
    required this.id,
    required this.patientUsername,
    required this.status,
  });

  factory SentCareRequest.fromJson(Map<String, dynamic> json) {
    return SentCareRequest(
      id: json['id']?.toString() ?? '',
      patientUsername: json['patientUsername']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class Patient {
  final String patientId;
  final String username;
  final String fullName;

  Patient({
    required this.patientId,
    required this.username,
    required this.fullName,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      patientId: json['patientId'] ?? '',
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
    );
  }
}
