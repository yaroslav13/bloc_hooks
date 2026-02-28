import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_hooks/src/effects/effect_emitter.dart';
import 'package:bloc_hooks/src/exceptions/exceptions.dart';
import 'package:bloc_hooks/src/hooks/bind_bloc.dart';
import 'package:bloc_hooks/src/hooks/use_bloc_scope.dart';
import 'package:bloc_hooks/src/scope/bloc_scope_registry.dart';
import 'package:flutter/material.dart';

/// A scoped container that creates, stores, and disposes bloc instances
/// on behalf of a single [BlocFactory] registration.
///
/// Each [BlocScope] is created by [BlocScopeRegistry.register] and is
/// tied to the [BuildContext] where [useBlocScope] was called. Blocs
/// are stored per *context* — a descendant [BuildContext] passed to
/// [createBloc] via [bindBloc] — so different widgets in the subtree
/// can own distinct bloc instances while sharing the same factory.
///
/// When the scope is disposed (via [dispose]), **all** blocs that were
/// created through it are closed, regardless of which context owns them.
///
/// See also:
///
///  * [BlocScopeRegistry], the singleton that manages scope lifecycles.
///  * [useBlocScope], the hook that registers a [BlocFactory].
///  * [bindBloc], the hook that creates a bloc in this scope.
final class BlocScope {
  /// Creates a [BlocScope] bound to [context] with the given [factory].
  BlocScope(this.context, this.factory);

  /// The [BuildContext] to which this scope is attached.
  final BuildContext context;

  /// The generic factory function used to instantiate blocs by type.
  final BlocFactory factory;

  final _blocsByContext =
      Expando<List<BlocBase<Object>>>('BlocScope.blocsByContext');
  final _scopedBlocs = <BlocBase<Object>>[];

  /// Creates a new bloc of type [B] with state [S] using [factory] and
  /// stores it in the context identified by [context].
  ///
  /// Returns the newly created bloc instance.
  B createBloc<B extends BlocBase<S>, S extends Object>(BuildContext context) {
    final bloc = factory<B>();

    final contextBlocs = (_blocsByContext[context] ?? [])..add(bloc);

    _blocsByContext[context] = contextBlocs;
    _scopedBlocs.add(bloc);

    return bloc;
  }

  /// Returns the bloc of type [B] stored in [context], or `null` if no
  /// such bloc exists.
  B? getBloc<B extends BlocBase<Object>>(BuildContext context) {
    return _blocsByContext[context]?.whereType<B>().firstOrNull;
  }

  /// Returns the first bloc whose state type matches [S] in [context],
  /// or `null` if none is found.
  BlocBase<S>? getBlocByState<S>(BuildContext context) {
    return _blocsByContext[context]
        ?.whereType<StateStreamableSource<S>>()
        .firstOrNull as BlocBase<S>?;
  }

  /// Removes and closes the bloc of type [B] from [context].
  ///
  /// Throws a [BlocRemovalException] if no bloc of type [B] was found
  /// in [context].
  Future<void> removeBloc<B extends BlocBase<S>, S extends Object>(
    BuildContext context,
  ) async {
    final bloc = getBloc<B>(context);
    final blocRemoved = _blocsByContext[context]?.remove(bloc) ?? false;

    if (!blocRemoved || bloc == null) {
      throw BlocRemovalException<B>();
    }

    _scopedBlocs.remove(bloc);
    await bloc.close();
  }

  /// Returns the first bloc in [context] that implements [EffectEmitter]<[E]>,
  /// or `null` if none is found.
  EffectEmitter<E>? getBlocWithEffects<E>(BuildContext context) {
    return _blocsByContext[context]?.whereType<EffectEmitter<E>>().firstOrNull;
  }

  /// Closes **all** blocs created through this scope (in reverse
  /// creation order) and clears the internal list.
  ///
  /// Called automatically by [BlocScopeRegistry.unregister] when the
  /// widget that owns this scope is removed from the tree.
  Future<void> dispose() async {
    await Future.wait(
      [
        for (final bloc in _scopedBlocs.reversed) bloc.close(),
      ],
    );
    _scopedBlocs.clear();
  }
}
