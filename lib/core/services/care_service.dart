import 'dart:convert';
import 'package:capyadoo/core/services/api_client.dart';
import 'package:capyadoo/core/model/care_models.dart';
import 'package:capyadoo/core/model/daily_intake.dart';
import 'package:capyadoo/core/model/medication_box.dart';
import 'package:capyadoo/core/model/user_medication.dart';
import 'package:intl/intl.dart';

class CareService {
  // Get all care requests sent to the current user
  static Future<List<CareRequest>> getCareRequests() async {
    try {
      final response = await ApiClient.get('/care/requests');
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(
          utf8.decode(response.bodyBytes),
        );
        return jsonList.map((j) => CareRequest.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting care requests: $e');
      return [];
    }
  }

  // Send a care request to another user by username
  static Future<bool> sendCareRequest(String username) async {
    try {
      final response = await ApiClient.post('/care/request', {
        'username': username,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error sending care request: $e');
      return false;
    }
  }

  // Respond to a care request
  static Future<bool> respondToRequest(String id, bool accept) async {
    try {
      // The parameter is a request param: ?accept=true/false
      final response = await ApiClient.post(
        '/care/requests/$id/respond?accept=$accept',
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error responding to care request: $e');
      return false;
    }
  }

  // Get list of patients for the current caregiver
  static Future<List<Patient>> getPatients() async {
    try {
      // Based on user provided URL: http://localhost:8080/api/caregiver/patients
      final response = await ApiClient.get('/caregiver/patients');
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(
          utf8.decode(response.bodyBytes),
        );
        return jsonList.map((j) => Patient.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting patients: $e');
      return [];
    }
  }

  // Get daily schedule for a specific patient
  static Future<List<DailyIntake>> getPatientSchedule(
    String patientId,
    DateTime date,
  ) async {
    try {
      final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final response = await ApiClient.get(
        '/caregiver/patients/$patientId/daily-medication?date=$formattedDate',
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(
          utf8.decode(response.bodyBytes),
        );
        return jsonList.map((j) => DailyIntake.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting patient schedule: $e');
      return [];
    }
  }

  // Get medication boxes for a specific patient
  static Future<List<MedicationBox>> getPatientMedicationBoxes(
    String patientId,
  ) async {
    try {
      final response = await ApiClient.get(
        '/caregiver/patients/$patientId/medication-boxes',
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(
          utf8.decode(response.bodyBytes),
        );
        return jsonList.map((j) => MedicationBox.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting patient medication boxes: $e');
      return [];
    }
  }

  // Get medications for a specific patient
  static Future<List<UserMedication>> getPatientMedications(
    String patientId,
  ) async {
    try {
      final response = await ApiClient.get(
        '/caregiver/patients/$patientId/medications',
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(
          utf8.decode(response.bodyBytes),
        );
        return jsonList.map((j) => UserMedication.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting patient medications: $e');
      return [];
    }
  }
}
