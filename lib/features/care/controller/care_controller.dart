import 'package:flutter/material.dart';
import 'package:capyadoo/core/model/care_models.dart';
import 'package:capyadoo/core/services/care_service.dart';

class CareController extends ChangeNotifier {
  List<CareRequest> _requests = [];
  List<SentCareRequest> _sentRequests = [];
  List<Patient> _patients = [];
  bool _isLoading = false;
  String? _error;

  List<CareRequest> get requests => _requests;
  List<SentCareRequest> get sentRequests => _sentRequests;
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
        CareService.getSentCareRequests(),
        CareService.getPatients(),
      ]);

      _requests = results[0] as List<CareRequest>;
      _sentRequests = results[1] as List<SentCareRequest>;
      _patients = results[2] as List<Patient>;
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

  Future<bool> cancelSentRequest(String id) async {
    _isLoading = true;
    notifyListeners();
    final success = await CareService.cancelSentRequest(id);
    if (success) {
      await loadData();
    } else {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }
}
