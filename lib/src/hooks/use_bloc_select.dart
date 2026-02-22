import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_hooks/src/hooks/use_bloc_listen.dart';
import 'package:bloc_hooks/src/hooks/use_bloc_watch.dart';
import 'package:bloc_hooks/src/scope/bloc_scope_registry.dart';
import 'package:bloc_hooks/src/types/types.dart';
import 'package:bloc_hooks/src/utils/find_bloc.dart';
import 'package:bloc_hooks/src/utils/where_state_changed.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Signature of the selector function used by [useBlocSelect].
typedef BlocStateSelector<S, V> = V Function(S state);

/// Subscribes to a bloc's state stream and rebuilds the widget only
/// when the value produced by [selector] changes.
///
/// This is the optimised alternative to [useBlocWatch] when only a
/// single property (or a derived value) of the state is needed.
///
/// Must be called inside a [HookWidget.build] method.
///
/// ### Parameters
///
/// * [selector] — a pure function that extracts a value of type [V]
///   from a state of type [S]. The widget rebuilds only when the
///   selected value changes (determined by `!=`).
/// * [when] — optional predicate that receives the previous and
///   current *raw state*. When provided, only emissions for which
///   [when] returns `true` are evaluated by the selector. By default
///   an emission triggers a rebuild whenever
///   `selector(previous) != selector(current)`.
///
/// ### Example
///
/// ```dart
/// class ScorePage extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final score = useBlocSelect<CounterState, int>(
///       (state) => state.score,
///     );
///
///     return Text(score.toString());
///   }
/// }
/// ```
///
/// See also:
///
///  * [useBlocWatch], to subscribe to the full state object.
///  * [useBlocListen], to react to state changes without rebuilding.
V useBlocSelect<S, V>(
  BlocStateSelector<S, V> selector, {
  BlocStateCondition<S>? when,
}) {
  return use(_SelectBlocHook<S, V>(selector: selector, when: when));
}

final class _SelectBlocHook<S, V> extends Hook<V> {
  const _SelectBlocHook({
    required this.selector,
    this.when,
  });

  final BlocStateSelector<S, V> selector;
  final BlocStateCondition<S>? when;

  @override
  _SelectBlocHookState<S, V> createState() => _SelectBlocHookState<S, V>();
}

final class _SelectBlocHookState<S, V>
    extends HookState<V, _SelectBlocHook<S, V>> {
  late BlocBase<S> _bloc;
  late V _selectedValue;

  StreamSubscription<V>? _stateSubscription;

  @override
  void initHook() {
    final scope = BlocScopeRegistry.instance.lookup(context);
    _bloc = findBloc(context, findMethod: scope.getBlocByState<S>);
    _selectedValue = hook.selector(_bloc.state);

    _subscribeStateChanges();
  }

  @override
  V build(BuildContext context) => _selectedValue;

  @override
  void dispose() {
    unawaited(_stateSubscription?.cancel());
    super.dispose();
  }

  void _subscribeStateChanges() {
    final selector = hook.selector;
    final when = hook.when;

    bool defaultWhen(S prev, S curr) => selector(prev) != selector(curr);
    final effectiveWhen = when ?? defaultWhen;

    _stateSubscription = _bloc.stream
        .transform(
          WhereStateChanged(
            initialState: _bloc.state,
            when: effectiveWhen,
          ),
        )
        .map(selector)
        .listen(
      (value) {
        _selectedValue = value;
        setState(() {});
      },
    );
  }
}
