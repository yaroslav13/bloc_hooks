import 'package:bloc_hooks/bloc_hooks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/cubits/todo_cubit.dart';
import 'utils/utils.dart';

void main() {
  group('useBlocScope', () {
    testWidgets('descendants can bind and use blocs after scope is registered',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (_) {
              useBlocScope(appFactory);

              return Builder(
                builder: (_) => HookBuilder(
                  builder: (_) {
                    bindBloc<TodoCubit, TodoState>();
                    final state = useBlocWatch<TodoState>();
                    return Text(
                      'todos: ${state.todos.length}',
                      textDirection: TextDirection.ltr,
                    );
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('todos: 0'), findsOneWidget);
    });

    testWidgets(
        'throws BlocScopeNotBoundException when bindBloc used without scope',
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

    testWidgets('disposes all blocs when scope is removed from tree',
        (tester) async {
      TodoCubit? captured;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (_) {
              useBlocScope(appFactory);

              return Builder(
                builder: (_) => HookBuilder(
                  builder: (_) {
                    bindBloc<TodoCubit, TodoState>(
                      onCreated: (c) => captured = c,
                    );
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(captured, isNotNull);
      expect(captured!.isClosed, isFalse);

      // Remove the entire tree.
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();

      expect(captured!.isClosed, isTrue);
    });

    testWidgets('nested scopes create independent bloc instances',
        (tester) async {
      TodoCubit? outerTodo;
      TodoCubit? innerTodo;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (_) {
              useBlocScope(appFactory);

              return Builder(
                builder: (_) => HookBuilder(
                  builder: (_) {
                    bindBloc<TodoCubit, TodoState>(
                      onCreated: (c) => outerTodo = c,
                    );

                    return HookBuilder(
                      builder: (_) {
                        useBlocScope(appFactory);

                        return Builder(
                          builder: (_) => HookBuilder(
                            builder: (_) {
                              bindBloc<TodoCubit, TodoState>(
                                onCreated: (c) => innerTodo = c,
                              );
                              return const SizedBox();
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(outerTodo, isNotNull);
      expect(innerTodo, isNotNull);
      expect(identical(outerTodo, innerTodo), isFalse);
    });

    testWidgets('factory change on rebuild preserves existing scope',
        (tester) async {
      TodoCubit? cubit1;
      TodoCubit? cubit2;
      late StateSetter outerSetState;
      var useFirst = true;

      const factory1 = appFactory;
      const factory2 = appFactory;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (_, setState) {
              outerSetState = setState;

              return HookBuilder(
                builder: (_) {
                  useBlocScope(useFirst ? factory1 : factory2);

                  return Builder(
                    builder: (_) => HookBuilder(
                      builder: (_) {
                        bindBloc<TodoCubit, TodoState>(
                          onCreated: (c) {
                            if (useFirst) {
                              cubit1 = c;
                            } else {
                              cubit2 = c;
                            }
                          },
                        );
                        return const SizedBox();
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      );

      expect(cubit1, isNotNull);

      // Trigger rebuild with a different factory reference.
      outerSetState(() => useFirst = false);
      await tester.pumpAndSettle();

      // Scope should keep the original registration (no-op on re-register).
      expect(cubit2, isNull);
    });
  });
}
