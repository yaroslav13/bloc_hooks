sealed class TodoDetailEffect {}
final class TodoSaved implements TodoDetailEffect {}
final class TodoDeleted implements TodoDetailEffect {
  const TodoDeleted(this.todoTitle);
  final String todoTitle;
}
final class TodoStatusChanged implements TodoDetailEffect {
  const TodoStatusChanged({required this.title, required this.done});
  final String title;
  final bool done;
}
