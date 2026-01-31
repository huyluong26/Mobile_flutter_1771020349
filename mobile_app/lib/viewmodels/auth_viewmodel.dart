import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../models/auth_models.dart';
import '../services/api_service.dart';

/// Authentication state
enum AuthState { initial, loading, authenticated, unauthenticated, error }

/// Authentication ViewModel
class AuthViewModel extends ChangeNotifier {
  AuthState _state = AuthState.initial;
  UserProfile? _currentUser;
  String? _errorMessage;
  String? _token;

  // Getters
  AuthState get state => _state;
  UserProfile? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  /// Login with username and password
  Future<bool> login(String username, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // ApiService now returns Map<String, dynamic>
      final response = await apiService.login(username, password);

      _token = response['token'];

      // Lưu token vào SharedPreferences để các API khác có thể sử dụng
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);

      // Fetch user profile after login
      try {
        _currentUser = await apiService.getUserProfile();
        print(
          '✅ Profile loaded: ${_currentUser?.fullName}, Role: ${_currentUser?.role}',
        );
      } catch (e) {
        print('❌ Profile fetch failed: $e');
        // Fallback if profile fetch fails
        _currentUser = UserProfile(
          id: 0,
          fullName: response['username'] ?? username,
          username: response['username'] ?? username,
          email: response['email'] ?? '',
        );
      }

      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  /// Register new user
  Future<bool> register(
    String username,
    String fullName,
    String email,
    String password,
  ) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // ApiService now takes individual params
      await apiService.register(username, email, password, fullName);

      // Auto-login after registration
      return await login(username, password);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  /// Update User Profile (FullName & Avatar)
  Future<bool> updateUserInfo({String? fullName, File? imageFile}) async {
    // KHÔNG thay đổi _state để tránh AuthWrapper redirect về login
    _errorMessage = null;

    try {
      String? avatarUrl;
      if (imageFile != null) {
        print('📤 Uploading avatar...');
        avatarUrl = await apiService.uploadAvatar(imageFile);
        print('📤 Upload result: $avatarUrl');
      }

      print('📝 Updating profile: fullName=$fullName, avatarUrl=$avatarUrl');
      final success = await apiService.updateProfile(
        fullName: fullName,
        avatarUrl: avatarUrl,
      );
      print('📝 Update result: $success');

      if (success) {
        await refreshProfile();
        return true;
      } else {
        _errorMessage = "Update failed";
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Update error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Refresh user profile data
  Future<void> refreshProfile() async {
    if (!isAuthenticated) {
      print('⚠️ refreshProfile: Not authenticated, skipping');
      return;
    }
    try {
      _currentUser = await apiService.getUserProfile();
      print('🔄 refreshProfile: avatarUrl=${_currentUser?.avatarUrl}');
      _state = AuthState.authenticated; // Ensure state
      notifyListeners();
    } catch (e) {
      print('❌ refreshProfile error: $e');
      // Keep existing cache if refresh fails
    }
  }

  /// Logout user
  Future<void> logout() async {
    // Xóa token khỏi SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    _token = null;
    _currentUser = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    if (_state == AuthState.error) {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }
}
