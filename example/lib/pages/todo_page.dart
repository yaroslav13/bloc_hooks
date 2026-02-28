import 'package:bloc_hooks/bloc_hooks.dart';
import 'package:bloc_hooks_example/cubits/todo_cubit.dart';
import 'package:bloc_hooks_example/cubits/todo_state.dart';
import 'package:bloc_hooks_example/effects/todo_effect.dart';
import 'package:bloc_hooks_example/widgets/add_todo_fab.dart';
import 'package:bloc_hooks_example/widgets/todo_list.dart';
import 'package:bloc_hooks_example/widgets/todo_stats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// The main page that binds [TodoCubit] and wires up effects & listeners.
///
/// Demonstrates [bindBloc], [useBlocEffects], and [useBlocListen].
class TodoPage extends HookWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Bind the cubit to this position in the widget tree.
    // It is created via the factory and disposed automatically.
    bindBloc<TodoCubit, TodoState>(
      onCreated: (cubit) => debugPrint('TodoCubit created'),
      onDisposed: (cubit) => debugPrint('TodoCubit disposed'),
    );

    // Listen to one-shot effects (fire-and-forget).
    useBlocEffects<TodoEffect>((context, effect) {
      switch (effect) {
        case ShowUndoSnackBar(:final todoTitle):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted "$todoTitle"')),
          );
        case AllTasksCompleted():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All tasks completed! 🎉')),
          );
      }
    });

    // Listen to state changes for side-effects (no rebuild).
    useBlocListen<TodoState>((state, context) {
      debugPrint('Todo count changed: ${state.todos.length}');
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Todos')),
      body: const Column(
        children: [
          TodoStats(),
          Expanded(child: TodoList()),
        ],
      ),
      floatingActionButton: const AddTodoFab(),
    );
  }
}
