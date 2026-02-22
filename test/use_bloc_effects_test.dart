import 'package:bloc_hooks/bloc_hooks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/cubits/notification_cubit.dart';
import 'utils/utils.dart';

void main() {
  group('useBlocEffects', () {
    testWidgets('receives emitted effects', (tester) async {
      final effects = <NotificationEffect>[];

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (_) {
              useBlocScope(appFactory);

              return Builder(
                builder: (_) => HookBuilder(
                  builder: (_) {
                    bindBloc<NotificationCubit, NotificationState>();

                    return Builder(
                      builder: (_) => HookBuilder(
                        builder: (_) {
                          final cubit = useBloc<NotificationCubit>();
                          useBlocEffects<NotificationEffect>((_, e) {
                            effects.add(e);
                          });

                          return ElevatedButton(
                            onPressed: () => cubit.showToast('hello'),
                            child: const Text('Toast'),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(effects, isEmpty);

      await tester.tap(find.text('Toast'));
      await tester.pump();

      expect(effects.length, 1);
      expect(effects.first, isA<ShowToast>());
      expect((effects.first as ShowToast).message, 'hello');
    });

    testWidgets('receives multiple effect types', (tester) async {
      final effects = <NotificationEffect>[];
      NotificationCubit? cubit;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (_) {
              useBlocScope(appFactory);

              return Builder(
                builder: (_) => HookBuilder(
                  builder: (_) {
                    bindBloc<NotificationCubit, NotificationState>(
                      onCreated: (c) => cubit = c,
                    );

                    return Builder(
                      builder: (_) => HookBuilder(
                        builder: (_) {
                          useBlocEffects<NotificationEffect>((_, e) {
                            effects.add(e);
                          });
                          return const SizedBox();
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      );

      cubit!.showToast('hey');
      await tester.pump();
      cubit!.playNotificationSound('ding.mp3');
      await tester.pump();

      expect(effects.length, 2);
      expect(effects[0], isA<ShowToast>());
      expect(effects[1], isA<PlaySound>());
      expect((effects[1] as PlaySound).sound, 'ding.mp3');
    });
  });

  group('Effects mixin (unit)', () {
    test('emitEffect delivers to effectsStream', () async {
      final cubit = NotificationCubit();
      final received = <NotificationEffect>[];

      cubit.effectsStream.listen(received.add);

      cubit.showToast('hi');
      await Future<void>.delayed(Duration.zero);

      expect(received.length, 1);
      expect((received.first as ShowToast).message, 'hi');

      await cubit.close();
    });

    test('effectsStream is broadcast – supports multiple listeners', () async {
      final cubit = NotificationCubit();
      final a = <NotificationEffect>[];
      final b = <NotificationEffect>[];

      cubit.effectsStream.listen(a.add);
      cubit.effectsStream.listen(b.add);

      cubit.playNotificationSound('pop.wav');
      await Future<void>.delayed(Duration.zero);

      expect(a.length, 1);
      expect(b.length, 1);

      await cubit.close();
    });

    test('throws StateError when emitting after close', () async {
      final cubit = NotificationCubit();
      await cubit.close();

      expect(
        () => cubit.showToast('late'),
        throwsStateError,
      );
    });
  });
}
