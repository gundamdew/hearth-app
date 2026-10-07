import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

final usersProvider = StreamProvider<List<AppUser>>((ref) {
  return FirebaseFirestore.instance.collection('users').snapshots().map(
    (snapshot) => snapshot.docs.map((doc) => AppUser.fromFirestore(doc.data(), doc.id)).toList()
  );
});

final usersControllerProvider = Provider((ref) => UsersController());

class UsersController {
  final _db = FirebaseFirestore.instance;

  Future<void> addUser(String name, String pinCode, Color color) async {
    final user = AppUser(id: '', name: name, pinCode: pinCode, color: color);
    await _db.collection('users').add(user.toMap());
  }

  Future<void> updateUser(String id, String newName, String newPin) async {
    await _db.collection('users').doc(id).update({
      'name': newName,
      'pinCode': newPin,
    });
  }

  Future<void> deleteUser(String id) async {
    await _db.collection('users').doc(id).delete();
  }
}