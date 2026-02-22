import 'dart:async';

import 'package:bloc_hooks/src/utils/where_state_changed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WhereStateChanged', () {
    test('passes all events when "when" is null', () async {
      final controller = StreamController<String>();
      final transformer = WhereStateChanged<String>(
        initialState: '',
        when: null,
      );

      final results = <String>[];
      controller.stream.transform(transformer).listen(results.add);

      controller
        ..add('buy milk')
        ..add('walk dog')
        ..add('clean house');
      await Future<void>.delayed(Duration.zero);

      expect(results, ['buy milk', 'walk dog', 'clean house']);
      await controller.close();
    });

    test('filters events according to "when" predicate', () async {
      final controller = StreamController<int>();
      bool when(int prev, int curr) => curr > prev;

      final transformer = WhereStateChanged<int>(
        initialState: 0,
        when: when,
      );

      final results = <int>[];
      controller.stream.transform(transformer).listen(results.add);

      controller
        ..add(3) // 0→3 ✓
        ..add(1) // 3→1 ✗
        ..add(7) // 1→7 ✓
        ..add(5); // 7→5 ✗
      await Future<void>.delayed(Duration.zero);

      expect(results, [3, 7]);
      await controller.close();
    });

    test('tracks previous state correctly', () async {
      final controller = StreamController<int>();
      final prevLog = <int>[];

      bool when(int prev, int curr) {
        prevLog.add(prev);
        return true;
      }

      final transformer = WhereStateChanged<int>(
        initialState: 10,
        when: when,
      );

      controller.stream.transform(transformer).listen((_) {});

      controller
        ..add(20)
        ..add(30)
        ..add(40);
      await Future<void>.delayed(Duration.zero);

      expect(prevLog, [10, 20, 30]);
      await controller.close();
    });

    test('uses initialState as first "previous"', () async {
      final controller = StreamController<String>();
      String? firstPrev;

      bool when(String prev, String curr) {
        firstPrev ??= prev;
        return true;
      }

      final transformer = WhereStateChanged<String>(
        initialState: 'initial-task',
        when: when,
      );

      controller.stream.transform(transformer).listen((_) {});

      controller.add('new-task');
      await Future<void>.delayed(Duration.zero);

      expect(firstPrev, 'initial-task');
      await controller.close();
    });
  });
}
