import 'package:bloc/bloc.dart';
import 'package:bloc_hooks/bloc_hooks.dart';
import 'package:bloc_hooks_example/cubits/todo_cubit.dart';
import 'package:bloc_hooks_example/cubits/todo_detail_cubit.dart';
import 'package:bloc_hooks_example/data/todo_repository.dart';
import 'package:bloc_hooks_example/pages/todo_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

void main() => runApp(const MyApp());

/// Shared repository instance — in a real app you'd use a DI container.
final todoRepository = TodoRepository();

/// Root widget that sets up [useBlocScope] and [bindBloc].
///
/// [TodoCubit] is bound here — above the [MaterialApp]'s [Navigator] —
/// so it is accessible from every route.
///
/// [TodoDetailCubit] is registered in the factory but bound at the
/// page level inside [TodoDetailPage].
class MyApp extends HookWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Register a BlocFactory at the root of the app.
    useBlocScope(<B extends BlocBase<Object>>() {
      return switch (B) {
        const (TodoCubit) => TodoCubit(todoRepository),
        const (TodoDetailCubit) => TodoDetailCubit(todoRepository),
        _ => throw UnimplementedError('No factory registered for $B'),
      } as B;
    });

    return MaterialApp(
      title: 'bloc_hooks example',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const TodoPage(),
    );
  }
}
