import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

class AuthNotifier extends Notifier<AppUser?> {
  @override
  AppUser? build() {
    return null; // Изначально никто не авторизован
  }

  void login(AppUser user) {
    state = user;
  }

  void logout() {
    state = null;
  }
}

final currentUserProvider = NotifierProvider<AuthNotifier, AppUser?>(() {
  return AuthNotifier();
});