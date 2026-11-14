import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';
import '../shared/models/location_model.dart';
import '../shared/models/picked_photo.dart';
import '../shared/models/report_model.dart';
import '../shared/models/stats_model.dart';

class AdminProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  AdminStatsModel? _stats;
  List<ReportModel> _queueReports = [];
  List<Map<String, dynamic>> _technicians = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _auditLogs = [];
  List<LocationModel> _locations = [];

  bool _isLoading = false;
  String? _errorMessage;

  AdminStatsModel? get stats => _stats;
  List<ReportModel> get queueReports => _queueReports;
  List<Map<String, dynamic>> get technicians => _technicians;
  List<Map<String, dynamic>> get users => _users;
  List<Map<String, dynamic>> get auditLogs => _auditLogs;
  List<LocationModel> get locations => _locations;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.dio.get(Endpoints.adminStats);
      _stats = AdminStatsModel.fromJson(res.data['data']);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchReportQueue({String? status}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.dio.get(
        Endpoints.reports,
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          'sort_by': 'priority',
          'per_page': 50,
        },
      );
      final list = res.data['data']['items'] as List;
      _queueReports = list.map((r) => ReportModel.fromJson(r)).toList();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTechnicians() async {
    try {
      final res = await _api.dio.get(Endpoints.adminTechnicians);
      _technicians = List<Map<String, dynamic>>.from(res.data['data']);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchUsers() async {
    try {
      final res = await _api.dio.get(Endpoints.adminUsers);
      _users = List<Map<String, dynamic>>.from(res.data['data']);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchAuditLogs() async {
    try {
      final res = await _api.dio.get(Endpoints.adminAuditLogs);
      _auditLogs = List<Map<String, dynamic>>.from(res.data['data']);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchLocations() async {
    try {
      final res = await _api.dio.get(Endpoints.locations);
      final flat = res.data['data']['flat'] as List;
      _locations = flat.map((l) => LocationModel.fromJson(l)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> verifyReport(int reportId, String note) async {
    try {
      await _api.dio.patch('/reports/$reportId/verify', data: {'note': note});
      await fetchReportQueue();
      await fetchDashboardStats();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignTechnician(int reportId, int technicianId, String notes) async {
    try {
      await _api.dio.patch(
        '/reports/$reportId/assign',
        data: {'technician_id': technicianId, 'notes': notes},
      );
      await fetchReportQueue();
      await fetchDashboardStats();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeReport(int reportId, String note, PickedPhoto? afterPhoto, {String? presetPhotoPath}) async {
    try {
      final formData = FormData.fromMap({'note': note});
      if (afterPhoto != null) {
        formData.files.add(
          MapEntry(
            'after_photo',
            MultipartFile.fromBytes(afterPhoto.bytes, filename: afterPhoto.name),
          ),
        );
      } else if (presetPhotoPath != null && presetPhotoPath.isNotEmpty) {
        formData.fields.add(MapEntry('photo_path', presetPhotoPath));
      } else {
        // Fallback demo proof photo
        formData.fields.add(const MapEntry('photo_path', 'uploads/photos/demo_after_chair.jpg'));
      }

      // Use POST so PHP web servers parse multipart/form-data cleanly
      await _api.dio.post('/reports/$reportId/complete', data: formData);
      await fetchReportQueue();
      await fetchDashboardStats();
      return true;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data is Map && e.response?.data['message'] != null) {
          _errorMessage = e.response!.data['message'].toString();
        } else if (e.error != null) {
          _errorMessage = e.error.toString();
        } else {
          _errorMessage = e.message ?? 'Gagal menyelesaikan laporan.';
        }
      } else {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectReport(int reportId, String reason) async {
    try {
      await _api.dio.patch('/reports/$reportId/reject', data: {'reason': reason});
      await fetchReportQueue();
      await fetchDashboardStats();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> addLocation(String building, String floor, String room, String code) async {
    try {
      await _api.dio.post(
        Endpoints.locations,
        data: {'building': building, 'floor': floor, 'room': room, 'code': code},
      );
      await fetchLocations();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> addTechnician(String name, String phone, String specialty) async {
    try {
      await _api.dio.post(
        Endpoints.adminTechnicians,
        data: {'name': name, 'phone': phone, 'specialty': specialty},
      );
      await fetchTechnicians();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> getQrPrintData(int locationId) async {
    try {
      final res = await _api.dio.get('/locations/$locationId/qr');
      return res.data['data'];
    } catch (_) {
      return null;
    }
  }
}
