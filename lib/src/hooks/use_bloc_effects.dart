import 'package:bloc_hooks/src/effects/effect_emitter.dart';
import 'package:bloc_hooks/src/effects/effects.dart';
import 'package:bloc_hooks/src/hooks/use_bloc_listen.dart';
import 'package:bloc_hooks/src/scope/bloc_scope_registry.dart';
import 'package:bloc_hooks/src/utils/find_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Subscribes to the one-shot effect stream of the nearest bloc that
/// implements [EffectEmitter]<[E]> and invokes [onEffect] for each emitted
/// effect.
///
/// Unlike state, effects are fire-and-forget — they are delivered
/// exactly once and are not replayed on widget rebuild. This makes
/// them ideal for ephemeral UI actions such as showing a dialog,
/// navigating, or displaying a snack-bar.
///
/// The subscription is set up inside [useEffect] and is automatically
/// cancelled when the widget is disposed. Pass [keys] to control when
/// the subscription is recreated (defaults to `[context]`).
///
/// The callback is skipped if the widget's [BuildContext] is no longer
/// mounted, preventing use of a stale context.
///
/// Must be called inside a [HookWidget.build] method.
///
/// ### Parameters
///
/// * [onEffect] — callback invoked with the current [BuildContext] and
///   the emitted effect value.
/// * [keys] — optional list of keys forwarded to [useEffect] to control
///   subscription lifecycle.
///
/// ### Example
///
/// ```dart
/// class CounterPage extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     useBlocEffects<UiEffect>((context, effect) {
///       if (effect is ShowSnackBar) {
///         ScaffoldMessenger.of(context).showSnackBar(
///           SnackBar(content: Text(effect.message)),
///         );
///       }
///     });
///
///     return const SizedBox();
///   }
/// }
/// ```
///
/// See also:
///
///  * [Effects], the mixin that adds effect emission to a bloc.
///  * [EffectEmitter], the interface defining the effect contract.
///  * [useBlocListen], for reacting to *state* changes without rebuilds.
void useBlocEffects<E extends Object>(
  void Function(BuildContext, E) onEffect, [
  List<Object?>? keys,
]) {
  final context = useContext();

  useEffect(
    () {
      final scope = BlocScopeRegistry.instance.lookup(context);

      final bloc = findBloc(
        context,
        findMethod: scope.getBlocWithEffects<E>,
      );

      final subscription = bloc.effectsStream.listen(
        (effect) {
          if (!context.mounted) {
            return;
          }

          onEffect(context, effect);
        },
      );

      return subscription.cancel;
    },
    [context, ...?keys],
  );
}
