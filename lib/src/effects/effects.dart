import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_hooks/src/effects/effect_emitter.dart';
import 'package:flutter/foundation.dart';

/// A mixin that provides effects capabilities to a [Bloc] and [Cubit].
base mixin Effects<E> on Closable implements EffectEmitter<E> {
  late final _effectController = StreamController<E>.broadcast();

  @override
  Stream<E> get effectsStream => _effectController.stream;

  @protected
  @visibleForTesting
  @override
  void emitEffect(E effect) {
    if (isClosed || _isEffectsClosed) {
      throw StateError('Cannot use effects after calling close');
    }

    _effectController.add(effect);
  }

  @mustCallSuper
  @override
  Future<void> close() async {
    if (!_isEffectsClosed) {
      await _effectController.close();
    }
    await super.close();
  }

  bool get _isEffectsClosed => _effectController.isClosed;
}
