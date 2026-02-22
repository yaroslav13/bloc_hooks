import 'package:bloc_hooks/bloc_hooks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../cubits/todo_cubit.dart';

/// A HookWidget that binds a [TodoCubit] and renders [child].
final class TodoBinder extends HookWidget {
  const TodoBinder({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    bindBloc<TodoCubit, TodoState>();
    return child;
  }
}
