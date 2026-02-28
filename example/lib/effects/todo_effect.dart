sealed class TodoEffect {}

final class ShowUndoSnackBar implements TodoEffect {
  const ShowUndoSnackBar(this.todoTitle);

  final String todoTitle;
}

final class AllTasksCompleted implements TodoEffect {}
