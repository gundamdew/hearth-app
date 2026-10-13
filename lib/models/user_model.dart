import 'package:flutter/material.dart';

class AppUser {
  final String id;
  final String name;
  final String pinCode;
  final Color color;
  final String? avatar;

  AppUser({
    required this.id,
    required this.name,
    required this.pinCode,
    required this.color,
    this.avatar,
  });

  AppUser copyWith({
    String? id,
    String? name,
    String? pinCode,
    Color? color,
    String? avatar,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      pinCode: pinCode ?? this.pinCode,
      color: color ?? this.color,
      avatar: avatar ?? this.avatar,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'pinCode': pinCode,
      // ignore: deprecated_member_use
      'color': color.value,
      'avatar': avatar,
    };
  }

  factory AppUser.fromFirestore(Map<String, dynamic> map, String documentId) {
    return AppUser(
      id: documentId,
      name: map['name'] ?? 'Nieznany',
      pinCode: map['pinCode'] ?? '0000',
      // ignore: deprecated_member_use
      color: Color(map['color'] ?? 0xFFB3C5B8),
      avatar: map['avatar'],
    );
  }
}