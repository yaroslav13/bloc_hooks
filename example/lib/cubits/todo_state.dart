import 'package:bloc_hooks_example/models/todo.dart';

final class TodoState {
  const TodoState({this.todos = const []});

  final List<Todo> todos;

  int get completedCount => todos.where((t) => t.done).length;
  int get activeCount => todos.where((t) => !t.done).length;

  TodoState copyWith({List<Todo>? todos}) =>
      TodoState(todos: todos ?? this.todos);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoState && _listEquals(todos, other.todos);

  @override
  int get hashCode => Object.hashAll(todos);

  static bool _listEquals(List<Todo> a, List<Todo> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
