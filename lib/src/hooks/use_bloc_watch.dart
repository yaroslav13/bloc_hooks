import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_hooks/src/hooks/use_bloc_listen.dart';
import 'package:bloc_hooks/src/hooks/use_bloc_read.dart';
import 'package:bloc_hooks/src/hooks/use_bloc_select.dart';
import 'package:bloc_hooks/src/scope/bloc_scope.dart';
import 'package:bloc_hooks/src/scope/bloc_scope_registry.dart';
import 'package:bloc_hooks/src/types/types.dart';
import 'package:bloc_hooks/src/utils/lookup_bloc.dart';
import 'package:bloc_hooks/src/utils/where_state_changed.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Subscribes to a bloc's state stream and rebuilds the widget
/// whenever a new state is emitted.
///
/// Resolves the nearest bloc whose state type is [S] from the
/// [BlocScope] tree (via [BlocScopeRegistry.instance.lookup] + [lookupBloc])
/// and returns the current state. On each qualifying emission the
/// widget is marked dirty and rebuilt with the latest value.
///
/// Must be called inside a [HookWidget.build] method.
///
/// ### Parameters
///
/// * [when] — optional predicate that receives the previous and
///   current state. When provided, only emissions for which [when]
///   returns `true` trigger a rebuild. By default every emission
///   triggers a rebuild.
///
/// ### Example
///
/// ```dart
/// class CounterPage extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final state = useBlocWatch<CounterState>();
///
///     return Text(state.score.toString());
///   }
/// }
/// ```
///
/// See also:
///
///  * [useBlocSelect], to subscribe to a single derived value.
///  * [useBlocListen], to react to state changes without rebuilding.
///  * [useBlocRead], for a one-time non-reactive state read.
S useBlocWatch<S>({
  BlocStateCondition<S>? when,
}) {
  return use(_WatchBlocHook<S>(when: when));
}

final class _WatchBlocHook<S> extends Hook<S> {
  const _WatchBlocHook({this.when});

  final BlocStateCondition<S>? when;

  @override
  _WatchBlocHookState<S> createState() => _WatchBlocHookState<S>();
}

final class _WatchBlocHookState<S> extends HookState<S, _WatchBlocHook<S>> {
  late BlocBase<S> _bloc;
  late S _state;

  StreamSubscription<S>? _stateSubscription;

  @override
  void initHook() {
    final scope = BlocScopeRegistry.instance.lookup(context);
    _bloc = lookupBloc(context, locator: scope.getBlocByState<S>);
    _state = _bloc.state;

    _subscribeStateChanges();
  }

  @override
  S build(BuildContext context) => _state;

  @override
  void dispose() {
    unawaited(_stateSubscription?.cancel());
    super.dispose();
  }

  void _subscribeStateChanges() {
    _stateSubscription = _bloc.stream
        .transform(
      WhereStateChanged(
        initialState: _state,
        when: hook.when,
      ),
    )
        .listen(
      (state) {
        _state = state;
        setState(() {});
      },
    );
  }
}
