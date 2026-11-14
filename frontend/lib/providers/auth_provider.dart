import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';
import '../shared/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null && _token != null;
  bool get isAdmin => _user?.isAdmin ?? false;

  AuthProvider() {
    initAuth();
  }

  Future<void> initAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      final userJson = prefs.getString('auth_user');

      if (_token != null && userJson != null) {
        _api.setToken(_token);
        _user = UserModel.fromJson(jsonDecode(userJson));
      }
    } catch (_) {
      _token = null;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String emailOrNpm, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.dio.post(
        Endpoints.login,
        data: {
          'email': emailOrNpm,
          'password': password,
        },
      );

      final data = response.data['data'];
      _token = data['token'];
      _user = UserModel.fromJson(data['user']);

      _api.setToken(_token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('auth_user', jsonEncode(_user!.toJson()));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data is Map && e.response?.data['message'] != null) {
          _errorMessage = e.response!.data['message'].toString();
        } else if (e.error != null) {
          _errorMessage = e.error.toString();
        } else {
          _errorMessage = e.message ?? 'Gagal terhubung ke server.';
        }
      } else {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String npm,
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.dio.post(
        Endpoints.register,
        data: {
          'npm': npm,
          'name': name,
          'email': email,
          'password': password,
        },
      );

      final data = response.data['data'];
      _token = data['token'];
      _user = UserModel.fromJson(data['user']);

      _api.setToken(_token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('auth_user', jsonEncode(_user!.toJson()));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data is Map && e.response?.data['message'] != null) {
          _errorMessage = e.response!.data['message'].toString();
        } else if (e.error != null) {
          _errorMessage = e.error.toString();
        } else {
          _errorMessage = e.message ?? 'Gagal terhubung ke server.';
        }
      } else {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.dio.post(Endpoints.logout);
    } catch (_) {}

    _user = null;
    _token = null;
    _api.setToken(null);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
