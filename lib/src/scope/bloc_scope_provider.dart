import 'package:bloc_hooks/src/hooks/bind_bloc.dart';
import 'package:bloc_hooks/src/hooks/use_bloc.dart';
import 'package:bloc_hooks/src/hooks/use_bloc_scope.dart';
import 'package:bloc_hooks/src/scope/bloc_scope_registry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// A convenience widget that registers a [BlocFactory] in the
/// [BlocScopeRegistry] for all descendants in the subtree.
///
/// This is a declarative alternative to calling [useBlocScope] directly
/// inside a [HookWidget]. Wrap a portion of the widget tree with
/// [BlocScopeProvider] to make the [factory] available to any descendant
/// that calls [useBloc], [bindBloc], or similar hooks.
///
/// ### Example
///
/// ```dart
/// BlocScopeProvider(
///   factory: <B extends BlocBase<Object>>() => switch (B) {
///     const (CounterCubit) => CounterCubit() as B,
///     _ => throw UnimplementedError('No factory for $B'),
///   },
///   child: const CounterPage(),
/// )
/// ```
final class BlocScopeProvider extends HookWidget {
  /// Creates a [BlocScopeProvider] that binds [factory] to the current
  /// [BuildContext] and renders [child].
  const BlocScopeProvider({
    required this.factory,
    required this.child,
    super.key,
  });

  /// The factory function used to create bloc instances.
  ///
  /// This is registered in [BlocScopeRegistry] when the widget builds
  /// and is available to all descendant widgets in the subtree.
  final BlocFactory factory;

  /// The widget below this provider in the tree.
  ///
  /// Typically the root of the subtree that needs access to blocs
  /// created by [factory].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    useBlocScope(factory);

    return child;
  }
}
