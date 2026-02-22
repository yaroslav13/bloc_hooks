import 'package:bloc_hooks/bloc_hooks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/cubits/todo_cubit.dart';
import 'utils/widgets/test_app.dart';
import 'utils/widgets/todo_binder.dart';

void main() {
  group('useBlocSelect', () {
    testWidgets('returns the selected value from initial state',
        (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: TodoBinder(
            child: HookBuilder(
              builder: (_) {
                final filter = useBlocSelect<TodoState, TodoFilter>(
                  (s) => s.filter,
                );
                return Text(filter.name);
              },
            ),
          ),
        ),
      );

      expect(find.text('all'), findsOneWidget);
    });

    testWidgets('rebuilds only when the selected value changes',
        (tester) async {
      var buildCount = 0;

      await tester.pumpWidget(
        TestApp(
          child: TodoBinder(
            child: HookBuilder(
              builder: (_) {
                final filter = useBlocSelect<TodoState, TodoFilter>(
                  (s) => s.filter,
                );
                final cubit = useBloc<TodoCubit>();
                buildCount++;

                return Column(
                  children: [
                    Text(filter.name),
                    ElevatedButton(
                      onPressed: () => cubit.addTodo('ignored'),
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

      // Adding a todo doesn't change filter → no rebuild
      await tester.tap(find.text('Add'));
      await tester.pump();
      expect(buildCount, 1);

      // Changing filter → rebuild
      await tester.tap(find.text('Filter'));
      await tester.pump();
      expect(buildCount, 2);
      expect(find.text('completed'), findsOneWidget);
    });

    testWidgets('selecting derived value (completedCount)', (tester) async {
      var buildCount = 0;

      await tester.pumpWidget(
        TestApp(
          child: TodoBinder(
            child: HookBuilder(
              builder: (_) {
                final done = useBlocSelect<TodoState, int>(
                  (s) => s.completedCount,
                );
                final cubit = useBloc<TodoCubit>();
                buildCount++;

                return Column(
                  children: [
                    Text('done:$done'),
                    ElevatedButton(
                      onPressed: () => cubit.addTodo('task'),
                      child: const Text('Add'),
                    ),
                    ElevatedButton(
                      onPressed: () => cubit.toggleTodo(0),
                      child: const Text('Toggle'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(buildCount, 1);
      expect(find.text('done:0'), findsOneWidget);

      // Add a todo (completedCount stays 0) → no rebuild
      await tester.tap(find.text('Add'));
      await tester.pump();
      expect(buildCount, 1);

      // Toggle it to done (completedCount 0→1) → rebuild
      await tester.tap(find.text('Toggle'));
      await tester.pump();
      expect(buildCount, 2);
      expect(find.text('done:1'), findsOneWidget);
    });

    testWidgets('custom "when" predicate controls selector evaluation',
        (tester) async {
      var buildCount = 0;

      await tester.pumpWidget(
        TestApp(
          child: TodoBinder(
            child: HookBuilder(
              builder: (_) {
                // Only consider state when todos list is non-empty.
                final count = useBlocSelect<TodoState, int>(
                  (s) => s.todos.length,
                  when: (prev, curr) => curr.todos.isNotEmpty,
                );
                final cubit = useBloc<TodoCubit>();
                buildCount++;

                return Column(
                  children: [
                    Text('count:$count'),
                    ElevatedButton(
                      onPressed: () => cubit.setFilter(TodoFilter.active),
                      child: const Text('ChangeFilter'),
                    ),
                    ElevatedButton(
                      onPressed: () => cubit.addTodo('x'),
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

      // Filter change while list is empty → when returns false → no rebuild
      await tester.tap(find.text('ChangeFilter'));
      await tester.pump();
      expect(buildCount, 1);

      // Add item → when returns true and count changes → rebuild
      await tester.tap(find.text('Add'));
      await tester.pump();
      expect(buildCount, 2);
      expect(find.text('count:1'), findsOneWidget);
    });

    testWidgets('useBlocSelect + useBlocWatch together: one rebuild per emit',
        (tester) async {
      var buildCount = 0;

      await tester.pumpWidget(
        TestApp(
          child: TodoBinder(
            child: HookBuilder(
              builder: (_) {
                final state = useBlocWatch<TodoState>();
                final filter = useBlocSelect<TodoState, TodoFilter>(
                  (s) => s.filter,
                );
                final cubit = useBloc<TodoCubit>();
                buildCount++;

                return Column(
                  children: [
                    Text('todos:${state.todos.length}'),
                    Text('filter:${filter.name}'),
                    ElevatedButton(
                      onPressed: () => cubit.addTodo('y'),
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

      await tester.tap(find.text('Add'));
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('todos:1'), findsOneWidget);
      expect(find.text('filter:all'), findsOneWidget);
    });
  });
}
