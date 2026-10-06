import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../theme.dart';

class UsersNotifier extends Notifier<List<AppUser>> {
  @override
  List<AppUser> build() {
    // Базовые пользователи для сохранения работоспособности старых данных
    return [
      AppUser(id: 'u1', name: 'Maya', pinCode: '0000', color: AppTheme.terracotta),
      AppUser(id: 'u2', name: 'Jonah', pinCode: '1111', color: AppTheme.sage),
    ];
  }

  void addUser(String name, String pinCode, Color color) {
    final newUser = AppUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      pinCode: pinCode,
      color: color,
    );
    state = [...state, newUser];
  }

  void updateUser(String id, String newName, String newPin) {
    state = state.map((u) {
      if (u.id == id) return u.copyWith(name: newName, pinCode: newPin);
      return u;
    }).toList();
  }

  void deleteUser(String id) {
    state = state.where((u) => u.id != id).toList();
  }
}

final usersProvider = NotifierProvider<UsersNotifier, List<AppUser>>(() => UsersNotifier());