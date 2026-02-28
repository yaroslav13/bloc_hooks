import 'package:bloc_hooks/bloc_hooks.dart';
import 'package:bloc_hooks_example/cubits/todo_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Displays active / completed counters using [useBlocSelect].
class TodoStats extends HookWidget {
  const TodoStats({super.key});

  @override
  Widget build(BuildContext context) {
    // Subscribe to a single derived value — rebuilds only when it changes.
    final completed = useBlocSelect<TodoState, int>(
      (state) => state.completedCount,
    );
    final active = useBlocSelect<TodoState, int>(
      (state) => state.activeCount,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatChip(label: 'Active', count: active, color: Colors.orange),
          _StatChip(label: 'Completed', count: completed, color: Colors.green),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Text('$count', style: const TextStyle(color: Colors.black)),
      label: Text(label),
    );
  }
}
