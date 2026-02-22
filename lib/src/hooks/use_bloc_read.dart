import 'package:bloc/bloc.dart';
import 'package:bloc_hooks/src/hooks/use_bloc.dart';
import 'package:bloc_hooks/src/hooks/use_bloc_select.dart';
import 'package:bloc_hooks/src/hooks/use_bloc_watch.dart';
import 'package:bloc_hooks/src/scope/bloc_scope_registry.dart';
import 'package:bloc_hooks/src/utils/find_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Reads the current state of the nearest bloc whose state type is [S],
/// without subscribing to future changes.
///
/// This is a **non-reactive** read — the widget will not rebuild when
/// the state changes. The result is memoized per [BuildContext], so
/// subsequent calls within the same build return the cached value.
///
/// Useful for one-time reads such as initialising a controller or
/// reading a value inside a callback.
///
/// Must be called inside a [HookWidget.build] method.
///
/// ### Example
///
/// ```dart
/// class InfoWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final currentState = useBlocRead<CounterState>();
///
///     return Text('Initial: ${currentState.score}');
///   }
/// }
/// ```
///
/// See also:
///
///  * [useBlocWatch], to subscribe to state changes with rebuilds.
///  * [useBlocSelect], to subscribe to a single derived value.
///  * [useBloc], to retrieve the bloc instance itself.
S useBlocRead<S>() {
  final context = useContext();

  return useMemoized(
    () {
      final scope = BlocScopeRegistry.instance.lookup(context);

      final bloc = findBloc<BlocBase<S>>(
        context,
        findMethod: scope.getBlocByState<S>,
      );

      return bloc.state;
    },
    [context],
  );
}
