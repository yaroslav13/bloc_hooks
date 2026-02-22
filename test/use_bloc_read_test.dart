import 'package:bloc_hooks/bloc_hooks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/cubits/todo_cubit.dart';
import 'utils/widgets/test_app.dart';
import 'utils/widgets/todo_binder.dart';

void main() {
  group('useBlocRead', () {
    testWidgets('returns the current state on first build', (tester) async {
      TodoState? read;

      await tester.pumpWidget(
        TestApp(
          child: TodoBinder(
            child: HookBuilder(
              builder: (_) {
                read = useBlocRead<TodoState>();
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(read, isNotNull);
      expect(read!.todos, isEmpty);
      expect(read!.filter, TodoFilter.all);
    });

    testWidgets('does not rebuild when state changes', (tester) async {
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
                    useBlocRead<TodoState>();
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

      cubit!.addTodo('Walk the dog');
      await tester.pump();

      expect(buildCount, 1); // still 1 – no re-render
    });

    testWidgets('memoizes – returns same object across builds forced by parent',
        (tester) async {
      late StateSetter parentSetState;
      final snapshots = <TodoState>[];

      await tester.pumpWidget(
        TestApp(
          child: TodoBinder(
            child: StatefulBuilder(
              builder: (_, setState) {
                parentSetState = setState;
                return HookBuilder(
                  builder: (_) {
                    snapshots.add(useBlocRead<TodoState>());
                    return const SizedBox();
                  },
                );
              },
            ),
          ),
        ),
      );

      parentSetState(() {}); // force rebuild
      await tester.pump();

      expect(snapshots.length, 2);
      expect(identical(snapshots[0], snapshots[1]), isTrue);
    });
  });
}
