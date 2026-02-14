import 'dart:convert';
import 'package:capyadoo/core/services/api_client.dart';
import 'package:capyadoo/core/model/medication.dart';
import 'package:capyadoo/core/model/user_medication.dart';
import 'package:capyadoo/core/model/medication_box.dart';
import 'package:capyadoo/core/services/pill_box_service.dart';
import 'package:capyadoo/core/services/search_master_medication_api.dart';

class MedicationSearchService {
  final PillBoxService _pillBoxService = PillBoxService();

  // Fetch user-specific medications with optional keyword
  Future<List<UserMedication>> searchUserMedications(
    String userId, [
    String? keyword,
  ]) async {
    try {
      String path = '/medications/search?userId=$userId';
      if (keyword != null && keyword.isNotEmpty) {
        path += '&keyword=${Uri.encodeComponent(keyword)}';
      }

      final response = await ApiClient.get(path);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(
          utf8.decode(response.bodyBytes),
        );
        return jsonList.map((json) => UserMedication.fromJson(json)).toList();
      } else {
        print('Failed to search user medications: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error searching user medications: $e');
      return [];
    }
  }

  // Search medications by userId (legacy, returns Medication objects)
  Future<List<Medication>> searchMedications(String userId) async {
    try {
      final response = await ApiClient.get(
        '/medications/search?userId=$userId',
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(
          utf8.decode(response.bodyBytes),
        );
        return jsonList.map((json) {
          // Flatten user medication to medication for legacy support
          final userMed = UserMedication.fromJson(json);
          return Medication(
            id: userMed.id,
            tradenameTh: userMed.name,
            tradenameEn: userMed.masterMedicationEntity?.tradenameEn,
          );
        }).toList();
      } else {
        print('Failed to search medications: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error searching medications: $e');
      return [];
    }
  }

  // Search all master medications in the system
  Future<List<Medication>> searchMasterMedications(String keyword) async {
    try {
      // Use the keyword search API if keyword is provided, otherwise get all
      if (keyword.isEmpty) {
        final response = await ApiClient.get('/master-medications');
        if (response.statusCode == 200) {
          final List data = jsonDecode(utf8.decode(response.bodyBytes));
          return data.map((e) => Medication.fromJson(e)).toList();
        }
        return [];
      }
      return await SearchMedicationApi.search(keyword);
    } catch (e) {
      print('Error searching master medications: $e');
      return [];
    }
  }

  // Get all medication boxes
  Future<List<MedicationBox>> getMedicationBoxes() async {
    return await _pillBoxService.getAllPillBoxes();
  }
}
