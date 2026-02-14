import 'dart:convert';
import '../model/medication.dart';
import 'api_client.dart';

class SearchMedicationApi {
  static Future<List<Medication>> search(String keyword) async {
    final response = await ApiClient.get(
      '/master-medications/search?keyword=$keyword',
    );

    if (response.statusCode != 200) {
      throw Exception('Unauthorized or Error');
    }

    final List data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.map((e) => Medication.fromJson(e)).toList();
  }

  static Future<Medication?> getById(String id) async {
    try {
      final response = await ApiClient.get('/master-medications/$id');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Medication.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching medication by ID: $e');
      return null;
    }
  }
}
