// lib/providers/auth_provider.dart
//
// Manages auth state: login, register, logout, and — crucially —
// token validation on app start via /api/accounts/me/.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sportsverse_app/api/api_client.dart';
import 'package:sportsverse_app/api/auth_api.dart';
import 'package:sportsverse_app/models/user.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  User? _currentUser;
  ProfileDetails? _profileDetails;
  bool _mustChangePassword = false;
  bool _isLoading = false;
  String? _errorMessage;

  // ── Getters ───────────────────────────────────────────────────────────────
  User? get currentUser => _currentUser;
  String? get token => _token;
  ProfileDetails? get profileDetails => _profileDetails;
  bool get mustChangePassword => _mustChangePassword;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Token validation on app start ─────────────────────────────────────────

  /// Called once in _SportsVerseAppState.initState().
  /// Loads the stored token → validates it against /me/ → populates user state.
  Future<void> initAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      await apiClient.init(); // loads token from SharedPreferences
      _token = apiClient.getToken();

      if (_token != null) {
        debugPrint('🔑 AuthProvider: token found, validating via /me/...');
        final meData = await authApi.getMe();

        if (meData != null) {
          // Token is still valid — hydrate user + profile
          _currentUser = User.fromJson(meData);
          if (meData['profile_details'] != null) {
            _profileDetails = ProfileDetails.fromJson(
              meData['profile_details'] as Map<String, dynamic>,
            );
          }
          _mustChangePassword =
              (meData['must_change_password'] as bool?) ?? false;
          debugPrint(
            '✅ AuthProvider: session restored for ${_currentUser?.username}',
          );
        } else {
          // Token expired / revoked — clear everything
          debugPrint('⚠️ AuthProvider: token invalid (401), clearing session');
          _token = null;
          _currentUser = null;
          _profileDetails = null;
          apiClient.setToken(null);
        }
      } else {
        debugPrint('🔑 AuthProvider: no stored token, showing login');
      }
    } catch (e) {
      // Network error during init → stay logged out, don't crash
      debugPrint('⚠️ AuthProvider.initAuth error: $e');
      _token = null;
      _currentUser = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<void> login(String emailOrUsername, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🚀 AuthProvider: login attempt for $emailOrUsername');
      final authResponse = await authApi.login(emailOrUsername, password);

      _currentUser = authResponse.user;
      _token = authResponse.token;
      _profileDetails = authResponse.profileDetails;
      _mustChangePassword = authResponse.mustChangePassword;
      debugPrint('✅ AuthProvider: login OK for ${authResponse.user.username}');
    } catch (e) {
      debugPrint('❌ AuthProvider.login error: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Register ──────────────────────────────────────────────────────────────

  Future<void> registerAcademy({
    required String organizationFullName,
    required String organizationAcademyName,
    required String organizationLocation,
    required String organizationMobileNumber,
    required String organizationEmailAddress,
    required String organizationSlug,
    required List<int> sportsOfferedIds,
    required String adminUsername,
    required String adminEmail,
    required String adminFirstName,
    required String adminLastName,
    required String adminPassword,
    File? academyLogoFile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authApi.registerAcademy(
        organizationFullName: organizationFullName,
        organizationAcademyName: organizationAcademyName,
        organizationLocation: organizationLocation,
        organizationMobileNumber: organizationMobileNumber,
        organizationEmailAddress: organizationEmailAddress,
        organizationSlug: organizationSlug,
        sportsOfferedIds: sportsOfferedIds,
        adminUsername: adminUsername,
        adminEmail: adminEmail,
        adminFirstName: adminFirstName,
        adminLastName: adminLastName,
        adminPassword: adminPassword,
        academyLogoFile: academyLogoFile,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> registerCoachStudentStaff({
    required String userType,
    required String username,
    String? email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? gender,
    String? dateOfBirth,
    String? parentName,
    String? parentPhoneNumber,
    String? parentEmail,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authApi.registerCoachStudentStaff(
        userType: userType,
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        gender: gender,
        dateOfBirth: dateOfBirth,
        parentName: parentName,
        parentPhoneNumber: parentPhoneNumber,
        parentEmail: parentEmail,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Misc ──────────────────────────────────────────────────────────────────

  void clearMustChangePassword() {
    _mustChangePassword = false;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _token = null;
    _profileDetails = null;
    _errorMessage = null;
    authApi.logout();
    notifyListeners();
  }

  void updateUser(User updatedUser) {
    _currentUser = updatedUser;
    notifyListeners();
  }
}