import 'package:bloc_hooks/src/exceptions/exceptions.dart';
import 'package:bloc_hooks/src/hooks/use_bloc.dart';
import 'package:bloc_hooks/src/hooks/use_bloc_select.dart';
import 'package:bloc_hooks/src/hooks/use_bloc_watch.dart';
import 'package:flutter/widgets.dart';

/// Resolves a value of type [B] by first checking the given [context]
/// and then walking up the ancestor element tree.
///
/// [locator] is called with the current [context] first. If it
/// returns `null`, [BuildContext.visitAncestorElements] is used to
/// probe each ancestor until a non-null result is found.
///
/// Throws a [BlocNotFoundException]<[B]> if no ancestor yields a
/// non-null result.
///
/// This is an internal utility used by the public hooks ([useBloc],
/// [useBlocWatch], [useBlocSelect], etc.) and is not exported from
/// the package's public API.
B lookupBloc<B>(
  BuildContext context, {
  required B? Function(BuildContext) locator,
}) {
  final bloc = locator(context);

  if (bloc != null) {
    return bloc;
  } else {
    B? found;

    context.visitAncestorElements(
      (element) {
        found = locator(element);

        return found == null;
      },
    );

    final foundBloc = found;

    if (foundBloc == null) {
      throw BlocNotFoundException<B>();
    }

    return foundBloc;
  }
}
