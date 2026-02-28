import 'package:bloc_hooks/bloc_hooks.dart';
import 'package:bloc_hooks_example/cubits/todo_cubit.dart';
import 'package:bloc_hooks_example/cubits/todo_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// FAB that opens a dialog to add a new todo.
///
/// Demonstrates [useBloc] and [useBlocRead].
class AddTodoFab extends HookWidget {
  const AddTodoFab({super.key});

  @override
  Widget build(BuildContext context) {
    // Non-reactive read of the current state (one-time snapshot).
    final initialState = useBlocRead<TodoState>();
    debugPrint(
      'Initial todo count when FAB built: ${initialState.todos.length}',
    );

    // Get the cubit instance to call addTodo.
    final cubit = useBloc<TodoCubit>();

    return FloatingActionButton(
      onPressed: () => _showAddDialog(context, cubit),
      child: const Icon(Icons.add),
    );
  }

  void _showAddDialog(BuildContext context, TodoCubit cubit) {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Todo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'What needs to be done?'),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              cubit.addTodo(value.trim());
              Navigator.of(dialogContext).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                cubit.addTodo(text);
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
