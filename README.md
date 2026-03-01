# bloc_hooks

The state management solution for Flutter, based on the [bloc](https://pub.dev/packages/bloc) state management and [flutter_hooks](https://pub.dev/packages/flutter_hooks). It reduces boilerplate, allows almost all widgets to remain stateless, and simplifies bloc injection within the widget tree.

[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.10.8-blue)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.38.9-blue)](https://flutter.dev)
[![bloc](https://img.shields.io/badge/bloc-%5E9.2.0-blueviolet)](https://pub.dev/packages/bloc)
[![flutter_hooks](https://img.shields.io/badge/flutter--hooks-%5E0.21.3+1-blueviolet)](https://pub.dev/packages/flutter_hooks)

---

## Table of Contents

- [Installation](#installation)
- [Getting Started](#getting-started)
  - [1. Set up BlocScope](#1-set-up-blocscope)
  - [2. Bind a bloc](#2-bind-a-bloc)
  - [3. Access the bloc instance](#3-access-the-bloc-instance)
- [State Hooks](#state-hooks)
  - [useBlocWatch](#useblocwatchs)
  - [useBlocSelect](#useblocselectsv)
  - [useBlocListen](#usebloclistens)
  - [useBlocRead](#useblocreads)
- [Effects](#effects)
  - [Define effects](#define-effects)
  - [Create a cubit with effects](#create-a-cubit-with-effects)
  - [Listen to effects in UI](#listen-to-effects-in-ui)
- [Expando-based Scoping](#expando-based-scoping)
- [Alternatives](#alternatives)

---

## Installation

Add `bloc_hooks` to your `pubspec.yaml`:

```yaml
dependencies:
  bloc_hooks: ^version
  bloc: ^version
  flutter_hooks: ^version
```

Then run:

```bash
flutter pub get
```

Import it in your Dart code:

```dart
import 'package:bloc_hooks/bloc_hooks.dart';
```

---

## Getting Started

### 1. Set up BlocScope

Call `useBlocScope` inside a `HookWidget` to register a `BlocFactory` for the entire subtree.
The factory is a generic function that creates blocs by type:

```dart
void main() => runApp(const MyApp());

class MyApp extends HookWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    useBlocScope(<B extends BlocBase<Object>>() {
      return switch (B) {
        const (TodoCubit)  => TodoCubit(),
        const (AuthCubit)  => AuthCubit(),
        _ => throw UnimplementedError('No factory registered for $B'),
      } as B;
    });

    return const MaterialApp(home: TodoPage());
  }
}
```

> **Tip:** You can use a dependency injection container (e.g. `get_it`) inside the factory to resolve instances.

### 2. Bind a bloc

Use `bindBloc<B, S>()` to create and bind a bloc to the current position in the widget tree.
The bloc is automatically created via the registered `BlocFactory` and disposed when the widget is removed:

```dart
class TodoPage extends HookWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context) {
    bindBloc<TodoCubit, TodoState>(
      onCreated: (cubit) => cubit.loadTodos(),
      onDisposed: (cubit) => debugPrint('TodoCubit disposed'),
    );

    return const TodoList();
  }
}
```

If you need a bloc to be shared between two parallel screens, bind it in a common ancestor.

> **Note:** Binding the same bloc type twice in the same widget will throw an assertion error in debug mode.

### 3. Access the bloc instance

Use `useBloc<B>()` to get the nearest bound bloc by walking up the widget tree:

```dart
final cubit = useBloc<TodoCubit>();
cubit.addTodo('Buy groceries');
```

This is a non-reactive hook — it retrieves the bloc instance but does **not** subscribe to state changes.

---

## State Hooks

### `useBlocWatch<S>()`

Subscribe to state changes. The widget rebuilds on every emission (or only when `when` returns `true`):

```dart
class TodoList extends HookWidget {
  const TodoList({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useBlocWatch<TodoState>();

    return ListView(
      children: [
        for (final todo in state.todos)
          ListTile(
            title: Text(todo.title),
            trailing: Icon(todo.done ? Icons.check_circle : Icons.circle_outlined),
          ),
      ],
    );
  }
}
```

With a condition:

```dart
final state = useBlocWatch<TodoState>(
  when: (previous, current) => previous.todos.length != current.todos.length,
);
```

### `useBlocSelect<S, V>()`

Subscribe to a **single derived value** from the state. Rebuilds only when the selected value changes:

```dart
class TodoStats extends HookWidget {
  const TodoStats({super.key});

  @override
  Widget build(BuildContext context) {
    final completedCount = useBlocSelect<TodoState, int>(
      (state) => state.todos.where((t) => t.done).length,
    );

    return Text('$completedCount tasks completed');
  }
}
```

You can also add a `when` predicate for additional control:

```dart
final activeCount = useBlocSelect<TodoState, int>(
  (state) => state.todos.where((t) => !t.done).length,
  when: (previous, current) => previous.todos.length != current.todos.length,
);
```

### `useBlocListen<S>()`

React to state changes with side effects (dialogs, snack-bars, navigation) **without** rebuilding the widget.
The listener receives both the new state and the current `BuildContext`:

```dart
useBlocListen<TodoState>((state, context) {
  if (state.todos.every((t) => t.done)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All tasks completed! 🎉')),
    );
  }
});
```

With a condition:

```dart
useBlocListen<AuthState>(
  (state, context) => Navigator.of(context).pushReplacementNamed('/login'),
  when: (previous, current) => previous.isLoggedIn && !current.isLoggedIn,
);
```

### `useBlocRead<S>()`

One-time, **non-reactive** read of the current state. The widget will **not** rebuild when the state changes:

```dart
final currentState = useBlocRead<TodoState>();
```

Useful for reading initial values or accessing state inside callbacks.

---

## Effects

Dispatch one-shot events from a bloc to the UI layer. Unlike state, effects are fire-and-forget and are not replayed on rebuild.

### Define effects

```dart
sealed class TodoEffect {}

class ShowUndoSnackBar implements TodoEffect {
  const ShowUndoSnackBar(this.todoTitle);
  final String todoTitle;
}

class NavigateToDetail implements TodoEffect {
  const NavigateToDetail(this.todoId);
  final String todoId;
}
```

### Create a cubit with effects

Add the `Effects<E>` mixin to any `Cubit` or `Bloc`:

```dart
class TodoCubit extends Cubit<TodoState> with Effects<TodoEffect> {
  TodoCubit() : super(const TodoState());

  void deleteTodo(String id) {
    final todo = state.findById(id);
    emit(state.withoutTodo(id));
    emitEffect(ShowUndoSnackBar(todo.title));
  }

  void openDetail(String id) => emitEffect(NavigateToDetail(id));
}
```

### Listen to effects in UI

Use `useBlocEffects<E>()` to subscribe. The callback receives the current `BuildContext` and the effect:

```dart
class TodoPage extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = useBloc<TodoCubit>();

    useBlocEffects<TodoEffect>((context, effect) {
      switch (effect) {
        case ShowUndoSnackBar(:final todoTitle):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted "$todoTitle"'),
              action: SnackBarAction(label: 'Undo', onPressed: cubit.undoDelete),
            ),
          );
        case NavigateToDetail(:final todoId):
          Navigator.of(context).pushNamed('/todo/$todoId');
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Todos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => cubit.addTodo('New task'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

---

## Expando-based Scoping

`bloc_hooks` uses Dart's [`Expando`](https://api.dart.dev/stable/dart-core/Expando-class.html) — a weak-map that attaches metadata to arbitrary objects without modifying them.


---

## Alternatives

- [hooked_bloc](https://pub.dev/packages/hooked_bloc) — a similar hooks-based approach to using `bloc` with `flutter_hooks`.

---

## License

See [LICENSE](LICENSE) for details.
