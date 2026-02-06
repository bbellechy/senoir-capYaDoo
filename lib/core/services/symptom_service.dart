import 'dart:convert';
import 'package:capyadoo/core/services/api_client.dart';
import '../model/symptom_record.dart';

class SymptomService {
  static Future<SymptomRecord?> createSymptom(SymptomRecord record) async {
    try {
      final response = await ApiClient.post('/symptoms', record.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return SymptomRecord.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)),
        );
      }
      return null;
    } catch (e) {
      print('Error creating symptom: $e');
      return null;
    }
  }

  static Future<List<SymptomRecord>> getUserSymptoms(String userId) async {
    try {
      final response = await ApiClient.get(
        '/symptoms/user/$userId?userId=$userId',
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => SymptomRecord.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching symptoms: $e');
      return [];
    }
  }

  static Future<SymptomRecord?> updateSymptom(
    String id,
    SymptomRecord record,
  ) async {
    try {
      final response = await ApiClient.put('/symptoms/$id', record.toJson());
      if (response.statusCode == 200) {
        return SymptomRecord.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)),
        );
      }
      return null;
    } catch (e) {
      print('Error updating symptom: $e');
      return null;
    }
  }

  static Future<bool> deleteSymptom(String id) async {
    try {
      final response = await ApiClient.delete('/symptoms/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting symptom: $e');
      return false;
    }
  }
}
