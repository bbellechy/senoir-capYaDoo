import 'dart:convert';
import 'package:capyadoo/core/services/api_client.dart';
import 'package:capyadoo/core/model/daily_intake.dart';
import 'package:capyadoo/core/model/user_medication.dart';
import 'package:capyadoo/core/services/medication_service.dart';
import 'package:capyadoo/core/services/auth_service.dart';
import 'package:intl/intl.dart';

class IntakeActionResponse {
  final bool success;
  final int statusCode;
  final String? message;

  IntakeActionResponse({
    required this.success,
    required this.statusCode,
    this.message,
  });
}

class MedicationScheduleService {
  /// Resolve backend intake UUID (daily-medication id) from medicationId + date + time.
  /// Returns null if backend hasn't created a record yet.
  static Future<String?> resolveBackendIntakeId({
    String? medicationId,
    String? medicationName,
    required DateTime date,
    required String time,
  }) async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final response = await ApiClient.get('/daily-medication?date=$formattedDate');

      if (response.statusCode != 200) return null;

      final List<dynamic> jsonList = json.decode(utf8.decode(response.bodyBytes));
      final backendIntakes =
          jsonList.map((j) => DailyIntake.fromJson(j)).toList();

      String normalizeTime(String t) {
        // Compare only HH:mm to be resilient to seconds formats
        if (t.length >= 5) return t.substring(0, 5);
        return t;
      }

      final targetTime = normalizeTime(time);

      String normalizeName(String? n) {
        return (n ?? '').trim().toLowerCase();
      }

      final targetName = normalizeName(medicationName);

      bool matchByIdAndTime(DailyIntake i) =>
          medicationId != null &&
          medicationId.isNotEmpty &&
          i.medicationId != null &&
          i.medicationId == medicationId &&
          normalizeTime(i.time) == targetTime;

      bool matchByNameAndTime(DailyIntake i) =>
          targetName.isNotEmpty &&
          normalizeName(i.medicationName) == targetName &&
          normalizeTime(i.time) == targetTime;

      DailyIntake? pickBest(List<DailyIntake> candidates) {
        // Prefer one with non-empty intakeId (UUID)
        for (final c in candidates) {
          if (c.intakeId.isNotEmpty) return c;
        }
        return candidates.isNotEmpty ? candidates.first : null;
      }

      // Prefer exact match by medicationId + time, fallback to medicationName + time
      final byIdAndTime = backendIntakes.where(matchByIdAndTime).toList();
      final byNameAndTime = backendIntakes.where(matchByNameAndTime).toList();

      DailyIntake? best = pickBest(byIdAndTime);
      best ??= pickBest(byNameAndTime);

      // Fallback: match by medicationId + period (morning/afternoon/evening/night)
      if (best == null) {
        String getTimePeriod(String t) {
          final hour = int.tryParse(t.split(':')[0]) ?? 0;
          if (hour >= 5 && hour < 11) return 'morning';
          if (hour >= 11 && hour < 16) return 'afternoon';
          if (hour >= 16 && hour < 21) return 'evening';
          return 'night';
        }

        final targetPeriod = getTimePeriod(time);
        final byIdAndPeriod = backendIntakes
            .where(
              (i) =>
                  medicationId != null &&
                  medicationId.isNotEmpty &&
                  i.medicationId != null &&
                  i.medicationId == medicationId &&
                  getTimePeriod(i.time) == targetPeriod,
            )
            .toList();
        final byNameAndPeriod = backendIntakes
            .where(
              (i) =>
                  targetName.isNotEmpty &&
                  normalizeName(i.medicationName) == targetName &&
                  getTimePeriod(i.time) == targetPeriod,
            )
            .toList();

        // IMPORTANT: period matching can collide if there are multiple meds in same period.
        // Only accept period fallback if it is unique for that medId/name.
        if (byIdAndPeriod.length == 1) {
          best = byIdAndPeriod.first;
        } else if (byNameAndPeriod.length == 1) {
          best = byNameAndPeriod.first;
        } else {
          best = null;
        }
      }

