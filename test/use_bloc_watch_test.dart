import 'package:bloc_hooks/bloc_hooks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/cubits/todo_cubit.dart';
import 'utils/widgets/test_app.dart';
import 'utils/widgets/todo_binder.dart';

void main() {
  group('useBlocWatch', () {
    testWidgets('returns initial state on first build', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: TodoBinder(
            child: HookBuilder(
              builder: (_) {
                final state = useBlocWatch<TodoState>();
                return Text('${state.todos.length}');
              },
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('rebuilds on every state emission', (tester) async {
      var buildCount = 0;

      await tester.pumpWidget(
        TestApp(
          child: TodoBinder(
            child: HookBuilder(
              builder: (_) {
                final state = useBlocWatch<TodoState>();
                final cubit = useBloc<TodoCubit>();
                buildCount++;

                return Column(
                  children: [
                    Text('${state.todos.length}'),
                    ElevatedButton(
                      onPressed: () => cubit.addTodo('item'),
                      child: const Text('Add'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(buildCount, 1);
      expect(find.text('0'), findsOneWidget);

      await tester.tap(find.text('Add'));
      await tester.pump();
      expect(buildCount, 2);
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.text('Add'));
      await tester.pump();
      expect(buildCount, 3);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('skips rebuild when "when" returns false', (tester) async {
      var buildCount = 0;

      await tester.pumpWidget(
        TestApp(
          child: TodoBinder(
            child: HookBuilder(
              builder: (_) {
                // Only rebuild when a todo is added (list grows).
                final state = useBlocWatch<TodoState>(
                  when: (prev, curr) => curr.todos.length > prev.todos.length,
                );
                final cubit = useBloc<TodoCubit>();
                buildCount++;

                return Column(
                  children: [
                    Text('${state.todos.length}'),
                    ElevatedButton(
                      onPressed: () => cubit.addTodo('task'),
                      child: const Text('Add'),
                    ),
                    ElevatedButton(
                      onPressed: () => cubit.setFilter(TodoFilter.completed),
                      child: const Text('Filter'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(buildCount, 1);

      // Add → list grows → rebuild
      await tester.tap(find.text('Add'));
      await tester.pump();
      expect(buildCount, 2);

      // Change filter → list length unchanged → no rebuild
      await tester.tap(find.text('Filter'));
      await tester.pump();
      expect(buildCount, 2);
    });

    testWidgets('single rebuild per emission even with two useBlocWatch calls',
        (tester) async {
      var buildCount = 0;

      await tester.pumpWidget(
        TestApp(
          child: TodoBinder(
            child: HookBuilder(
              builder: (_) {
                useBlocWatch<TodoState>();
                useBlocWatch<TodoState>();
                final cubit = useBloc<TodoCubit>();
                buildCount++;

                return ElevatedButton(
                  onPressed: () => cubit.addTodo('x'),
                  child: const Text('Add'),
                );
              },
            ),
          ),
        ),
      );

      expect(buildCount, 1);

      await tester.tap(find.text('Add'));
      await tester.pump();

      expect(buildCount, 2);
    });

    testWidgets('sibling watchers both update from the same bloc',
        (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: TodoBinder(
            child: Column(
              children: [
                HookBuilder(
                  builder: (_) {
                    final s = useBlocWatch<TodoState>();
                    final c = useBloc<TodoCubit>();
                    return Row(
                      children: [
                        Text('A:${s.todos.length}'),
                        ElevatedButton(
                          onPressed: () => c.addTodo('x'),
                          child: const Text('Add'),
                        ),
                      ],
                    );
                  },
                ),
                HookBuilder(
                  builder: (_) {
                    final s = useBlocWatch<TodoState>();
                    return Text('B:${s.todos.length}');
                  },
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('A:0'), findsOneWidget);
      expect(find.text('B:0'), findsOneWidget);

      await tester.tap(find.text('Add'));
      await tester.pump();

      expect(find.text('A:1'), findsOneWidget);
      expect(find.text('B:1'), findsOneWidget);
    });
  });
}
