import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

final usersProvider = StreamProvider<List<AppUser>>((ref) {
  return FirebaseFirestore.instance.collection('users').snapshots().map(
    (snapshot) => snapshot.docs.map((doc) => AppUser.fromFirestore(doc.data(), doc.id)).toList()
  );
});

final usersByNameMapProvider = Provider<Map<String, AppUser>>((ref) {
  final users = ref.watch(usersProvider).value ?? [];
  return {for (final u in users) u.name: u};
});

final usersControllerProvider = Provider((ref) => UsersController());

class UsersController {
  final _db = FirebaseFirestore.instance;

  Future<void> addUser(String name, String pinCode, Color color, [String? avatar]) async {
    final user = AppUser(id: '', name: name, pinCode: pinCode, color: color, avatar: avatar);
    await _db.collection('users').add(user.toMap());
  }

  Future<void> updateUser(String id, String newName, String newPin, [Color? color, String? avatar]) async {
    final data = <String, dynamic>{
      'name': newName,
      'pinCode': newPin,
    };
    if (color != null) {
      // ignore: deprecated_member_use
      data['color'] = color.value;
    }
    if (avatar != null) {
      data['avatar'] = avatar;
    }
    await _db.collection('users').doc(id).update(data);
  }

  Future<void> deleteUser(String id) async {
    await _db.collection('users').doc(id).delete();
  }
}