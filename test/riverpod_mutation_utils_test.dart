import 'dart:async';

import 'package:riverpod/experimental/mutation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_mutation_utils/riverpod_mutation_utils.dart';
import 'package:test/test.dart';

final _refProvider = Provider<Ref>((ref) => ref);

void main() {
  group('MutationRunner', () {
    test('coalesces concurrent submits into one execution', () async {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final ref = container.read(_refProvider);
      final mutation = Mutation<int>();
      final runner = MutationRunner<int>();
      final completer = Completer<int>();

      var runCount = 0;
      var successCount = 0;

      final first = runner.submitAction(
        ref,
        mutation,
        (tx) async {
          runCount++;
          return completer.future;
        },
        afterSuccess: (_, result) {
          successCount++;
        },
      );

      final second = runner.submitAction(
        ref,
        mutation,
        (tx) async {
          runCount++;
          return -1;
        },
      );

      expect(runCount, 1);

      completer.complete(42);

      expect(await first, 42);
      expect(await second, 42);
      expect(runCount, 1);
      expect(successCount, 1);
    });

    test('forwards mutation success notifications', () async {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final ref = container.read(_refProvider);
      final mutation = Mutation<int>();
      final runner = MutationRunner<int>();

      final events = <String>[];

      runner.listenMutation(
        ref,
        mutation,
        onChanged: (previous, next) {
          events.add('${previous.runtimeType}->${next.runtimeType}');
        },
        onSuccess: (previous, result) {
          events.add('success:$result');
        },
      );

      final result = await mutation.run(container, (_) async => 7);

      expect(result, 7);
      expect(events, contains('success:7'));
      expect(
        events,
        contains('MutationIdle<int>->MutationPending<int>'),
      );
      expect(
        events,
        contains('MutationPending<int>->MutationSuccess<int>'),
      );
    });

    test('forwards mutation error notifications', () async {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final ref = container.read(_refProvider);
      final mutation = Mutation<int>();
      final runner = MutationRunner<int>();

      Object? capturedError;

      runner.listenMutation(
        ref,
        mutation,
        onError: (previous, error, stackTrace) {
          capturedError = error;
        },
      );

      await expectLater(
        mutation.run(container, (_) async => throw StateError('boom')),
        throwsA(isA<StateError>()),
      );

      expect(capturedError, isA<StateError>());
      expect((capturedError as StateError).message, 'boom');
    });
  });
}
