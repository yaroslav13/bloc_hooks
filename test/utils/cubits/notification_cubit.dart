import 'package:bloc/bloc.dart';
import 'package:bloc_hooks/bloc_hooks.dart';
import 'package:flutter/foundation.dart';

/// One-shot UI effects emitted by [NotificationCubit].
sealed class NotificationEffect {}

final class ShowToast extends NotificationEffect {
  ShowToast(this.message);
  final String message;
}

final class PlaySound extends NotificationEffect {
  PlaySound(this.sound);
  final String sound;
}

/// A cubit that holds notification preferences and can emit one-shot effects.
final class NotificationCubit extends Cubit<NotificationState>
    with Effects<NotificationEffect> {
  NotificationCubit() : super(const NotificationState());

  void enableSound() => emit(state.copyWith(soundEnabled: true));

  void disableSound() => emit(state.copyWith(soundEnabled: false));

  void setBadgeCount(int count) => emit(state.copyWith(badgeCount: count));

  void showToast(String message) => emitEffect(ShowToast(message));

  void playNotificationSound(String sound) => emitEffect(PlaySound(sound));
}

@immutable
final class NotificationState {
  const NotificationState({
    this.soundEnabled = true,
    this.badgeCount = 0,
  });

  final bool soundEnabled;
  final int badgeCount;

  NotificationState copyWith({
    bool? soundEnabled,
    int? badgeCount,
  }) =>
      NotificationState(
        soundEnabled: soundEnabled ?? this.soundEnabled,
        badgeCount: badgeCount ?? this.badgeCount,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationState &&
          soundEnabled == other.soundEnabled &&
          badgeCount == other.badgeCount;

  @override
  int get hashCode => Object.hash(soundEnabled, badgeCount);
}
