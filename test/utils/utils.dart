import 'package:bloc/bloc.dart';

import 'cubits/auth_cubit.dart';
import 'cubits/notification_cubit.dart';
import 'cubits/todo_cubit.dart';

/// A cubit type that is intentionally *not* registered in [appFactory].
class UnknownCubit extends Cubit<UnknownState> {
  UnknownCubit() : super(const UnknownState());
}

final class UnknownState {
  const UnknownState();
}

/// Factory that knows how to create all domain cubits.
T appFactory<T extends BlocBase<Object>>() {
  return switch (T) {
    const (TodoCubit) => TodoCubit() as T,
    const (AuthCubit) => AuthCubit() as T,
    const (NotificationCubit) => NotificationCubit() as T,
    _ => throw UnimplementedError('No factory for $T'),
  };
}
