import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'notifications_provider.dart';

class AuthNotifier extends Notifier<AppUser?> {
  @override
  AppUser? build() {
    return null; // Изначально никто не авторизован
  }

  void login(AppUser user) {
    state = user;
    ref.read(pushNotificationServiceProvider).initAndRegisterUser(user);
  }

  void logout() {
    final user = state;
    if (user != null) {
      ref.read(pushNotificationServiceProvider).unregisterUser(user);
    }
    state = null;
  }

  void updateCurrentUser(AppUser updatedUser) {
    state = updatedUser;
  }
}

final currentUserProvider = NotifierProvider<AuthNotifier, AppUser?>(() {
  return AuthNotifier();
});