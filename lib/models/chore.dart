class Chore {
  final String id;
  final String name;
  final String category;
  final String assignee; // 'Maya' или 'Jonah'
  final bool isDone;

  Chore({
    required this.id,
    required this.name,
    this.category = '',
    required this.assignee,
    this.isDone = false,
  });

  Chore copyWith({
    String? id,
    String? name,
    String? category,
    String? assignee,
    bool? isDone,
  }) {
    return Chore(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      assignee: assignee ?? this.assignee,
      isDone: isDone ?? this.isDone,
    );
  }
}