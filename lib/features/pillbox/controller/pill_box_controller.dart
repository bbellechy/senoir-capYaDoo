import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:capyadoo/core/model/medication_box.dart';
import 'package:capyadoo/core/services/pill_box_service.dart';

class PillBoxController extends ChangeNotifier {
  final PillBoxService _service = PillBoxService();

  List<MedicationBox> _pillBoxes = [];
  List<MedicationBox> get pillBoxes => _pillBoxes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadPillBoxes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pillBoxes = await _service.getAllPillBoxes();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPillBox(
    String name,
    String? description,
    File? imageFile,
    List<int> days,
    List<String> intakePeriods,
    String intakeTiming,
  ) async {
    print('=== Controller: addPillBox called ===');
    print('Name: $name');
    print('Description: $description');
    print('Has image: ${imageFile != null}');
    print('Days: $days');
    print('IntakePeriods: $intakePeriods');
    print('IntakeTiming: $intakeTiming');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newBox = MedicationBox(
        name: name,
        description: description,
        days: days,
        intakePeriods: intakePeriods,
        intakeTiming: intakeTiming,
      );

      print('Controller: Calling service.createPillBox...');
      final created = await _service
          .createPillBox(newBox, imageFile)
          .timeout(const Duration(seconds: 15));
      print(
        'Controller: Service returned: ${created != null ? "SUCCESS" : "NULL"}',
      );

      if (created != null) {
        _pillBoxes.add(created);
        notifyListeners();
        print('Controller: Pill box added successfully');
        return true;
      } else {
        _error = 'ไม่สามารถสร้างกล่องยาได้ กรุณาลองใหม่อีกครั้ง';
        print('Controller: Error - created is null');
        return false;
      }
    } on TimeoutException catch (e, stackTrace) {
      print('=== Controller: TimeoutException caught ===');
      print('Exception: $e');
      print('Stack trace: $stackTrace');
      _error = 'การเชื่อมต่อช้าเกินไป กรุณาลองใหม่อีกครั้ง';
      return false;
    } catch (e, stackTrace) {
      print('=== Controller: Exception caught ===');
      print('Exception type: ${e.runtimeType}');
      print('Exception: $e');
      print('Stack trace: $stackTrace');

      String errorMsg = e.toString();
      // Extract meaningful error message
      if (errorMsg.contains('Exception:')) {
        errorMsg = errorMsg.split('Exception:').last.trim();
      }
      _error = errorMsg.isNotEmpty
          ? errorMsg
          : 'ไม่สามารถสร้างกล่องยาได้ กรุณาลองใหม่อีกครั้ง';
      print('Controller: Final error message: $_error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
      print('=== Controller: addPillBox finished ===');
    }
  }

  Future<bool> updatePillBox(MedicationBox box, File? newImageFile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _service.updatePillBox(box, newImageFile);
      if (updated != null) {
        final index = _pillBoxes.indexWhere((b) => b.id == box.id);
        if (index != -1) {
          _pillBoxes[index] = updated;
        }
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update pill box';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePillBox(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _service.deletePillBox(id);
      if (success) {
        _pillBoxes.removeWhere((b) => b.id == id);
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to delete pill box';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addMedicationToBox(
    String boxId, {
    String? masterMedicationId,
    String? medicationName,
    String? medicationId,
  }) async {
    final success = await _service.addMedicationToBox(
      boxId,
      masterMedicationId: masterMedicationId,
      medicationName: medicationName,
      medicationId: medicationId,
    );
    if (success) {
      // Reload boxes to get updated medication list
      await loadPillBoxes();
    }
    return success;
  }

  Future<bool> removeMedicationFromBox(
    String boxId,
    String medicationId,
  ) async {
    final success = await _service.removeMedicationFromBox(boxId, medicationId);
    if (success) {
      final index = _pillBoxes.indexWhere((b) => b.id == boxId);
      if (index != -1) {
        final box = _pillBoxes[index];
        final updatedMedIds = List<String>.from(box.medicationIds)
          ..remove(medicationId);
        _pillBoxes[index] = box.copyWith(medicationIds: updatedMedIds);
        notifyListeners();
      }
    }
    return success;
  }
}
