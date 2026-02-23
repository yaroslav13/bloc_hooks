import 'package:bloc/bloc.dart';
import 'package:bloc_hooks/src/exceptions/exceptions.dart';
import 'package:bloc_hooks/src/hooks/bind_bloc.dart';
import 'package:bloc_hooks/src/hooks/use_bloc_read.dart';
import 'package:bloc_hooks/src/hooks/use_bloc_select.dart';
import 'package:bloc_hooks/src/hooks/use_bloc_watch.dart';
import 'package:bloc_hooks/src/scope/bloc_scope_registry.dart';
import 'package:bloc_hooks/src/utils/lookup_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Returns the nearest bound bloc instance of type [B] by walking up
/// the widget tree.
///
/// The lookup is memoized per [BuildContext] — subsequent calls within
/// the same build return the cached instance without repeating the
/// tree walk.
///
/// This is a **non-reactive** hook: retrieving a bloc does not
/// subscribe to its state stream and will not trigger widget rebuilds.
/// Use [useBlocWatch] or [useBlocSelect] if you need reactive updates.
///
/// Must be called inside a [HookWidget.build] method.
///
/// Throws a [BlocNotFoundException] if no bloc of type [B] has been
/// bound (via [bindBloc]) in the current context or any ancestor.
///
/// ### Example
///
/// ```dart
/// class CounterControls extends HookWidget {
///   const CounterControls({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     final cubit = useBloc<CounterCubit>();
///
///     return ElevatedButton(
///       onPressed: cubit.increment,
///       child: const Text('+'),
///     );
///   }
/// }
/// ```
///
/// See also:
///
///  * [bindBloc], to create and bind a bloc to the tree.
///  * [useBlocWatch], to subscribe to full state changes.
///  * [useBlocRead], to perform a one-time non-reactive state read.
B useBloc<B extends BlocBase<Object>>() {
  final context = useContext();

  return useMemoized(
    () {
      final scope = BlocScopeRegistry.instance.lookup(context);

      final bloc = lookupBloc(
        context,
        locator: scope.getBloc<B>,
      );

      return bloc;
    },
    [context],
  );
}
