final class Todo {
  const Todo({required this.id, required this.title, required this.done});

  final String id;
  final String title;
  final bool done;

  Todo copyWith({String? title, bool? done}) => Todo(
        id: id,
        title: title ?? this.title,
        done: done ?? this.done,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Todo &&
          id == other.id &&
          title == other.title &&
          done == other.done;

  @override
  int get hashCode => Object.hash(id, title, done);
}
