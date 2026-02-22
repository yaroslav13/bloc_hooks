# bloc_hooks

A hooks-based integration for [bloc](https://pub.dev/packages/bloc) state management with [flutter_hooks](https://pub.dev/packages/flutter_hooks). Less boilerplate, almost all widgets can be stateless.

[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.6.0-blue)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.27.0-blue)](https://flutter.dev)
[![bloc](https://img.shields.io/badge/bloc-%5E9.2.0-blueviolet)](https://pub.dev/packages/bloc)

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
- [Architecture Overview](#architecture-overview)
- [API Reference](#api-reference)
- [Error Handling](#error-handling)

---

## Installation

Add `bloc_hooks` to your `pubspec.yaml`:

```yaml
dependencies:
  bloc_hooks:
    git:
      url: https://github.com/<your-org>/bloc_hooks.git
```

Or, if published to [pub.dev](https://pub.dev):

```yaml
dependencies:
  bloc_hooks: ^1.0.0
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

The mixin provides:

| Member | Description |
|--------|-------------|
| `emitEffect(E)` | Dispatches a new effect to listeners |
| `effectsStream` | The broadcast stream of effects |

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

## Architecture Overview

```
HookWidget
  └─ useBlocScope(factory)          ← registers a BlocFactory
       │
       ├─ BlocScopeRegistry         ← singleton; maps BuildContext → BlocScope
       │     └─ BlocScope           ← holds created bloc instances per slot
       │
       └─ Child HookWidget
            ├─ bindBloc<B, S>()     ← creates & stores a bloc in the nearest scope
            ├─ useBloc<B>()         ← resolves the nearest bound bloc
            ├─ useBlocWatch<S>()    ← subscribes to state stream, rebuilds widget
            ├─ useBlocSelect<S,V>() ← subscribes to derived value, rebuilds widget
            ├─ useBlocListen<S>()   ← side-effect listener, no rebuild
            ├─ useBlocRead<S>()     ← one-time read, no rebuild
            └─ useBlocEffects<E>()  ← listens to one-shot effects
```

Key design decisions:

- **No `InheritedWidget`** — scopes are attached to `BuildContext` via `Expando`, avoiding the rebuild cascade of inherited models.
- **Tree walking** — `useBloc`, `useBlocWatch`, etc. walk up the element tree to find the nearest scope and bloc, similar to how `Provider` resolves dependencies.
- **Automatic disposal** — blocs are closed when their binding widget is removed; scopes dispose all remaining blocs on unregistration.

---

## API Reference

| Hook / Function | Signature | Purpose | Rebuilds? |
|---|---|---|---|
| `useBlocScope` | `void useBlocScope(BlocFactory)` | Register a bloc factory for the subtree | No |
| `bindBloc` | `void bindBloc<B, S>({onCreated, onDisposed})` | Create & bind a bloc to the widget tree | No |
| `useBloc` | `B useBloc<B>()` | Get the nearest bound bloc instance | No |
| `useBlocWatch` | `S useBlocWatch<S>({when})` | Subscribe to full state changes | Yes |
| `useBlocSelect` | `V useBlocSelect<S, V>(selector, {when})` | Subscribe to a derived value | Yes (when value changes) |
| `useBlocListen` | `void useBlocListen<S>(listener, {when})` | Side-effect listener on state changes | No |
| `useBlocRead` | `S useBlocRead<S>()` | One-time non-reactive state read | No |
| `useBlocEffects` | `void useBlocEffects<E>(onEffect, [keys])` | Listen to one-shot effects from a bloc | No |

### Types

| Type | Definition |
|------|------------|
| `BlocFactory` | `B Function<B extends BlocBase<Object>>()` — generic factory used to create bloc instances |
| `Effects<E>` | Mixin on `Closable` — adds effect emission (`emitEffect`) and an `effectsStream` to a bloc |
| `EffectEmitter<E>` | Interface — contract for effect emission and stream access |

---

## Error Handling

All exceptions extend `BlocHooksException`:

| Exception | Thrown when |
|-----------|------------|
| `BlocScopeNotBoundException` | No `useBlocScope` was called above the requesting widget |
| `BlocNotFoundException<B>` | The requested bloc type was not found in any ancestor scope |
| `BlocRemovalException<B>` | Attempting to remove a bloc that was never bound |
| `BlocDuplicateBindingException<B>` | `bindBloc` is called twice for the same type in the same widget |

```dart
try {
  final cubit = useBloc<TodoCubit>();
} on BlocHooksException catch (e) {
  debugPrint(e.message);
}
```

---

## License

See [LICENSE](LICENSE) for details.
