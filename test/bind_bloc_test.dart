import 'package:bloc/bloc.dart';
import 'package:bloc_hooks/bloc_hooks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/cubits/auth_cubit.dart';
import 'utils/cubits/todo_cubit.dart';
import 'utils/utils.dart';
import 'utils/widgets/test_app.dart';

void main() {
  group('bindBloc', () {
    testWidgets('creates bloc accessible via useBloc in subtree',
        (tester) async {
      TodoCubit? captured;

      await tester.pumpWidget(
        TestApp(
          child: HookBuilder(
            builder: (_) {
              bindBloc<TodoCubit, TodoState>();

              return Builder(
                builder: (_) => HookBuilder(
                  builder: (_) {
                    captured = useBloc<TodoCubit>();
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(captured, isA<TodoCubit>());
    });

    testWidgets('invokes onCreated callback', (tester) async {
      TodoCubit? created;

      await tester.pumpWidget(
        TestApp(
          child: HookBuilder(
            builder: (_) {
              bindBloc<TodoCubit, TodoState>(
                onCreated: (c) => created = c,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(created, isA<TodoCubit>());
    });

    testWidgets('invokes onDisposed callback when widget is removed',
        (tester) async {
      TodoCubit? disposed;

      await tester.pumpWidget(
        TestApp(
          child: HookBuilder(
            builder: (_) {
              bindBloc<TodoCubit, TodoState>(
                onDisposed: (c) => disposed = c,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(disposed, isNull);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();

      expect(disposed, isA<TodoCubit>());
    });

    testWidgets('assertion error when same type bound twice in one widget',
        (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: HookBuilder(
            builder: (_) {
              bindBloc<TodoCubit, TodoState>();
              bindBloc<TodoCubit, TodoState>();
              return const SizedBox();
            },
          ),
        ),
      );

      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('two different bloc types can be bound in the same widget',
        (tester) async {
      TodoCubit? todo;
      AuthCubit? auth;

      await tester.pumpWidget(
        TestApp(
          child: HookBuilder(
            builder: (_) {
              bindBloc<TodoCubit, TodoState>(onCreated: (c) => todo = c);
              bindBloc<AuthCubit, AuthState>(onCreated: (c) => auth = c);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(todo, isA<TodoCubit>());
      expect(auth, isA<AuthCubit>());
      expect(identical(todo, auth), isFalse);
    });

    testWidgets(
        'same type bound at different tree levels → different instances',
        (tester) async {
      TodoCubit? parent;
      TodoCubit? child;

      await tester.pumpWidget(
        TestApp(
          child: HookBuilder(
            builder: (_) {
              bindBloc<TodoCubit, TodoState>(onCreated: (c) => parent = c);

              return Builder(
                builder: (_) => HookBuilder(
                  builder: (_) {
                    bindBloc<TodoCubit, TodoState>(onCreated: (c) => child = c);
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(parent, isNotNull);
      expect(child, isNotNull);
      expect(identical(parent, child), isFalse);
    });

    testWidgets('bloc is closed when the binding widget leaves the tree',
        (tester) async {
      TodoCubit? cubit;

      await tester.pumpWidget(
        TestApp(
          child: HookBuilder(
            builder: (_) {
              bindBloc<TodoCubit, TodoState>(onCreated: (c) => cubit = c);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(cubit!.isClosed, isFalse);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();

      expect(cubit!.isClosed, isTrue);
    });

    testWidgets('bloc is not accessible higher in the tree', (tester) async {
      // The watcher widget is a sibling placed *before* the binder,
      // so useBlocWatch cannot find a bound TodoCubit.
      await tester.pumpWidget(
        TestApp(
          child: HookBuilder(
            builder: (_) {
              // Try to watch without any binding above us.
              useBlocWatch<TodoState>();
              return const SizedBox();
            },
          ),
        ),
      );

      final exception = tester.takeException();
      expect(exception, isA<BlocNotFoundException<BlocBase<TodoState>>>());
    });

    testWidgets('exception when factory does not know the requested type',
        (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: HookBuilder(
            builder: (_) {
              bindBloc<UnknownCubit, UnknownState>();
              return const SizedBox();
            },
          ),
        ),
      );

      expect(tester.takeException(), isNotNull);
    });

    testWidgets('assertion error when bindBloc called outside HookWidget.build',
        (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => bindBloc<TodoCubit, TodoState>(),
                child: const Text('Bind'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Bind'));

      expect(tester.takeException(), isA<AssertionError>());
    });
  });
}
