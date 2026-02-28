import 'package:bloc_hooks/bloc_hooks.dart';
import 'package:bloc_hooks_example/cubits/todo_cubit.dart';
import 'package:bloc_hooks_example/cubits/todo_state.dart';
import 'package:bloc_hooks_example/effects/todo_effect.dart';
import 'package:bloc_hooks_example/pages/todo_detail_page.dart';
import 'package:bloc_hooks_example/widgets/add_todo_fab.dart';
import 'package:bloc_hooks_example/widgets/todo_list.dart';
import 'package:bloc_hooks_example/widgets/todo_stats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// The main page that wires up effects & listeners for the todo list.
///
/// Demonstrates [useBlocEffects] with navigation and [useBlocListen].
/// The [TodoCubit] is bound in [MyApp] above the navigator so it is
/// available to both this page and [TodoDetailPage].
class TodoPage extends HookWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Bind the list cubit above the Navigator so every route can access it.
    bindBloc<TodoCubit, TodoState>(
      onCreated: (cubit) {
        debugPrint('TodoCubit created');
        cubit.loadTodos();
      },
      onDisposed: (cubit) => debugPrint('TodoCubit disposed'),
    );

    final cubit = useBloc<TodoCubit>();

    // Listen to one-shot effects (fire-and-forget).
    // NavigateToDetail triggers a push to TodoDetailPage.
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
        case NavigateToDetail(:final todoId):
          Navigator.of(context)
              .push(
            MaterialPageRoute<void>(
              builder: (_) => TodoDetailPage(todoId: todoId),
            ),
          )
              .then(
            (_) {
              cubit.loadTodos();
            },
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
