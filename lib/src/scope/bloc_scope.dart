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
/// are stored per *slot* — a descendant [BuildContext] passed to
/// [createBloc] via [bindBloc] — so different widgets in the subtree
/// can own distinct bloc instances while sharing the same factory.
///
/// When the scope is disposed (via [dispose]), **all** blocs that were
/// created through it are closed, regardless of which slot owns them.
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

  final _slotsExpando = Expando<List<BlocBase<Object>>>('BlocFactory.slots');
  final _allBlocs = <BlocBase<Object>>[];

  /// Creates a new bloc of type [B] with state [S] using [factory] and
  /// stores it in the slot identified by [slot].
  ///
  /// Returns the newly created bloc instance.
  B createBloc<B extends BlocBase<S>, S extends Object>(BuildContext slot) {
    final bloc = factory<B>();

    final currentListOfBlocs = (_slotsExpando[slot] ?? [])..add(bloc);

    _slotsExpando[slot] = currentListOfBlocs;
    _allBlocs.add(bloc);

    return bloc;
  }

  /// Returns the bloc of type [B] stored in [slot], or `null` if no
  /// such bloc exists.
  B? getBloc<B extends BlocBase<Object>>(BuildContext slot) {
    return _slotsExpando[slot]?.whereType<B>().firstOrNull;
  }

  /// Returns the first bloc whose state type matches [S] in [slot],
  /// or `null` if none is found.
  BlocBase<S>? getBlocByState<S>(BuildContext slot) {
    return _slotsExpando[slot]
        ?.whereType<StateStreamableSource<S>>()
        .firstOrNull as BlocBase<S>?;
  }

  /// Removes and closes the bloc of type [B] from [slot].
  ///
  /// Throws a [BlocRemovalException] if no bloc of type [B] was found
  /// in [slot].
  void removeBloc<B extends BlocBase<S>, S extends Object>(BuildContext slot) {
    final bloc = getBloc<B>(slot);
    final blocRemoved = _slotsExpando[slot]?.remove(bloc) ?? false;

    if (!blocRemoved || bloc == null) {
      throw BlocRemovalException<B>();
    }

    _allBlocs.remove(bloc);
    unawaited(bloc.close());
  }

  /// Returns the first bloc in [slot] that implements [EffectEmitter]<[E]>,
  /// or `null` if none is found.
  EffectEmitter<E>? getBlocWithEffects<E>(BuildContext slot) {
    return _slotsExpando[slot]?.whereType<EffectEmitter<E>>().firstOrNull;
  }

  /// Closes **all** blocs created through this scope (in reverse
  /// creation order) and clears the internal list.
  ///
  /// Called automatically by [BlocScopeRegistry.unregister] when the
  /// widget that owns this scope is removed from the tree.
  Future<void> dispose() async {
    await Future.wait(
      [
        for (final bloc in _allBlocs.reversed) bloc.close(),
      ],
    );
    _allBlocs.clear();
  }
}
