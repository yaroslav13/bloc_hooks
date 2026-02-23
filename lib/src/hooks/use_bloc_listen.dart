import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_hooks/src/hooks/use_bloc_effects.dart';
import 'package:bloc_hooks/src/hooks/use_bloc_watch.dart';
import 'package:bloc_hooks/src/scope/bloc_scope_registry.dart';
import 'package:bloc_hooks/src/types/types.dart';
import 'package:bloc_hooks/src/utils/lookup_bloc.dart';
import 'package:bloc_hooks/src/utils/where_state_changed.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Signature of the listener callback used by [useBlocListen].
typedef BlocStateListener<S> = void Function(S state, BuildContext context);

/// Listens to a bloc's state stream and invokes [listener] on each
/// qualifying emission. Unlike [useBlocWatch], this hook does **not**
/// trigger widget rebuilds — it is intended for side effects such as
/// showing dialogs or snack-bars.
///
/// The listener receives the new state and the current [BuildContext],
/// and is only invoked while the widget is still mounted.
///
/// ### Parameters
///
/// * [listener] — callback invoked with the latest state and the
///   widget's [BuildContext] on every qualifying emission.
/// * [when] — optional predicate that receives the previous and current
///   state. When provided, only emissions for which [when] returns
///   `true` invoke the listener. By default every emission invokes it.
///
/// ### Example
///
/// ```dart
/// class CounterPage extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     useBlocListen<CounterState>((state, context) {
///       if (state.score > 10) {
///         ScaffoldMessenger.of(context).showSnackBar(
///           SnackBar(content: Text('High score!')),
///         );
///       }
///     });
///
///     return const SizedBox();
///   }
/// }
/// ```
///
/// See also:
///
///  * [useBlocWatch], to subscribe to state changes **with** rebuilds.
///  * [useBlocEffects], to listen to one-shot effects instead of state.
void useBlocListen<S>(
  BlocStateListener<S> listener, {
  BlocStateCondition<S>? when,
}) {
  use(_BlocListenerHook<S>(listener: listener, when: when));
}

final class _BlocListenerHook<S> extends Hook<void> {
  const _BlocListenerHook({
    required this.listener,
    this.when,
  });

  final BlocStateListener<S> listener;
  final BlocStateCondition<S>? when;

  @override
  _ListenBlocHookState<S> createState() => _ListenBlocHookState<S>();
}

final class _ListenBlocHookState<S>
    extends HookState<void, _BlocListenerHook<S>> {
  late BlocBase<S> _bloc;
  StreamSubscription<S>? _stateSubscription;

  @override
  void initHook() {
    final scope = BlocScopeRegistry.instance.lookup(context);
    _bloc = lookupBloc(context, locator: scope.getBlocByState<S>);

    _subscribeStateChanges();
  }

  @override
  void build(BuildContext context) {
    // side effect
  }

  @override
  void dispose() {
    unawaited(_stateSubscription?.cancel());
    super.dispose();
  }

  void _subscribeStateChanges() {
    _stateSubscription = _bloc.stream
        .transform(
      WhereStateChanged(
        initialState: _bloc.state,
        when: hook.when,
      ),
    )
        .listen(
      (state) {
        if (!context.mounted) {
          return;
        }

        hook.listener(state, context);
      },
    );
  }
}
