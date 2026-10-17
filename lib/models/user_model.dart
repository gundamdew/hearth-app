import 'package:flutter/material.dart';

class AppUser {
  final String id;
  final String name;
  final String pinCode;
  final Color color;
  final String? avatar;
  final List<String> fcmTokens;
  final bool notificationsEnabled;

  AppUser({
    required this.id,
    required this.name,
    required this.pinCode,
    required this.color,
    this.avatar,
    this.fcmTokens = const [],
    this.notificationsEnabled = true,
  });

  AppUser copyWith({
    String? id,
    String? name,
    String? pinCode,
    Color? color,
    String? avatar,
    List<String>? fcmTokens,
    bool? notificationsEnabled,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      pinCode: pinCode ?? this.pinCode,
      color: color ?? this.color,
      avatar: avatar ?? this.avatar,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'pinCode': pinCode,
      // ignore: deprecated_member_use
      'color': color.value,
      'avatar': avatar,
      'fcmTokens': fcmTokens,
      'notificationsEnabled': notificationsEnabled,
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
      fcmTokens: List<String>.from(map['fcmTokens'] ?? const []),
      notificationsEnabled: map['notificationsEnabled'] ?? true,
    );
  }
}