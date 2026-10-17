import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String category; // 'budget', 'inventory', 'meals', 'cleaning'
  final String actorName; // 'vladimir', 'System', etc.
  final String? targetUser; // null if for all residents
  final DateTime createdAt;
  final List<String> readBy;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.actorName,
    this.targetUser,
    required this.createdAt,
    this.readBy = const [],
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? category,
    String? actorName,
    String? targetUser,
    DateTime? createdAt,
    List<String>? readBy,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      actorName: actorName ?? this.actorName,
      targetUser: targetUser ?? this.targetUser,
      createdAt: createdAt ?? this.createdAt,
      readBy: readBy ?? this.readBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'category': category,
      'actorName': actorName,
      'targetUser': targetUser,
      'createdAt': Timestamp.fromDate(createdAt),
      'readBy': readBy,
    };
  }

  factory AppNotification.fromFirestore(Map<String, dynamic> map, String documentId) {
    return AppNotification(
      id: documentId,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      category: map['category'] ?? 'budget',
      actorName: map['actorName'] ?? 'System',
      targetUser: map['targetUser'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readBy: List<String>.from(map['readBy'] ?? const []),
    );
  }
}
