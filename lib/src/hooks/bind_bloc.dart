import 'package:bloc/bloc.dart';
import 'package:bloc_hooks/src/exceptions/exceptions.dart';
import 'package:bloc_hooks/src/hooks/use_bloc.dart';
import 'package:bloc_hooks/src/hooks/use_bloc_scope.dart';
import 'package:bloc_hooks/src/scope/bloc_scope.dart';
import 'package:bloc_hooks/src/scope/bloc_scope_registry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// A callback that receives a bloc instance of type [B].
///
/// Used by [bindBloc] to notify callers when a bloc is created or disposed.
///
/// The bloc's state type [S] must extend [Object].
typedef BlocLifecycleCallback<B extends BlocBase<S>, S extends Object> = void
    Function(B);

/// Creates a bloc of type [B] with state [S] and binds it to the current
/// position in the widget tree.
///
/// The bloc is instantiated via the nearest [BlocScope]'s factory
/// (registered with [useBlocScope]) and is automatically closed when the
/// host widget is removed from the tree.
///
/// Must be called inside a [HookWidget.build] method.
///
/// ### Parameters
///
/// * [onCreated] — optional callback invoked immediately after the bloc
///   is created. Useful for triggering initial loads or subscriptions.
/// * [onDisposed] — optional callback invoked just after the bloc is
///   removed from the scope and before the widget is fully disposed.
///
/// ### Assertions
///
/// In debug mode an assertion error is thrown if a bloc of the same type [B]
/// is already bound to the same widget (i.e. [bindBloc] is called twice for
/// the same type in one widget).
///
/// ### Example
///
/// ```dart
/// class CounterPage extends HookWidget {
///   const CounterPage({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     bindBloc<CounterCubit, int>(
///       onCreated: (cubit) => cubit.load(),
///       onDisposed: (cubit) => debugPrint('disposed'),
///     );
///
///     return const CounterView();
///   }
/// }
/// ```
///
/// See also:
///
///  * [useBloc], to retrieve a previously bound bloc instance.
///  * [useBlocScope], to register the factory that [bindBloc] uses.
void bindBloc<B extends BlocBase<S>, S extends Object>({
  BlocLifecycleCallback<B, S>? onCreated,
  BlocLifecycleCallback<B, S>? onDisposed,
}) {
  return use(
    _BindBlocHook<B, S>(
      onCreated: onCreated,
      onDisposed: onDisposed,
    ),
  );
}

final class _BindBlocHook<B extends BlocBase<S>, S extends Object>
    extends Hook<void> {
  const _BindBlocHook({
    this.onCreated,
    this.onDisposed,
    super.keys,
  });

  final BlocLifecycleCallback<B, S>? onCreated;
  final BlocLifecycleCallback<B, S>? onDisposed;

  @override
  _BindBlocHookState<B, S> createState() {
    return _BindBlocHookState<B, S>();
  }
}

final class _BindBlocHookState<B extends BlocBase<S>, S extends Object>
    extends HookState<void, _BindBlocHook<B, S>> {
  _BindBlocHookState();

  VoidCallback? _onDispose;

  @override
  void initHook() {
    final scope = BlocScopeRegistry.instance.lookup(context);

    assert(
      scope.getBloc<B>(context) == null,
      AlreadyBindException<B>(context.widget.toString()).toString(),
    );

    final bloc = scope.createBloc<B, S>(context);

    hook.onCreated?.call(bloc);

    _onDispose = () => _removeBloc(scope, bloc);
  }

  @override
  void build(BuildContext context) {
    // side effect
  }

  @override
  void dispose() {
    _onDispose?.call();
    _onDispose = null;

    super.dispose();
  }

  void _removeBloc(BlocScope scope, B bloc) {
    scope.removeBloc<B, S>(context).whenComplete(() {
      hook.onDisposed?.call(bloc);
    });
  }
}
