import 'dart:convert';
import 'package:capyadoo/core/services/api_client.dart';
import 'package:capyadoo/core/model/daily_intake.dart';
import 'package:intl/intl.dart';

class IntakeActionResponse {
  final bool success;
  final int statusCode;

  IntakeActionResponse({required this.success, required this.statusCode});
}

class MedicationScheduleService {
  // Fetch daily medication schedule for a specific date
  static Future<List<DailyIntake>> getDailySchedule(DateTime date) async {
    try {
      final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final response = await ApiClient.get(
        '/daily-medication?date=$formattedDate',
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(
          utf8.decode(response.bodyBytes),
        );
        return jsonList.map((json) => DailyIntake.fromJson(json)).toList();
      } else {
        print('Failed to fetch daily schedule: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching daily schedule: $e');
      return [];
    }
  }

  // Mark a medication intake as taken
  static Future<bool> markAsTaken(String intakeId) async {
    final result = await markAsTakenWithResponse(intakeId);
    return result.success;
  }

  // Mark a medication intake as taken and return the detailed response
  static Future<IntakeActionResponse> markAsTakenWithResponse(
    String intakeId,
  ) async {
    try {
      final response = await ApiClient.post('/daily-medication/$intakeId/take');
      return IntakeActionResponse(
        success:
            response.statusCode == 200 ||
            response.statusCode == 201 ||
            response.statusCode == 204,
        statusCode: response.statusCode,
      );
    } catch (e) {
      print('Error marking medication as taken: $e');
      return IntakeActionResponse(success: false, statusCode: 500);
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
