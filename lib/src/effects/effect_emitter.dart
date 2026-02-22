import 'dart:async';

/// An interface that defines the contract for emitting effects
/// in a Bloc or Cubit.
abstract interface class EffectEmitter<Effect> {
  /// The current [effectsStream] of effects.
  Stream<Effect> get effectsStream;

  /// Emits a new [effect].
  void emitEffect(Effect effect);
}
