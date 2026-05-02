// lib/providers/chatbot_provider.dart
//
// ChatbotProvider — manages chatbot state for the SportsVerse app.
//
// ── Data Isolation Guarantee ──────────────────────────────────────────────────
// Messages are stored under a USER-SCOPED key: 'chatbot_msg_<userId>'
// Every call to initialize() does THREE things in order:
//   1. Clears all in-memory messages immediately
//   2. Clears the stale global key 'chatbot_messages' (legacy cleanup)
//   3. Loads ONLY messages stored under the current user's scoped key
//
// This means: switching users → different key → zero message leakage.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportsverse_app/models/chat_message.dart';
import 'package:sportsverse_app/providers/auth_provider.dart';
import 'package:sportsverse_app/services/ai_service.dart';

class ChatbotProvider with ChangeNotifier {
  static const int _maxMessages = 20;

  // Legacy key — written by the old implementation; we clean it up on init.
  static const String _legacyKey = 'chatbot_messages';

  // User-scoped key — isolates each user's history on the device.
  String _scopedKey = '';

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  bool _sessionExpired = false;
  int _sessionCount = 0;
  String _userRole = '';
  int? _currentUserId;

  // ── Getters ───────────────────────────────────────────────────────────────

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get sessionExpired => _sessionExpired;
  bool get isRateLimited => _sessionCount >= _maxMessages;
  String get userRole => _userRole;

  // ── Initialise (called every time the chat sheet opens) ───────────────────

  Future<void> initialize(AuthProvider auth) async {
    final user = auth.currentUser;
    final incomingUserId = user?.id;

    // ── Step 1: Detect user switch — wipe memory immediately ─────────────────
    // If the user changed (or no user), clear everything before loading anything.
    if (incomingUserId != _currentUserId) {
      _messages.clear();
      _sessionCount = 0;
      _error = null;
      _sessionExpired = false;
      _currentUserId = incomingUserId;
    }

    // ── Step 2: Set up scoped storage key ────────────────────────────────────
    _userRole = user?.userType ?? '';
    _scopedKey = incomingUserId != null
        ? 'chatbot_msg_${incomingUserId}'
        : '';

    // ── Step 3: Clean up the legacy unscoped key (one-time migration) ────────
    _cleanLegacyKey();

    // ── Step 4: Load only THIS user's persisted messages ─────────────────────
    if (_scopedKey.isNotEmpty) {
      await _loadPersistedMessages();
    }

    notifyListeners();
  }

  // ── Wipe all data (call on logout) ────────────────────────────────────────

  Future<void> onLogout() async {
    _messages.clear();
    _sessionCount = 0;
    _error = null;
    _sessionExpired = false;
    _currentUserId = null;
    _scopedKey = '';
    _userRole = '';
    // NOTE: We intentionally do NOT delete the scoped prefs key here.
    // The user may log back in and want their history. It will be wiped
    // only when they explicitly tap "Clear chat".
    notifyListeners();
  }

  // ── Send message ──────────────────────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    if (_sessionCount >= _maxMessages) {
      _error = 'You have reached the maximum of $_maxMessages messages per session. '
          'Please close and reopen the chat to continue.';
      notifyListeners();
      return;
    }

    _messages.add(ChatMessage.fromUser(trimmed));
    _sessionCount++;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await chatbotService.sendQuery(trimmed);
      _messages.add(ChatMessage.fromAssistant(response));
    } on SessionExpiredException {
      _sessionExpired = true;
      _error = 'Your session has expired. Please log in again.';
    } on ChatbotException catch (e) {
      _messages.add(ChatMessage.fromAssistant(e.message));
    } catch (e) {
      _messages.add(
        ChatMessage.fromAssistant(
          'The AI assistant is temporarily unavailable. Please use the app directly.',
        ),
      );
    } finally {
      _isLoading = false;
      await _persistMessages();
      notifyListeners();
    }
  }

  // ── Clear error ───────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    _sessionExpired = false;
    notifyListeners();
  }

  // ── Clear this user's messages (explicit "Clear chat" button) ─────────────

  Future<void> clearMessages() async {
    _messages.clear();
    _sessionCount = 0;
    _error = null;
    _sessionExpired = false;
    if (_scopedKey.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_scopedKey);
    }
    notifyListeners();
  }

  // ── Persistence (scoped per user) ─────────────────────────────────────────

  Future<void> _persistMessages() async {
    if (_scopedKey.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final last20 = _messages.length > 20
          ? _messages.sublist(_messages.length - 20)
          : _messages;
      final encoded = jsonEncode(last20.map((m) => m.toJson()).toList());
      await prefs.setString(_scopedKey, encoded);
    } catch (_) {
      // Non-fatal
    }
  }

  Future<void> _loadPersistedMessages() async {
    if (_scopedKey.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_scopedKey);
      if (raw == null) return;
      final list = jsonDecode(raw) as List<dynamic>;
      _messages.clear();
      _messages.addAll(
        list.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)),
      );
    } catch (_) {
      // Ignore corrupt data — start fresh
      _messages.clear();
    }
  }

  /// Removes the old unscoped 'chatbot_messages' key left by the previous version.
  Future<void> _cleanLegacyKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_legacyKey)) {
        await prefs.remove(_legacyKey);
      }
    } catch (_) {}
  }
}
