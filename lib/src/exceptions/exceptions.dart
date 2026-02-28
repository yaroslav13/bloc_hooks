import 'package:bloc_hooks/src/hooks/bind_bloc.dart';
import 'package:bloc_hooks/src/hooks/use_bloc.dart';
import 'package:bloc_hooks/src/hooks/use_bloc_scope.dart';
import 'package:bloc_hooks/src/scope/bloc_scope.dart';
import 'package:bloc_hooks/src/scope/bloc_scope_registry.dart';

/// The base exception type for all exceptions thrown by the `bloc_hooks`
/// package.
///
/// All concrete exceptions extend this class, providing a human-readable
/// [message] that describes the error. Catch this type to handle any
/// `bloc_hooks` error generically:
///
/// ```dart
/// try {
///   final cubit = useBloc<MyCubit>();
/// } on BlocHooksException catch (e) {
///   debugPrint(e.message);
/// }
/// ```
abstract base class BlocHooksException implements Exception {
  /// Creates an exception with the given error [message].
  const BlocHooksException(this.message);

  /// A human-readable description of the error.
  final String message;

  @override
  String toString() => message;
}

/// Thrown when attempting to resolve a [BlocScope] from the
/// [BlocScopeRegistry], but no [BlocFactory] has been bound to the
/// current context or any of its ancestors.
///
/// This typically means [useBlocScope] was never called above the
/// widget that triggered the lookup.
///
/// ### Example trigger
///
/// ```dart
/// // No useBlocScope() call anywhere above this widget.
/// final cubit = useBloc<MyCubit>(); // throws NoBlocScopeFoundException
/// ```
final class NoBlocScopeFoundException extends BlocHooksException {
  /// Creates a [NoBlocScopeFoundException] with a default message.
  const NoBlocScopeFoundException()
      : super('BlocScope is not bound to the current context. '
            'Make sure useBlocScope() is called in an ancestor widget.');
}

/// Thrown when attempting to remove a bloc of type [B] from a [BlocScope],
/// but no bloc of that type was previously bound to the given context.
///
/// This typically means [bindBloc] was never called for [B] before
/// calling remove.
///
/// ### Example trigger
///
/// ```dart
/// // No bindBloc<MyCubit>() call for this context.
/// scope.removeBloc<MyCubit, int>(context); // throws BlocRemovalException
/// ```
final class RemovalException<B> extends BlocHooksException {
  /// Creates a [RemovalException] with a default message for type [B].
  const RemovalException()
      : super(
          'Could not remove bloc of type $B. '
          'Make sure you call bindBloc<$B>() before removing it.',
        );
}

/// Thrown when attempting to look up a bloc of type [B] via [useBloc],
/// but no bloc of that type has been bound in the current context or
/// any of its ancestors.
///
/// ### Example trigger
///
/// ```dart
/// // No bindBloc<MyCubit>() call anywhere above this widget.
/// final cubit = useBloc<MyCubit>(); // throws NotFoundException
/// ```
final class NotFoundException<B> extends BlocHooksException {
  /// Creates a [NotFoundException] with a default message for type [B].
  const NotFoundException()
      : super(
          'Could not find bloc of type $B. '
          'Make sure you call bindBloc<$B>() before using useBloc<$B>().',
        );
}

/// Thrown when attempting to bind a bloc of type [B] to a widget that
/// already has a bloc of the same type bound to it.
///
/// Each widget can host at most one bloc of a given type. If you need
/// multiple instances, bind them in separate child widgets.
///
/// ### Example trigger
///
/// ```dart
/// // Inside the same HookWidget.build():
/// bindBloc<MyCubit>();
/// bindBloc<MyCubit>(); // throws AlreadyBindException
/// ```
final class AlreadyBindException<B> extends BlocHooksException {
  /// Creates a [AlreadyBindException] for type [B] hosted by
  /// the widget named [blocHostWidgetName].
  const AlreadyBindException(String blocHostWidgetName)
      : super(
          'Cannot bind more than one bloc of type $B to '
          'the same $blocHostWidgetName host widget.',
        );
}
