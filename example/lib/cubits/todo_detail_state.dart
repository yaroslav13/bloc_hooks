import 'package:bloc_hooks_example/models/todo.dart';

final class TodoDetailState {
  const TodoDetailState({this.todo, this.isLoading = true});

  final Todo? todo;
  final bool isLoading;

  bool get notFound => !isLoading && todo == null;

  TodoDetailState copyWith({Todo? todo, bool? isLoading}) => TodoDetailState(
        todo: todo ?? this.todo,
        isLoading: isLoading ?? this.isLoading,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoDetailState &&
          todo == other.todo &&
          isLoading == other.isLoading;

  @override
  int get hashCode => Object.hash(todo, isLoading);
}
