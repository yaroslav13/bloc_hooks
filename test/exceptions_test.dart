import 'package:bloc/bloc.dart';
import 'package:bloc_hooks/bloc_hooks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/cubits/todo_cubit.dart';
import 'utils/utils.dart';

void main() {
  group('exceptions', () {
    testWidgets('BlocScopeNotBoundException when no useBlocScope in ancestors',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (_) {
              bindBloc<TodoCubit, TodoState>();
              return const SizedBox();
            },
          ),
        ),
      );

      expect(tester.takeException(), isA<BlocScopeNotBoundException>());
    });

    testWidgets('BlocNotFoundException when no bindBloc for requested type',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (_) {
              useBlocScope(appFactory);

              return Builder(
                builder: (_) => HookBuilder(
                  builder: (_) {
                    useBlocWatch<TodoState>();
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(
        tester.takeException(),
        isA<BlocNotFoundException<BlocBase<TodoState>>>(),
      );
    });

    testWidgets('exception when factory does not support the bloc type',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (_) {
              useBlocScope(appFactory);

              return Builder(
                builder: (_) => HookBuilder(
                  builder: (_) {
                    bindBloc<UnknownCubit, UnknownState>();
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(tester.takeException(), isNotNull);
    });

    test('BlocScopeNotBoundException has descriptive message', () {
      const e = BlocScopeNotBoundException();
      expect(e.message, contains('useBlocScope()'));
      expect(e.toString(), e.message);
    });

    test('BlocNotFoundException message includes the type', () {
      final e = BlocNotFoundException<TodoCubit>();
      expect(e.message, contains('TodoCubit'));
    });

    test('BlocRemovalException message includes the type', () {
      final e = BlocRemovalException<TodoCubit>();
      expect(e.message, contains('TodoCubit'));
    });

    test('BlocDuplicateBindingException message includes type and host', () {
      final e = BlocDuplicateBindingException<TodoCubit>('MyPage');
      expect(e.message, contains('TodoCubit'));
      expect(e.message, contains('MyPage'));
    });
  });
}
