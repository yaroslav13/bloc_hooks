# Changelog

## 1.0.0

Initial release of `bloc_hooks` — a hooks-based integration for [bloc](https://pub.dev/packages/bloc) state management with [flutter_hooks](https://pub.dev/packages/flutter_hooks).

### Features

#### Scope & Lifecycle
- **`useBlocScope(factory)`** — Register a bloc factory for a widget subtree.
- **`bindBloc<B, S>()`** — Create and bind a bloc to the current position in the widget tree; automatically disposed when the widget is removed.
- **`useBloc<B>()`** — Retrieve the nearest bound bloc instance by walking up the widget tree.

#### State Hooks
- **`useBlocWatch<S>()`** — Subscribe to full state changes with optional `when` filter; rebuilds the widget on every matching emission.
- **`useBlocSelect<S, V>(selector)`** — Subscribe to a single derived value from the state; rebuilds only when the selected value changes.
- **`useBlocListen<S>(listener)`** — React to state changes with side effects (dialogs, snack-bars, navigation) without rebuilding the widget.
- **`useBlocRead<S>()`** — One-time, non-reactive read of the current state.

#### Effects
- **`useBlocEffects<E>(handler)`** — Listen to one-shot effects dispatched from a bloc to the UI layer.
- **`Effects<E>` mixin** — Add effect emission capability to any `Cubit` or `Bloc`.
