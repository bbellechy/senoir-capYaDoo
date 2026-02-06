import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:capyadoo/core/services/api_client.dart';
import '../model/user_medication.dart';

class MedicationService {
  static const _storage = FlutterSecureStorage();
  static const _imageKeyPrefix = 'medication_image_';

  static Future<String> _saveImageLocally(File imageFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${directory.path}/medication_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final ext = imageFile.path.split('.').length > 1
        ? imageFile.path.split('.').last.toLowerCase()
        : 'jpg';
    final fileName = 'med_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final savedImage = await imageFile.copy('${imagesDir.path}/$fileName');
    return savedImage.path;
  }

  static Future<void> _saveLocalImageMapping(String medicationId, String path) async {
    await _storage.write(key: '$_imageKeyPrefix$medicationId', value: path);
  }

  static Future<String?> _getLocalImageMapping(String medicationId) async {
    return await _storage.read(key: '$_imageKeyPrefix$medicationId');
  }

  static Future<void> deleteMedicationImageMapping(String medicationId) async {
    await _storage.delete(key: '$_imageKeyPrefix$medicationId');
  }

  /// บันทึกรูปยาในเครื่องและแมปกับ medication id (ใช้หลัง create/update สำเร็จ)
  static Future<void> saveMedicationImageLocally(
    String medicationId,
    File imageFile,
  ) async {
    final path = await _saveImageLocally(imageFile);
    await _saveLocalImageMapping(medicationId, path);
  }

  static Future<UserMedication?> createMedication(
    Map<String, dynamic> request,
  ) async {
    try {
      final response = await ApiClient.post('/medications/add', request);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return UserMedication.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)),
        );
      }
      return null;
    } catch (e) {
      print('Error creating medication: $e');
      return null;
    }
  }

  static Future<List<UserMedication>> getUserMedications(
    String userId, {
    String? keyword,
  }) async {
    try {
      final path =
          '/medications/search?userId=$userId${keyword != null ? "&keyword=$keyword" : ""}';
      final response = await ApiClient.get(path);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final list =
            data.map((json) => UserMedication.fromJson(json)).toList();
        for (var i = 0; i < list.length; i++) {
          if (list[i].id != null) {
            final localPath = await _getLocalImageMapping(list[i].id!);
            if (localPath != null) {
              list[i] = list[i].copyWith(imagePath: localPath);
            }
          }
        }
        return list;
      }
      return [];
    } catch (e) {
      print('Error searching medications: $e');
      return [];
    }
  }

  static Future<UserMedication?> getMedicationById(
    String id,
    String userId,
  ) async {
    try {
      final response = await ApiClient.get('/medications/$id?userId=$userId');
      if (response.statusCode == 200) {
        var med = UserMedication.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)),
        );
        final localPath = await _getLocalImageMapping(id);
        if (localPath != null) {
          med = med.copyWith(imagePath: localPath);
        }
        return med;
      }
      return null;
    } catch (e) {
      print('Error getting medication by id: $e');
      return null;
    }
  }

  static Future<bool> deleteMedication(String id) async {
    try {
      final response = await ApiClient.delete('/medications/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        await deleteMedicationImageMapping(id);
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting medication: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getMasterMedications(
    String keyword,
  ) async {
    try {
      final response = await ApiClient.get(
        '/master-medications/search?keyword=$keyword',
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print('Error searching master medications: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>>
  getAllMasterMedicationNames() async {
    try {
      final response = await ApiClient.get('/master-medications');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print('Error getting all master medication names: $e');
      return [];
    }
  }

  static Future<UserMedication?> updateMedication(
    String id,
    Map<String, dynamic> request,
  ) async {
    try {
      final userId = request['userId'];
      final response = await ApiClient.put(
        '/medications/$id?userId=$userId',
        request,
      );
      if (response.statusCode == 200) {
        return UserMedication.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)),
        );
      }
      return null;
    } catch (e) {
      print('Error updating medication: $e');
      return null;
    }
  }
}
