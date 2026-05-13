import 'dart:async';

import 'package:flutter_permission_wizard/src/core/request_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RequestQueue', () {
    test('serializes concurrent jobs', () async {
      final queue = RequestQueue();
      final log = <String>[];
      final completer1 = Completer<int>();
      final completer2 = Completer<int>();

      final f1 = queue.enqueue(() async {
        log.add('start1');
        final v = await completer1.future;
        log.add('end1');
        return v;
      });
      final f2 = queue.enqueue(() async {
        log.add('start2');
        final v = await completer2.future;
        log.add('end2');
        return v;
      });

      // Yield to give the queue a chance to start the first job.
      await Future<void>.delayed(Duration.zero);
      expect(log, ['start1']);
      completer1.complete(1);
      expect(await f1, 1);
      await Future<void>.delayed(Duration.zero);
      expect(log, ['start1', 'end1', 'start2']);
      completer2.complete(2);
      expect(await f2, 2);
    });

    test('error in one job does not stall the queue', () async {
      final queue = RequestQueue();
      final first = queue.enqueue(() async {
        throw StateError('boom');
      });
      final second = queue.enqueue(() async => 42);
      await expectLater(first, throwsA(isA<StateError>()));
      expect(await second, 42);
    });

    test('isIdle reflects pending count', () async {
      final queue = RequestQueue();
      expect(queue.isIdle, isTrue);
      final completer = Completer<int>();
      final job = queue.enqueue(() => completer.future);
      expect(queue.isIdle, isFalse);
      completer.complete(1);
      await job;
      expect(queue.isIdle, isTrue);
    });

    test('reset drops in-flight chain', () async {
      final queue = RequestQueue();
      queue.enqueue(() async => 1); // intentionally not awaited
      queue.reset();
      expect(queue.isIdle, isTrue);
      // After reset, subsequent jobs work normally.
      final result = await queue.enqueue(() async => 99);
      expect(result, 99);
    });
  });
}
