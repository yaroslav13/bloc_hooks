import 'package:bloc_hooks/bloc_hooks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/cubits/todo_cubit.dart';
import 'utils/widgets/test_app.dart';
import 'utils/widgets/todo_binder.dart';

void main() {
  group('useBlocListen', () {
    testWidgets('listener is called on every state change', (tester) async {
      final states = <TodoState>[];

      await tester.pumpWidget(
        TestApp(
          child: TodoBinder(
            child: HookBuilder(
              builder: (_) {
                final cubit = useBloc<TodoCubit>();
                useBlocListen<TodoState>((state, _) => states.add(state));

                return ElevatedButton(
                  onPressed: () => cubit.addTodo('milk'),
                  child: const Text('Add'),
                );
              },
            ),
          ),
        ),
      );

      expect(states, isEmpty);

      await tester.tap(find.text('Add'));
      await tester.pump();
      expect(states.length, 1);
      expect(states.first.todos.length, 1);

      await tester.tap(find.text('Add'));
      await tester.pump();
      expect(states.length, 2);
      expect(states.last.todos.length, 2);
    });

    testWidgets('does NOT trigger a widget rebuild', (tester) async {
      var buildCount = 0;

      await tester.pumpWidget(
        TestApp(
          child: TodoBinder(
            child: HookBuilder(
              builder: (_) {
                final cubit = useBloc<TodoCubit>();
                useBlocListen<TodoState>((_, __) {});
                buildCount++;

                return ElevatedButton(
                  onPressed: () => cubit.addTodo('eggs'),
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
      expect(buildCount, 1);
    });

    testWidgets('respects "when" predicate', (tester) async {
      final heard = <TodoState>[];

      await tester.pumpWidget(
        TestApp(
          child: TodoBinder(
            child: HookBuilder(
              builder: (_) {
                final cubit = useBloc<TodoCubit>();
                useBlocListen<TodoState>(
                  (state, _) => heard.add(state),
                  // Only fire when filter changes.
                  when: (prev, curr) => prev.filter != curr.filter,
                );

                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => cubit.addTodo('x'),
                      child: const Text('Add'),
                    ),
                    ElevatedButton(
                      onPressed: () => cubit.setFilter(TodoFilter.active),
                      child: const Text('Filter'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Adding a todo → filter unchanged → listener silent
      await tester.tap(find.text('Add'));
      await tester.pump();
      expect(heard, isEmpty);

      // Changing filter → listener fires
      await tester.tap(find.text('Filter'));
      await tester.pump();
      expect(heard.length, 1);
      expect(heard.first.filter, TodoFilter.active);
    });

    testWidgets('listener receives a valid BuildContext', (tester) async {
      BuildContext? received;

      await tester.pumpWidget(
        TestApp(
          child: TodoBinder(
            child: HookBuilder(
              builder: (_) {
                final cubit = useBloc<TodoCubit>();
                useBlocListen<TodoState>(
                  (_, ctx) => received = ctx,
                );

                return ElevatedButton(
                  onPressed: () => cubit.addTodo('z'),
                  child: const Text('Add'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Add'));
      await tester.pump();

      expect(received, isNotNull);
    });
  });
}
