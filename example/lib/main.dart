import 'package:bloc/bloc.dart';
import 'package:bloc_hooks/bloc_hooks.dart';
import 'package:bloc_hooks_example/cubits/todo_cubit.dart';
import 'package:bloc_hooks_example/pages/todo_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

void main() => runApp(const MyApp());

class MyApp extends HookWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Register a BlocFactory at the root of the app.
    // All descendant widgets can now create and resolve blocs.
    useBlocScope(<B extends BlocBase<Object>>() {
      return switch (B) {
        const (TodoCubit) => TodoCubit(),
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
