import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';
import '../shared/models/category_model.dart';
import '../shared/models/location_model.dart';
import '../shared/models/picked_photo.dart';
import '../shared/models/report_model.dart';

class ReportsProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<ReportModel> _reports = [];
  List<ReportModel> _myReports = [];
  List<CategoryModel> _categories = [];
  List<LocationModel> _locations = [];
  Map<String, dynamic> _locationsTree = {};

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // Filter & Search states
  String? _selectedBuilding;
  int? _selectedCategoryId;
  String? _selectedStatus;
  String _searchQuery = '';
  String _sortBy = 'priority'; // 'priority' | 'latest'
  int _currentPage = 1;
  int _totalPages = 1;

  List<ReportModel> get reports => _reports;
  List<ReportModel> get myReports => _myReports;
  List<CategoryModel> get categories => _categories;
  List<LocationModel> get locations => _locations;
  Map<String, dynamic> get locationsTree => _locationsTree;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;

  String? get selectedBuilding => _selectedBuilding;
  int? get selectedCategoryId => _selectedCategoryId;
  String? get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  Future<void> initData() async {
    await Future.wait([
      fetchCategories(),
      fetchLocations(),
      fetchReports(reset: true),
      fetchMyReports(),
    ]);
  }

  Future<void> fetchCategories() async {
    try {
      final res = await _api.dio.get(Endpoints.categories);
      final list = res.data['data'] as List;
      _categories = list.map((c) => CategoryModel.fromJson(c)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchLocations() async {
    try {
      final res = await _api.dio.get(Endpoints.locations);
      final flat = res.data['data']['flat'] as List;
      _locations = flat.map((l) => LocationModel.fromJson(l)).toList();
      _locationsTree = res.data['data']['tree'] ?? {};
      notifyListeners();
    } catch (_) {}
  }

  Future<LocationModel?> resolveQrCode(String code, String sig) async {
    try {
      final res = await _api.dio.get(
        Endpoints.resolveQr,
        queryParameters: {'code': code, 'sig': sig},
      );
      return LocationModel.fromJson(res.data['data']);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<void> fetchReports({bool reset = false}) async {
    if (reset) {
      _currentPage = 1;
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      if (_currentPage >= _totalPages || _isLoadingMore) return;
      _isLoadingMore = true;
      _currentPage++;
      notifyListeners();
    }

    try {
      final res = await _api.dio.get(
        Endpoints.reports,
        queryParameters: {
          if (_selectedBuilding != null && _selectedBuilding!.isNotEmpty) 'building': _selectedBuilding,
          if (_selectedCategoryId != null) 'category_id': _selectedCategoryId,
          if (_selectedStatus != null && _selectedStatus!.isNotEmpty) 'status': _selectedStatus,
          if (_searchQuery.isNotEmpty) 'search': _searchQuery,
          'sort_by': _sortBy,
          'page': _currentPage,
          'per_page': 15,
        },
      );

      final data = res.data['data'];
      final items = (data['items'] as List).map((r) => ReportModel.fromJson(r)).toList();
      _totalPages = data['total_pages'] ?? 1;

      if (reset) {
        _reports = items;
      } else {
        _reports.addAll(items);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyReports() async {
    try {
      final res = await _api.dio.get(Endpoints.myReports);
      final list = res.data['data'] as List;
      _myReports = list.map((r) => ReportModel.fromJson(r)).toList();
      notifyListeners();
    } catch (_) {}
  }

  void setFilters({
    String? building,
    int? categoryId,
    String? status,
    String? search,
    String? sort,
  }) {
    if (building != null) _selectedBuilding = building.isEmpty ? null : building;
    if (categoryId != null) _selectedCategoryId = categoryId == 0 ? null : categoryId;
    if (status != null) _selectedStatus = status.isEmpty ? null : status;
    if (search != null) _searchQuery = search;
    if (sort != null) _sortBy = sort;
    fetchReports(reset: true);
  }

  void clearFilters() {
    _selectedBuilding = null;
    _selectedCategoryId = null;
    _selectedStatus = null;
    _searchQuery = '';
    _sortBy = 'priority';
    fetchReports(reset: true);
  }

  Future<List<ReportModel>> checkSimilarReports(int locationId, int categoryId) async {
    try {
      final res = await _api.dio.get(
        Endpoints.similarReports,
        queryParameters: {
          'location_id': locationId,
          'category_id': categoryId,
        },
      );
      final list = res.data['data']['similar_reports'] as List;
      return list.map((r) => ReportModel.fromJson(r)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> toggleUpvote(ReportModel report) async {
    final originalState = report.userHasUpvoted;
    final originalCount = report.upvoteCount;
    final originalScore = report.priorityScore;

    // Optimistic UI update
    report.userHasUpvoted = !originalState;
    report.upvoteCount += originalState ? -1 : 1;
    report.priorityScore += originalState ? -2 : 2;
    notifyListeners();

    try {
      if (originalState) {
        // Cancel upvote
        final res = await _api.dio.delete('/reports/${report.id}/upvote');
        report.upvoteCount = res.data['data']['upvote_count'];
        report.priorityScore = res.data['data']['priority_score'];
      } else {
        // Upvote
        final res = await _api.dio.post('/reports/${report.id}/upvote');
        report.upvoteCount = res.data['data']['upvote_count'];
        report.priorityScore = res.data['data']['priority_score'];
      }
      notifyListeners();
      return true;
    } catch (e) {
      // Revert optimistic update on failure
      report.userHasUpvoted = originalState;
      report.upvoteCount = originalCount;
      report.priorityScore = originalScore;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> createReport({
    required int locationId,
    required int categoryId,
    required String title,
    required String description,
    required String urgencyLevel,
    List<PickedPhoto>? pickedFiles,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final formData = FormData.fromMap({
        'location_id': locationId,
        'category_id': categoryId,
        'title': title,
        'description': description,
        'urgency_level': urgencyLevel,
      });

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        for (var i = 0; i < pickedFiles.length; i++) {
          final file = pickedFiles[i];
          formData.files.add(
            MapEntry(
              'photos[]',
              MultipartFile.fromBytes(
                file.bytes,
                filename: file.name,
              ),
            ),
          );
        }
      }

      await _api.dio.post(Endpoints.reports, data: formData);
      await fetchReports(reset: true);
      await fetchMyReports();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<ReportModel?> getReportDetail(int id) async {
    try {
      final res = await _api.dio.get('/reports/$id');
      return ReportModel.fromJson(res.data['data']);
    } catch (_) {
      return null;
    }
  }

  Future<bool> submitRating(int reportId, int rating, String review) async {
    try {
      await _api.dio.post(
        '/reports/$reportId/rating',
        data: {'rating': rating, 'review': review},
      );
      await fetchMyReports();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
