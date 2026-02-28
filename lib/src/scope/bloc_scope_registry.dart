import 'dart:async';

import 'package:bloc_hooks/src/exceptions/exceptions.dart';
import 'package:bloc_hooks/src/hooks/use_bloc_scope.dart';
import 'package:bloc_hooks/src/scope/bloc_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// A singleton registry that associates [BlocScope] instances with
/// [BuildContext]s using an [Expando].
///
/// This registry is the central mechanism for binding and resolving
/// [BlocFactory] functions throughout the widget tree. When a
/// [BlocFactory] is registered via [useBlocScope], it creates a
/// [BlocScope] tied to that widget's [BuildContext]. Descendant widgets
/// can then resolve the nearest [BlocScope] via [lookup].
///
/// The registry is **not** tied to [InheritedWidget] — instead it uses
/// [Expando] to attach metadata to [BuildContext] objects without
/// modifying them, and [BuildContext.visitAncestorElements] to walk up the tree
/// during resolution.
///
/// See also:
///
///  * [BlocScope], the scoped container that holds bloc instances.
///  * [useBlocScope], the hook that calls [register] and [unregister].
final class BlocScopeRegistry {
  BlocScopeRegistry._();

  /// The global singleton instance of [BlocScopeRegistry].
  ///
  /// All registrations and lookups go through this single instance.
  static final instance = BlocScopeRegistry._();

  /// An [Expando] that maps each [BuildContext] to its associated
  /// [BlocScope], if one has been registered at that level.
  final _expando = Expando<BlocScope>('BlocFactoryRegistry');

  /// Resolves the nearest [BlocScope] for the given [context].
  ///
  /// First checks whether a [BlocScope] is directly attached to [context].
  /// If not, walks up the ancestor element tree using
  /// [BuildContext.visitAncestorElements] and returns the first
  /// [BlocScope] found.
  ///
  /// Throws a [NoBlocScopeFoundException] if no [BlocScope] is found
  /// anywhere in the ancestor chain. This typically means [useBlocScope]
  /// was never called above the requesting widget.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final scope = BlocScopeRegistry.instance.lookup(context);
  /// final cubit = scope.createBloc<CounterCubit, int>(context);
  /// ```
  BlocScope lookup(BuildContext context) {
    var scope = _expando[context];

    if (scope != null) {
      return scope;
    }

    BlocScope? nearestScope;

    context.visitAncestorElements(
      (element) {
        nearestScope = _expando[element];

        return nearestScope == null;
      },
    );

    scope = nearestScope;

    if (scope != null) {
      return scope;
    }

    throw const NoBlocScopeFoundException();
  }

  /// Registers a [BlocFactory] at the given [context].
  ///
  /// Creates a new [BlocScope] wrapping [factory] and attaches it to
  /// [context]. If a scope is already registered at this exact [context],
  /// the call is a no-op — the existing scope is preserved.
  ///
  /// This is typically called once during [HookState.initHook] by the
  /// [useBlocScope] hook.
  void register(BuildContext context, BlocFactory factory) {
    _expando[context] ??= BlocScope(context, factory);
  }

  /// Unregisters and disposes the [BlocScope] at the given [context].
  ///
  /// Removes the association between [context] and its [BlocScope],
  /// then calls [BlocScope.dispose] to close all blocs that were
  /// created within that scope.
  ///
  /// If no scope is registered at [context], this is a safe no-op.
  ///
  /// This is typically called during [HookState.dispose] by the
  /// [useBlocScope] hook.
  Future<void> unregister(BuildContext context) async {
    final disposingFactory = _expando[context];
    _expando[context] = null;

    await disposingFactory?.dispose();
  }
}
