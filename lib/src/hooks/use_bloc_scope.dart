import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_hooks/src/scope/bloc_scope.dart';
import 'package:bloc_hooks/src/scope/bloc_scope_registry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// A factory function responsible for creating bloc instances.
///
/// The function must be generic and return a bloc of type [B],
/// where [B] extends [BlocBase<Object>].
///
/// Typically implemented using a dependency injection container
/// or a simple switch/map-based lookup:
///
/// ```dart
/// B myFactory<B extends BlocBase<Object>>() {
///   return switch (B) {
///     const (CounterCubit) => CounterCubit(),
///     _ => throw UnimplementedError('No factory for $B'),
///   } as B;
/// }
/// ```
typedef BlocFactory = B Function<B extends BlocBase<Object>>();

/// Binds a [BlocFactory] to the current widget's [BuildContext].
///
/// This hook registers the given [factory] in the [BlocScopeRegistry],
/// making it available to the current widget and all of its descendants.
/// The factory is automatically unregistered and its associated
/// [BlocScope] is disposed when the widget is removed from the tree.
///
/// Must be called inside a [HookWidget.build] method.
///
/// ### Example
///
/// ```dart
/// class MyApp extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     useBlocScope(<B extends BlocBase<Object>>() {
///       return switch (B) {
///         const (CounterCubit) => CounterCubit(),
///         _ => throw UnimplementedError('No factory for $B'),
///       } as B;
///     });
///
///     return const MaterialApp(home: HomePage());
///   }
/// }
/// ```
///
/// See also:
///
///  * [BlocFactory], the typedef for the factory function.
///  * [BlocScopeRegistry], the singleton that manages factory registrations.
void useBlocScope(BlocFactory factory) {
  use(_BlocScopeHook(factory));
}

/// A [Hook] that manages the lifecycle of a [BlocFactory] registration.
///
/// Delegates to [_BlocScopeHookState] to register the factory on
/// initialization and unregister it on disposal.
final class _BlocScopeHook extends Hook<void> {
  const _BlocScopeHook(this.blocFactory);

  /// The factory function to register in the [BlocScopeRegistry].
  final BlocFactory blocFactory;

  @override
  _BlocScopeHookState createState() => _BlocScopeHookState();
}

/// The mutable state for [_BlocScopeHook].
///
/// On [initHook], registers the [BlocFactory] with the current
/// [BuildContext] in the [BlocScopeRegistry]. On [dispose],
/// unregisters it — which also disposes the associated [BlocScope]
/// and closes all blocs it created.
final class _BlocScopeHookState extends HookState<void, _BlocScopeHook> {
  final registerer = BlocScopeRegistry.instance;

  @override
  void initHook() {
    registerer.register(context, hook.blocFactory);
  }

  @override
  void build(BuildContext context) {
    // side effect
  }

  @override
  void dispose() {
    unawaited(registerer.unregister(context));
    super.dispose();
  }
}
