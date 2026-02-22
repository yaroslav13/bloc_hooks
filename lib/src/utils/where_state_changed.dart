import 'dart:async';

import 'package:bloc_hooks/src/types/types.dart';

/// A [StreamTransformer] that filters state emissions using an optional
/// [when] predicate while tracking the previous state.
///
/// If [when] is `null`, every emission passes through unchanged.
/// If [when] is provided, only emissions for which
/// `when(previous, current)` returns `true` are forwarded.
///
/// The [initialState] is used as the first "previous" value for the
/// very first comparison.
///
/// Each instance maintains its own previous-state reference, so
/// multiple subscriptions do not interfere with each other.
///
/// ### Example
///
/// ```dart
/// bloc.stream
///     .transform(WhereStateChanged(
///       initialState: bloc.state,
///       when: (prev, curr) => prev.count != curr.count,
///     ))
///     .listen(print);
/// ```
final class WhereStateChanged<S> extends StreamTransformerBase<S, S> {
  /// Creates a transformer that filters by [when], starting with
  /// [initialState] as the first "previous" value.
  WhereStateChanged({
    required S initialState,
    required BlocStateCondition<S>? when,
  })  : _initialState = initialState,
        _when = when;

  final S _initialState;
  final BlocStateCondition<S>? _when;

  @override
  Stream<S> bind(Stream<S> stream) {
    var previous = _initialState;
    final when = _when;

    if (when == null) {
      return stream.map((state) {
        previous = state;
        return state;
      });
    }

    return stream.where((state) {
      final shouldForward = when(previous, state);
      previous = state;
      return shouldForward;
    });
  }
}
