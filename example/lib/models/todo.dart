final class Todo {
  const Todo({
    required this.id,
    required this.title,
    this.description = '',
    required this.done,
  });

  final String id;
  final String title;
  final String description;
  final bool done;

  Todo copyWith({String? title, String? description, bool? done}) => Todo(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        done: done ?? this.done,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Todo &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          done == other.done;

  @override
  int get hashCode => Object.hash(id, title, description, done);
}
