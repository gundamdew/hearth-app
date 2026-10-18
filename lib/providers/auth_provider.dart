import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'notifications_provider.dart';

final isSessionRestoringProvider = NotifierProvider<SessionRestoringNotifier, bool>(() {
  return SessionRestoringNotifier();
});

class SessionRestoringNotifier extends Notifier<bool> {
  @override
  bool build() {
    return true;
  }

  void setDone() {
    state = false;
  }
}

class AuthNotifier extends Notifier<AppUser?> {
  static const String _userStorageKey = 'hearth_saved_user_session';

  @override
  AppUser? build() {
    _restoreSession();
    return null;
  }

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_userStorageKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(savedJson);
        final user = AppUser.fromJson(data);
        if (state == null) {
          state = user;
          ref.read(pushNotificationServiceProvider).initAndRegisterUser(user);
        }
      }
    } catch (_) {
      // Ignore corrupted cached session
    } finally {
      ref.read(isSessionRestoringProvider.notifier).setDone();
    }
  }

  Future<void> login(AppUser user) async {
    state = user;
    ref.read(pushNotificationServiceProvider).initAndRegisterUser(user);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userStorageKey, jsonEncode(user.toJson()));
    } catch (_) {}
  }

  Future<void> logout() async {
    final user = state;
    if (user != null) {
      ref.read(pushNotificationServiceProvider).unregisterUser(user);
    }
    state = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userStorageKey);
    } catch (_) {}
  }

  Future<void> updateCurrentUser(AppUser updatedUser) async {
    state = updatedUser;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userStorageKey, jsonEncode(updatedUser.toJson()));
    } catch (_) {}
  }
}

final currentUserProvider = NotifierProvider<AuthNotifier, AppUser?>(() {
  return AuthNotifier();
});