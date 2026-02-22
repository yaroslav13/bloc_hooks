import 'package:bloc_hooks/src/hooks/use_bloc_listen.dart';
import 'package:bloc_hooks/src/hooks/use_bloc_select.dart';
import 'package:bloc_hooks/src/hooks/use_bloc_watch.dart';
import 'package:bloc_hooks/src/utils/where_state_changed.dart';

/// A predicate that compares the [previous] and [current] state of a bloc
/// and returns `true` when a subscriber should be notified of the change.
///
/// Used by [useBlocWatch], [useBlocSelect], [useBlocListen], and
/// [WhereStateChanged] to filter state emissions.
typedef BlocStateCondition<S> = bool Function(S previous, S current);
