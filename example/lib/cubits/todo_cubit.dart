import 'package:bloc/bloc.dart';
import 'package:bloc_hooks/bloc_hooks.dart';
import 'package:bloc_hooks_example/cubits/todo_state.dart';
import 'package:bloc_hooks_example/effects/todo_effect.dart';
import 'package:bloc_hooks_example/models/todo.dart';

final class TodoCubit extends Cubit<TodoState> with Effects<TodoEffect> {
  TodoCubit() : super(const TodoState());

  int _nextId = 0;

  void addTodo(String title) {
    final todo = Todo(id: '${_nextId++}', title: title, done: false);
    emit(state.copyWith(todos: [...state.todos, todo]));
  }

  void toggleTodo(String id) {
    final updated = state.todos.map((t) {
      return t.id == id ? t.copyWith(done: !t.done) : t;
    }).toList();

    emit(state.copyWith(todos: updated));

    if (updated.every((t) => t.done) && updated.isNotEmpty) {
      emitEffect(AllTasksCompleted());
    }
  }

  void removeTodo(String id) {
    final todo = state.todos.firstWhere((t) => t.id == id);
    final updated = state.todos.where((t) => t.id != id).toList();
    emit(state.copyWith(todos: updated));
    emitEffect(ShowUndoSnackBar(todo.title));
  }
}