      if (best == null) return null;
      if (best.intakeId.isEmpty) return null;
      return best.intakeId;
    } catch (e) {
      print('Error resolving backend intakeId: $e');
      return null;
    }
  }

  // Fetch daily medication schedule for a specific date
  static Future<List<DailyIntake>> getDailySchedule(DateTime date) async {
    try {
      // Get current user
      final profile = await AuthService.getProfile();
      if (profile == null) {
        return [];
      }

      // Fetch medications for the user
      final medications = await MedicationService.getUserMedications(profile.id);
      
      // Generate daily intake from medications
      return await generateDailyIntakeFromMedications(medications, date);
    } catch (e) {
      print('Error fetching daily schedule: $e');
      return [];
    }
  }

  // Generate daily intake list from medications based on date, days, startDate, endDate
  static Future<List<DailyIntake>> generateDailyIntakeFromMedications(
    List<UserMedication> medications,
    DateTime date,
  ) async {
    final List<DailyIntake> dailyIntakes = [];
    final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final int dayOfWeek = date.weekday; // 1=Monday, 7=Sunday
    final DateTime dateOnly = DateTime(date.year, date.month, date.day);

    for (final med in medications) {
      // Check if medication is active
      if (med.days == null || med.days!.isEmpty) continue;

      // Check if medication should be taken on this day of week
      if (!med.days!.contains(dayOfWeek)) continue;

      // Check date range (startDate and endDate)
      if (med.startDate != null) {
        final startDate = DateTime.tryParse(med.startDate!);
        if (startDate != null) {
          final startDateOnly = DateTime(startDate.year, startDate.month, startDate.day);
          if (dateOnly.isBefore(startDateOnly)) continue;
        }
      }

      if (med.endDate != null) {
        final endDate = DateTime.tryParse(med.endDate!);
        if (endDate != null) {
          final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);
          if (dateOnly.isAfter(endDateOnly)) continue;
        }
      }

      // Generate intake times from intakePeriods
      final intakeTimes = _getIntakeTimesFromPeriods(med.intakePeriods);
      
      // If no intake periods specified, skip
      if (intakeTimes.isEmpty) continue;

      // Create DailyIntake for each time
      for (final time in intakeTimes) {
        // Check if there's an existing intake record from backend
        // For now, we'll create a basic intake record
        // The backend should handle the actual intake status via daily-medication API
        final intakeId = '${med.id}_${formattedDate}_$time';
        
        dailyIntakes.add(
          DailyIntake(
            intakeId: intakeId,
            medicationName: med.name,
            time: time,
            status: IntakeStatus.PENDING, // Default status, backend will update
            imagePath: med.imagePath,
            remainingQuantity: med.remainingQuantity,
            medicationId: med.id, // Store medication ID for matching
          ),
        );
      }
    }

    // Try to get actual intake status from backend daily-medication API
    return await _mergeWithBackendIntakeStatus(dailyIntakes, formattedDate);
  }

  // Get intake times from periods (MORNING, NOON, EVENING, BEDTIME)
  static List<String> _getIntakeTimesFromPeriods(List<String>? periods) {
    if (periods == null || periods.isEmpty) return [];
    
    final Map<String, String> periodToTime = {
      'MORNING': '08:00:00',
      'NOON': '12:00:00',
      'EVENING': '18:00:00',
      'BEDTIME': '21:00:00',
    };

    return periods
        .where((p) => periodToTime.containsKey(p.toUpperCase()))
        .map((p) => periodToTime[p.toUpperCase()]!)
        .toList();
  }

  // Merge with backend intake status if available
  static Future<List<DailyIntake>> _mergeWithBackendIntakeStatus(
    List<DailyIntake> generatedIntakes,
    String formattedDate,
  ) async {
    try {
      final response = await ApiClient.get(
        '/daily-medication?date=$formattedDate',
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(
          utf8.decode(response.bodyBytes),
        );
        final backendIntakes = jsonList.map((json) => DailyIntake.fromJson(json)).toList();
        
        print('Backend intakes count: ${backendIntakes.length}');
        for (final intake in backendIntakes) {
          print('Backend intake: ${intake.medicationName} at ${intake.time} - ID: ${intake.intakeId}');
        }
        
        String normalizeTime(String t) {
          if (t.length >= 5) return t.substring(0, 5);
          return t;
        }

        // Get time period from time (for flexible matching)
        String getTimePeriod(String time) {
          final hour = int.tryParse(time.split(':')[0]) ?? 0;
          if (hour >= 5 && hour < 11) return 'morning';
          if (hour >= 11 && hour < 16) return 'afternoon';
          if (hour >= 16 && hour < 21) return 'evening';
          return 'night';
        }

        String normalizeName(String name) => name.trim().toLowerCase();

        // Create maps for robust matching.
        // Priority:
        // - medicationId + HH:mm
        // - medicationName + HH:mm
        // - (unique only) medicationId + period
        // - (unique only) medicationName + period
        // IMPORTANT: This API is only for getting status and intakeId, not for creating new items
        DailyIntake pickBetter(DailyIntake a, DailyIntake b) {
          if (a.intakeId.isEmpty && b.intakeId.isNotEmpty) return b;
          return a;
        }

        final Map<String, DailyIntake> byIdTime = {};
        final Map<String, DailyIntake> byNameTime = {};
        final Map<String, List<DailyIntake>> byIdPeriod = {};
        final Map<String, List<DailyIntake>> byNamePeriod = {};

        for (final intake in backendIntakes) {
          final hhmm = normalizeTime(intake.time);
          final period = getTimePeriod(intake.time);

          if (intake.medicationId != null && intake.medicationId!.isNotEmpty) {
            final key = '${intake.medicationId}_$hhmm';
            byIdTime[key] = byIdTime.containsKey(key)
                ? pickBetter(byIdTime[key]!, intake)
                : intake;

            final pKey = '${intake.medicationId}_$period';
            byIdPeriod.putIfAbsent(pKey, () => []).add(intake);
          }

          if (intake.medicationName.trim().isNotEmpty) {
            final nKey = '${normalizeName(intake.medicationName)}_$hhmm';
            byNameTime[nKey] = byNameTime.containsKey(nKey)
                ? pickBetter(byNameTime[nKey]!, intake)
                : intake;

            final npKey = '${normalizeName(intake.medicationName)}_$period';
            byNamePeriod.putIfAbsent(npKey, () => []).add(intake);
          }
        }

        // Update generated intakes with backend status and intakeId (if available)
        // Only update existing generated intakes, don't add new ones from backend
        final List<DailyIntake> mergedIntakes = [];
        
        for (final generated in generatedIntakes) {
          final hhmm = normalizeTime(generated.time);
          final period = getTimePeriod(generated.time);
          DailyIntake? backend;

          // 1) medicationId + time
          if (generated.medicationId != null &&
              generated.medicationId!.isNotEmpty) {
            backend = byIdTime['${generated.medicationId}_$hhmm'];
          }

          // 2) name + time
          backend ??= byNameTime['${normalizeName(generated.medicationName)}_$hhmm'];

          // 3) unique medicationId + period
          if (backend == null &&
              generated.medicationId != null &&
              generated.medicationId!.isNotEmpty) {
            final list = byIdPeriod['${generated.medicationId}_$period'];
            if (list != null && list.length == 1) backend = list.first;
          }

          // 4) unique name + period
          if (backend == null) {
            final list = byNamePeriod['${normalizeName(generated.medicationName)}_$period'];
            if (list != null && list.length == 1) backend = list.first;
          }
          
          if (backend != null) {
            // Found matching backend intake - update status and intakeId (if available)
            mergedIntakes.add(
              DailyIntake(
                intakeId: backend.intakeId.isNotEmpty 
                    ? backend.intakeId 
                    : generated.intakeId, // Use backend intakeId if available, otherwise keep generated
                medicationName: generated.medicationName, // Always keep from generated (has name)
                time: generated.time, // Always keep from generated (correct format)
                status: backend.status, // Always use backend status
                imagePath: generated.imagePath ?? backend.imagePath,
                remainingQuantity: generated.remainingQuantity ?? backend.remainingQuantity,
                medicationId: generated.medicationId ?? backend.medicationId,
              ),
            );
            print('Updated: ${generated.medicationName} at ${generated.time} - Status: ${backend.status}, Backend ID: ${backend.intakeId.isEmpty ? "none" : backend.intakeId}');
          } else {
            // No backend record yet - use generated intake as is (status will be PENDING)
            print('No backend record: ${generated.medicationName} at ${generated.time} - Generated ID: ${generated.intakeId}');
            mergedIntakes.add(generated);
          }
        }
        
        print('Total merged intakes: ${mergedIntakes.length}');
        return mergedIntakes;
      } else {
        print('Backend API returned status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error merging with backend intake status: $e');
    }
    
    return generatedIntakes;
  }

  // Mark a medication intake as taken
  static Future<bool> markAsTaken(String intakeId) async {
    final result = await markAsTakenWithResponse(intakeId);
    return result.success;
  }

  // Check if intakeId is a valid UUID (not a generated one)
  static bool _isValidUuid(String intakeId) {
    // UUID format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx (36 characters with hyphens)
    // Or without hyphens: 32 hex characters
    if (intakeId.isEmpty) return false;
    
    // Check if it contains underscore (generated IDs have format: medId_date_time)
    if (intakeId.contains('_')) return false;
    
    // Check if it's a valid UUID format (with or without hyphens)
    final uuidPattern = RegExp(r'^[0-9a-f]{8}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{12}$', caseSensitive: false);
    return uuidPattern.hasMatch(intakeId);
  }

  // Mark a medication intake as taken and return the detailed response
  static Future<IntakeActionResponse> markAsTakenWithResponse(
    String intakeId,
  ) async {
    try {
      // Validate that intakeId is a real UUID from backend
      if (!_isValidUuid(intakeId)) {
        print('Invalid intakeId format: $intakeId (not a valid UUID)');
        return IntakeActionResponse(
          success: false,
          statusCode: 400,
          message: 'Invalid intakeId (not UUID)',
        );
      }

      print('Marking as taken - intakeId: $intakeId');
      final response = await ApiClient.post('/daily-medication/$intakeId/take');
      print('Mark as taken response: ${response.statusCode}');
      if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 204) {
        print('Response body: ${response.body}');
      }
      
      return IntakeActionResponse(
        success:
            response.statusCode == 200 ||
            response.statusCode == 201 ||
            response.statusCode == 204,
        statusCode: response.statusCode,
        message: response.body.isNotEmpty ? response.body : null,
      );
    } catch (e) {
      print('Error marking medication as taken: $e');
      return IntakeActionResponse(
        success: false,
        statusCode: 500,
        message: e.toString(),
      );
    }
  }

  // Mark a medication intake as missed (Not Taken)
  static Future<bool> markAsMissed(String intakeId) async {
    try {
      final response = await ApiClient.post('/daily-medication/$intakeId/miss');
      return response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204;
    } catch (e) {
      print('Error marking medication as missed: $e');
      return false;
    }
  }

  // Mark a medication intake as overdue
  static Future<bool> markAsOverdue(String intakeId) async {
    try {
      final response = await ApiClient.post(
        '/daily-medication/$intakeId/overdue',
      );
      return response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204;
    } catch (e) {
      print('Error marking medication as overdue: $e');
      return false;
    }
  }
}
