class Note {
  final int? id;
  final String title;
  final String description;
  final String createdAt;

  const Note({
    this.id,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'created_at': createdAt,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      createdAt: map['created_at'] as String,
    );
  }
}
