import 'package:bloc_hooks/bloc_hooks.dart';
import 'package:bloc_hooks_example/cubits/todo_detail_cubit.dart';
import 'package:bloc_hooks_example/cubits/todo_detail_state.dart';
import 'package:bloc_hooks_example/effects/todo_detail_effect.dart';
import 'package:bloc_hooks_example/models/todo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Detail page for a single todo.
///
/// Demonstrates a **page-level cubit** bound with [bindBloc].
/// [TodoDetailCubit] is created when the page opens and disposed
/// when the user navigates back — its lifecycle is fully automatic.
///
/// Also shows [useBlocWatch], [useBlocEffects], and [useBloc].
class TodoDetailPage extends HookWidget {
  const TodoDetailPage({required this.todoId, super.key});

  final String todoId;

  @override
  Widget build(BuildContext context) {
    // Bind a page-scoped cubit. It is created via the factory registered
    // in MyApp and disposed when this page is popped off the navigator.
    bindBloc<TodoDetailCubit, TodoDetailState>(
      onCreated: (cubit) => cubit.load(todoId),
      onDisposed: (cubit) => debugPrint('TodoDetailCubit disposed'),
    );

    // Subscribe to the detail cubit's state — rebuilds on every change.
    final state = useBlocWatch<TodoDetailState>();

    // Handle one-shot effects from the detail cubit.
    useBlocEffects<TodoDetailEffect>((context, effect) {
      switch (effect) {
        case TodoSaved():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Changes saved')),
          );
        case TodoDeleted(:final todoTitle):
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted "$todoTitle"')),
          );
        case TodoStatusChanged(:final title, :final done):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                done ? '"$title" completed ✅' : '"$title" reopened',
              ),
              duration: const Duration(seconds: 1),
            ),
          );
      }
    });

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.notFound) {
      return Scaffold(
        appBar: AppBar(title: const Text('Not Found')),
        body: const Center(child: Text('This todo no longer exists.')),
      );
    }

    final todo = state.todo!;
    final detailCubit = useBloc<TodoDetailCubit>();

    return Scaffold(
      appBar: AppBar(title: Text(todo.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Status chip ----
            Chip(
              label: Text(todo.done ? 'Completed' : 'Active'),
              backgroundColor:
                  todo.done ? Colors.green.shade100 : Colors.orange.shade100,
            ),
            const SizedBox(height: 24),

            // ---- Description ----
            Text('Description', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              todo.description.isEmpty
                  ? 'No description yet.'
                  : todo.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            const Spacer(),

            // ---- Action buttons ----
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: detailCubit.toggleDone,
                    icon: Icon(todo.done ? Icons.undo : Icons.check),
                    label: Text(todo.done ? 'Reopen' : 'Complete'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showEditDialog(context, detailCubit, todo),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: detailCubit.delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    TodoDetailCubit cubit,
    Todo todo,
  ) {
    final titleController = TextEditingController(text: todo.title);
    final descriptionController = TextEditingController(text: todo.description);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Todo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              cubit.edit(
                title: titleController.text.trim(),
                description: descriptionController.text.trim(),
              );
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
