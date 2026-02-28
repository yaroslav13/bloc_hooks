import 'package:bloc/bloc.dart';
import 'package:bloc_hooks/bloc_hooks.dart';
import 'package:bloc_hooks_example/cubits/todo_state.dart';
import 'package:bloc_hooks_example/data/todo_repository.dart';
import 'package:bloc_hooks_example/effects/todo_effect.dart';

final class TodoCubit extends Cubit<TodoState> with Effects<TodoEffect> {
  TodoCubit(this._repository) : super(const TodoState());

  final TodoRepository _repository;

  void loadTodos() {
    emit(state.copyWith(todos: _repository.getAll()));
  }

  Future<void> addTodo(String title) async {
    await _repository.add(title);
    emit(state.copyWith(todos: _repository.getAll()));
  }

  Future<void> toggleTodo(String id) async {
    final todo = _repository.getById(id);
    if (todo == null) return;

    await _repository.update(id, done: !todo.done);
    final todos = _repository.getAll();
    emit(state.copyWith(todos: todos));

    if (todos.every((t) => t.done) && todos.isNotEmpty) {
      emitEffect(AllTasksCompleted());
    }
  }

  Future<void> editTodo(String id, {String? title, String? description}) async {
    await _repository.update(id, title: title, description: description);
    emit(state.copyWith(todos: _repository.getAll()));
  }

  Future<void> removeTodo(String id) async {
    final removed = await _repository.remove(id);
    emit(state.copyWith(todos: _repository.getAll()));
    emitEffect(ShowUndoSnackBar(removed.title));
  }

  void openDetail(String id) => emitEffect(NavigateToDetail(id));
}
