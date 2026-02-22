import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

/// A cubit managing a simple todo list.
final class TodoCubit extends Cubit<TodoState> {
  TodoCubit() : super(const TodoState());

  void addTodo(String title) => emit(
        state.copyWith(
          todos: [...state.todos, Todo(title: title, done: false)],
        ),
      );

  void toggleTodo(int index) {
    final updated = [...state.todos];
    final todo = updated[index];
    updated[index] = Todo(title: todo.title, done: !todo.done);
    emit(state.copyWith(todos: updated));
  }

  void removeTodo(int index) {
    final updated = [...state.todos]..removeAt(index);
    emit(state.copyWith(todos: updated));
  }

  void setFilter(TodoFilter filter) => emit(state.copyWith(filter: filter));
}

enum TodoFilter { all, active, completed }

@immutable
final class Todo {
  const Todo({required this.title, required this.done});

  final String title;
  final bool done;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Todo && title == other.title && done == other.done;

  @override
  int get hashCode => title.hashCode ^ done.hashCode;
}

@immutable
final class TodoState {
  const TodoState({
    this.todos = const [],
    this.filter = TodoFilter.all,
  });

  final List<Todo> todos;
  final TodoFilter filter;

  List<Todo> get filtered => switch (filter) {
        TodoFilter.all => todos,
        TodoFilter.active => todos.where((t) => !t.done).toList(),
        TodoFilter.completed => todos.where((t) => t.done).toList(),
      };

  int get completedCount => todos.where((t) => t.done).length;

  TodoState copyWith({
    List<Todo>? todos,
    TodoFilter? filter,
  }) =>
      TodoState(
        todos: todos ?? this.todos,
        filter: filter ?? this.filter,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoState &&
          filter == other.filter &&
          listEquals(todos, other.todos);

  @override
  int get hashCode => Object.hash(Object.hashAll(todos), filter);
}
