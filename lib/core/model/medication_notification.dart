class MedicationNotification {
  final String? id;
  final String medicationName;
  final List<int> days; // 1=Monday, 2=Tuesday, ..., 7=Sunday
  final List<String> times; // Format: "HH:mm:ss"
  final bool isEnabled;
  final int? baseNotificationId;

  MedicationNotification({
    this.id,
    required this.medicationName,
    required this.days,
    required this.times,
    this.isEnabled = true,
    this.baseNotificationId,
  });

  // Convert to JSON for backend API
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'medicationName': medicationName,
      'days': days,
      'times': times,
      'isEnabled': isEnabled,
      'isActive': isEnabled, // Send both for compatibility
      if (baseNotificationId != null) 'baseNotificationId': baseNotificationId,
    };
  }

  // Create from JSON (backend response)
  factory MedicationNotification.fromJson(Map<String, dynamic> json) {
    // Backend uses 'isActive', frontend model uses 'isEnabled'
    final bool active = json['isActive'] ?? json['isEnabled'] ?? true;

    return MedicationNotification(
      id: json['id']?.toString(),
      medicationName: json['medicationName'] ?? '',
      days:
          (json['days'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      times:
          (json['times'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isEnabled: active,
      baseNotificationId: json['baseNotificationId'] != null
          ? int.tryParse(json['baseNotificationId'].toString())
          : null,
    );
  }

  // Create a copy with updated fields
  MedicationNotification copyWith({
    String? id,
    String? medicationName,
    List<int>? days,
    List<String>? times,
    bool? isEnabled,
    int? baseNotificationId,
  }) {
    return MedicationNotification(
      id: id ?? this.id,
      medicationName: medicationName ?? this.medicationName,
      days: days ?? this.days,
      times: times ?? this.times,
      isEnabled: isEnabled ?? this.isEnabled,
      baseNotificationId: baseNotificationId ?? this.baseNotificationId,
    );
  }

  // Get day names in Thai (abbreviated)
  List<String> getDayNames() {
    const dayMap = {1: 'จ', 2: 'อ', 3: 'พ', 4: 'พฤ', 5: 'ศ', 6: 'ส', 7: 'อา'};
    return days.map((day) => dayMap[day] ?? '').toList();
  }

  // Format times for display (HH:mm)
  List<String> getFormattedTimes() {
    return times.map((time) {
      final parts = time.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}:${parts[1]}';
      }
      return time;
    }).toList();
  }

  // Getters for display strings
  String get formattedDays => getDayNames().join(', ');
  String get formattedTimes => getFormattedTimes().join(', ');
}
