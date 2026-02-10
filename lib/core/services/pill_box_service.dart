import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capyadoo/core/model/medication_box.dart';
import 'package:capyadoo/core/services/storage/token_storage.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class PillBoxService {
  // Replace with your actual backend URL
  // static const String _baseUrl = 'http://10.0.2.2:8080/api/medication-boxes';
  static const String _baseUrl =
      'http://192.168.1.43:8080/api/medication-boxes';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Get token helper - use TokenStorage to match the rest of the app
  Future<String?> _getToken() async {
    return await TokenStorage.getToken();
  }

  // Fetch all pill boxes
  Future<List<MedicationBox>> getAllPillBoxes() async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final boxes = data.map((json) => MedicationBox.fromJson(json)).toList();

        // Populate local images
        for (var i = 0; i < boxes.length; i++) {
          if (boxes[i].id != null) {
            final localPath = await _getLocalImageMapping(boxes[i].id!);
            if (localPath != null) {
              boxes[i] = boxes[i].copyWith(imagePath: localPath);
            }
          }
        }
        return boxes;
      } else {
        throw Exception('Failed to load pill boxes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching pill boxes: $e');
      return [];
    }
  }

  // Create a new pill box
  Future<MedicationBox?> createPillBox(
    MedicationBox box,
    File? imageFile,
  ) async {
    print('=== START createPillBox ===');
    print('Box name: ${box.name}');
    print('Box description: ${box.description}');
    print('Box medicationIds: ${box.medicationIds}');

    try {
      print('Step 1: Getting token...');
      final token = await _getToken();
      print(
        'Token retrieved: ${token != null && token.isNotEmpty ? "YES (${token.substring(0, 10)}...)" : "NO"}',
      );

      if (token == null || token.isEmpty) {
        print('ERROR: No authentication token found');
        throw Exception('No authentication token. Please login again.');
      }

      // 1. Save image locally
      print('Step 2: Saving image locally...');
      String? localImagePath;
      if (imageFile != null) {
        localImagePath = await _saveImageLocally(imageFile);
        print('Image saved to: $localImagePath');
      } else {
        print('No image file provided');
      }

      // 2. Prepare request body
      print('Step 3: Preparing request body...');
      final Map<String, dynamic> body = {
        'name': box.name,
        'description': box.description ?? '',
        'medicationIds': box.medicationIds,
        'days': box.days,
        'intakePeriods': box.intakePeriods,
        if (box.intakeTiming != null) 'intakeTiming': box.intakeTiming,
      };

      print('Request body: ${json.encode(body)}');
      print('Request URL: $_baseUrl');

      // 3. Send request
      print('Step 4: Sending HTTP POST request...');
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(body),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('ERROR: Request timeout');
              throw Exception(
                'Request timeout. Please check your network connection.',
              );
            },
          );

      print('Step 5: Received response');
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final createdBox = MedicationBox.fromJson(data);

        // Save local image mapping if we have an image
        if (localImagePath != null && createdBox.id != null) {
          await _saveLocalImageMapping(createdBox.id!, localImagePath);
          return createdBox.copyWith(imagePath: localImagePath);
        }

        return createdBox;
      } else {
        String errorMessage = 'Failed to create pill box';
        try {
          final errorData = json.decode(utf8.decode(response.bodyBytes));
          if (errorData is Map && errorData.containsKey('message')) {
            errorMessage = errorData['message'].toString();
          } else {
            errorMessage = response.body;
          }
        } catch (_) {
          errorMessage = response.body.isNotEmpty
              ? response.body
              : 'Status: ${response.statusCode}';
        }
        print('API Error: $errorMessage');
        print('=== END createPillBox (with error) ===');
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      print('=== ERROR in createPillBox ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      print('=== END createPillBox ===');
      // Re-throw to let controller handle it
      rethrow;
    }
  }

  // Update pill box
  Future<MedicationBox?> updatePillBox(
    MedicationBox box,
    File? newImageFile,
  ) async {
    try {
      final token = await _getToken();

      String? imagePathToSave = box.imagePath;

      if (newImageFile != null) {
        imagePathToSave = await _saveImageLocally(newImageFile);
      }

      final Map<String, dynamic> body = {
        'name': box.name,
        'description': box.description,
        'medicationIds': box.medicationIds,
        'days': box.days,
        'intakePeriods': box.intakePeriods,
        if (box.intakeTiming != null) 'intakeTiming': box.intakeTiming,
      };

      final response = await http.put(
        Uri.parse('$_baseUrl/${box.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final updatedBox = MedicationBox.fromJson(data);

        // Update local mapping if image changed
        if (newImageFile != null && updatedBox.id != null) {
          await _saveLocalImageMapping(updatedBox.id!, imagePathToSave!);
          return updatedBox.copyWith(imagePath: imagePathToSave);
        } else if (imagePathToSave != null && updatedBox.id != null) {
          // Ensure we keep the existing image path
          return updatedBox.copyWith(imagePath: imagePathToSave);
        }

        return updatedBox;
      } else {
        throw Exception('Failed to update pill box: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating pill box: $e');
      return null;
    }
  }

  // Delete pill box
  Future<bool> deletePillBox(String id) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Remove local mapping
        await _storage.delete(key: 'box_image_$id');
        return true;
      }

      return false;
    } catch (e) {
      print('Error deleting pill box: $e');
      return false;
    }
  }

  // Fetch a single pill box by ID
  Future<MedicationBox?> getBoxById(String boxId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/$boxId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final box = MedicationBox.fromJson(data);

        final localPath = await _getLocalImageMapping(boxId);
        if (localPath != null) {
          return box.copyWith(imagePath: localPath);
        }
        return box;
      }
      return null;
    } catch (e) {
      print('Error fetching box details: $e');
      return null;
    }
  }

  // Add medication to box using the specific POST endpoint
  // Supports: masterMedicationId, medicationName, or medicationId (user medication)
  Future<bool> addMedicationToBox(
    String boxId, {
    String? masterMedicationId,
    String? medicationName,
    String? medicationId,
  }) async {
    try {
      final token = await _getToken();

      // Build query parameters
      final queryParams = <String, String>{};
      if (masterMedicationId != null) {
        queryParams['masterMedicationId'] = masterMedicationId;
      } else if (medicationName != null) {
        queryParams['medicationName'] = medicationName;
      } else if (medicationId != null) {
        queryParams['medicationId'] = medicationId;
      } else {
        print('Error: No medication identifier provided');
        return false;
      }

      final uri = Uri.parse(
        '$_baseUrl/$boxId/medications',
      ).replace(queryParameters: queryParams);

      print('Adding medication to box: $uri');
      print('Query params: $queryParams');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print(
          'Failed to add medication: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error adding medication to box: $e');
      return false;
    }
  }

  // Remove medication from box using the specific DELETE endpoint
  Future<bool> removeMedicationFromBox(
    String boxId,
    String medicationId,
  ) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/$boxId/medications/$medicationId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error removing medication from box: $e');
      return false;
    }
  }

  // Helper to save image
  Future<String> _saveImageLocally(File imageFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${directory.path}/pill_box_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final fileName = 'box_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await imageFile.copy('${imagesDir.path}/$fileName');
    return savedImage.path;
  }

  // Helper to save image mapping
  Future<void> _saveLocalImageMapping(String boxId, String path) async {
    await _storage.write(key: 'box_image_$boxId', value: path);
  }

  // Helper to get image mapping
  Future<String?> _getLocalImageMapping(String boxId) async {
    return await _storage.read(key: 'box_image_$boxId');
  }

  // Find image for a medication ID
  Future<String?> getImageForMedication(String medicationId) async {
    try {
      final boxes = await getAllPillBoxes();
      for (var box in boxes) {
        if (box.medicationIds.contains(medicationId)) {
          return box.imagePath;
        }
      }
      return null;
    } catch (e) {
      print('Error finding image for medication: $e');
      return null;
    }
  }

  // Find image by Medication Name (backup if ID is not available)
  Future<String?> getImageForMedicationName(String medicationName) async {
    try {
      // TODO: Implement name-based lookup if needed
      // This would require fetching medication details for each box
      await getAllPillBoxes();
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get daily medications for a specific box
  Future<List<Map<String, dynamic>>> getDailyMedicationsForBox(
    String boxId,
    DateTime date,
  ) async {
    try {
      final token = await _getToken();
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final response = await http.get(
        Uri.parse('$_baseUrl/$boxId/daily?date=$dateStr'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching daily medications for box: $e');
      return [];
    }
  }
}
