import 'package:flutter/material.dart';
import 'package:capyadoo/core/model/care_models.dart';
import 'package:capyadoo/core/services/care_service.dart';

class CareController extends ChangeNotifier {
  List<CareRequest> _requests = [];
  List<Patient> _patients = [];
  bool _isLoading = false;
  String? _error;

  List<CareRequest> get requests => _requests;
  List<Patient> get patients => _patients;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        CareService.getCareRequests(),
        CareService.getPatients(),
      ]);

      _requests = results[0] as List<CareRequest>;
      _patients = results[1] as List<Patient>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendRequest(String username) async {
    _isLoading = true;
    notifyListeners();
    final success = await CareService.sendCareRequest(username);
    if (success) {
      await loadData();
    } else {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }

  Future<bool> respondToRequest(String id, bool accept) async {
    _isLoading = true;
    notifyListeners();
    final success = await CareService.respondToRequest(id, accept);
    if (success) {
      await loadData();
    } else {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }
}
