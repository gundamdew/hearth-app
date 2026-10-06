import 'package:flutter/material.dart';

class AppUser {
  final String id;
  final String name;
  final String pinCode;
  final Color color;

  AppUser({
    required this.id,
    required this.name,
    required this.pinCode,
    required this.color,
  });

  AppUser copyWith({String? id, String? name, String? pinCode, Color? color}) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      pinCode: pinCode ?? this.pinCode,
      color: color ?? this.color,
    );
  }
}