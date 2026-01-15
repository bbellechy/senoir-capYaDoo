import 'dart:convert';
import '../model/medication.dart';
import 'api_client.dart';

class SearchMedicationApi {
  static Future<List<Medication>> search(String keyword) async {
    final response =
        await ApiClient.get('/master-medications/search?keyword=$keyword');

    if (response.statusCode != 200) {
      throw Exception('Unauthorized or Error');
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => Medication.fromJson(e)).toList();
  }
}
