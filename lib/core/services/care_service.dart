import 'dart:convert';
import 'package:capyadoo/core/services/api_client.dart';
import 'package:capyadoo/core/model/care_models.dart';
import 'package:capyadoo/core/model/daily_intake.dart';
import 'package:capyadoo/core/model/medication_box.dart';
import 'package:capyadoo/core/model/user_medication.dart';
import 'package:capyadoo/core/services/medication_service.dart';
import 'package:capyadoo/core/services/medication_schedule_service.dart';

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
    String patientId, // This is the userId of the patient
    DateTime date,
  ) async {
    try {
      // Use the same API as main page: /medications/search?userId=...
      final medications = await MedicationService.getUserMedications(patientId);
      
      // Generate daily intake from medications (same logic as main page)
      return await MedicationScheduleService.generateDailyIntakeFromMedications(medications, date);
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

  // Get medications for a specific patient (using same API as main page)
  static Future<List<UserMedication>> getPatientMedications(
    String patientId, // This is the userId
  ) async {
    try {
      // Use the same API as main page: /medications/search?userId=...
      return await MedicationService.getUserMedications(patientId);
    } catch (e) {
      print('Error getting patient medications: $e');
      return [];
    }
  }

  // Remove a patient from caregiver's care list
  static Future<bool> removePatient(String patientId) async {
    try {
      final response = await ApiClient.delete(
        '/caregiver/patients/$patientId',
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error removing patient: $e');
      return false;
    }
  }
}
