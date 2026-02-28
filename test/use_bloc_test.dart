import 'package:bloc_hooks/bloc_hooks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/cubits/todo_cubit.dart';
import 'utils/widgets/test_app.dart';
import 'utils/widgets/todo_binder.dart';

void main() {
  group('useBloc', () {
    testWidgets('returns the same instance that bindBloc created',
        (tester) async {
      TodoCubit? bound;
      TodoCubit? hooked;

      await tester.pumpWidget(
        TestApp(
          child: HookBuilder(
            builder: (_) {
              bindBloc<TodoCubit, TodoState>(onCreated: (c) => bound = c);

              return Builder(
                builder: (_) => HookBuilder(
                  builder: (_) {
                    hooked = useBloc<TodoCubit>();
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(identical(bound, hooked), isTrue);
    });

    testWidgets('does not cause rebuilds when state changes', (tester) async {
      var buildCount = 0;
      TodoCubit? cubit;

      await tester.pumpWidget(
        TestApp(
          child: HookBuilder(
            builder: (_) {
              bindBloc<TodoCubit, TodoState>(onCreated: (c) => cubit = c);

              return Builder(
                builder: (_) => HookBuilder(
                  builder: (_) {
                    useBloc<TodoCubit>();
                    buildCount++;
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(buildCount, 1);

      cubit!.addTodo('Buy milk');
      await tester.pump();

      expect(buildCount, 1); // no rebuild
    });

    testWidgets('siblings sharing an ancestor binding get same instance',
        (tester) async {
      TodoCubit? sibling1;
      TodoCubit? sibling2;

      await tester.pumpWidget(
        TestApp(
          child: TodoBinder(
            child: Column(
              children: [
                HookBuilder(
                  builder: (_) {
                    sibling1 = useBloc<TodoCubit>();
                    return const SizedBox();
                  },
                ),
                HookBuilder(
                  builder: (_) {
                    sibling2 = useBloc<TodoCubit>();
                    return const SizedBox();
                  },
                ),
              ],
            ),
          ),
        ),
      );

      expect(identical(sibling1, sibling2), isTrue);
    });

    testWidgets('throws BlocNotFoundException when no binding exists',
        (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: HookBuilder(
            builder: (_) {
              useBloc<TodoCubit>();
              return const SizedBox();
            },
          ),
        ),
      );

      expect(tester.takeException(), isA<NotFoundException<TodoCubit>>());
    });

    testWidgets('resolves the closest ancestor binding', (tester) async {
      TodoCubit? parentCubit;
      TodoCubit? childCubit;
      TodoCubit? resolved;

      await tester.pumpWidget(
        TestApp(
          child: HookBuilder(
            builder: (_) {
              bindBloc<TodoCubit, TodoState>(
                onCreated: (c) => parentCubit = c,
              );

              return Builder(
                builder: (_) => HookBuilder(
                  builder: (_) {
                    bindBloc<TodoCubit, TodoState>(
                      onCreated: (c) => childCubit = c,
                    );

                    return Builder(
                      builder: (_) => HookBuilder(
                        builder: (_) {
                          resolved = useBloc<TodoCubit>();
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

      expect(identical(resolved, childCubit), isTrue);
      expect(identical(resolved, parentCubit), isFalse);
    });
  });
}
