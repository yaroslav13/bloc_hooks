import 'package:bloc_hooks_example/models/todo.dart';

/// A simple in-memory data provider for todos.
///
/// In a real app this would talk to a REST API, local database, etc.
class TodoRepository {
  final _todos = <String, Todo>{};
  int _nextId = 0;

  List<Todo> getAll() => _todos.values.toList();

  Todo? getById(String id) => _todos[id];

  Future<Todo> add(String title) async {
    // Simulate network delay.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final todo = Todo(id: '${_nextId++}', title: title, done: false);
    _todos[todo.id] = todo;
    return todo;
  }

  Future<Todo> update(
    String id, {
    String? title,
    String? description,
    bool? done,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final existing = _todos[id];
    if (existing == null) throw StateError('Todo $id not found');

    final updated = existing.copyWith(
      title: title,
      description: description,
      done: done,
    );
    _todos[id] = updated;
    return updated;
  }

  Future<Todo> remove(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final removed = _todos.remove(id);
    if (removed == null) throw StateError('Todo $id not found');
    return removed;
  }
}
