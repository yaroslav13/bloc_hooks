import 'package:bloc_hooks/bloc_hooks.dart';
import 'package:bloc_hooks_example/cubits/todo_cubit.dart';
import 'package:bloc_hooks_example/cubits/todo_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Renders the list of todos using [useBlocWatch] and [useBloc].
class TodoList extends HookWidget {
  const TodoList({super.key});

  @override
  Widget build(BuildContext context) {
    // Subscribe to the full state — rebuilds on every emission.
    final state = useBlocWatch<TodoState>();

    // Get the cubit instance (non-reactive) to call methods.
    final cubit = useBloc<TodoCubit>();

    if (state.todos.isEmpty) {
      return const Center(
        child: Text('No todos yet. Tap + to add one!'),
      );
    }

    return ListView.builder(
      itemCount: state.todos.length,
      itemBuilder: (context, index) {
        final todo = state.todos[index];
        return ListTile(
          onTap: () => cubit.openDetail(todo.id),
          leading: Checkbox(
            value: todo.done,
            onChanged: (_) => cubit.toggleTodo(todo.id),
          ),
          title: Text(
            todo.title,
            style: TextStyle(
              decoration: todo.done ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: todo.description.isNotEmpty
              ? Text(todo.description,
                  maxLines: 1, overflow: TextOverflow.ellipsis)
              : null,
          trailing: IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => cubit.openDetail(todo.id),
          ),
        );
      },
    );
  }
}
