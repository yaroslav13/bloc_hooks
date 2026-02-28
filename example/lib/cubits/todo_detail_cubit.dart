import 'package:bloc/bloc.dart';
import 'package:bloc_hooks/bloc_hooks.dart';
import 'package:bloc_hooks_example/cubits/todo_detail_state.dart';
import 'package:bloc_hooks_example/data/todo_repository.dart';
import 'package:bloc_hooks_example/effects/todo_detail_effect.dart';

/// A page-level cubit that manages a single todo on the detail screen.
///
/// Bound with [bindBloc] inside `TodoDetailPage` and automatically
/// disposed when the user navigates away.
final class TodoDetailCubit extends Cubit<TodoDetailState>
    with Effects<TodoDetailEffect> {
  TodoDetailCubit(this._repository) : super(const TodoDetailState());

  final TodoRepository _repository;

  void load(String id) {
    final todo = _repository.getById(id);
    emit(TodoDetailState(todo: todo, isLoading: false));
  }

  Future<void> toggleDone() async {
    final todo = state.todo;
    if (todo == null) return;

    final updated = await _repository.update(todo.id, done: !todo.done);
    emit(state.copyWith(todo: updated));
    emitEffect(TodoStatusChanged(title: updated.title, done: updated.done));
  }

  Future<void> edit({String? title, String? description}) async {
    final todo = state.todo;
    if (todo == null) return;

    final updated = await _repository.update(
      todo.id,
      title: title,
      description: description,
    );
    emit(state.copyWith(todo: updated));
    emitEffect(TodoSaved());
  }

  Future<void> delete() async {
    final todo = state.todo;
    if (todo == null) return;

    await _repository.remove(todo.id);
    emitEffect(TodoDeleted(todo.title));
  }
}
