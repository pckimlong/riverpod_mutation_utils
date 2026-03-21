import 'dart:async';

import 'package:riverpod/riverpod.dart';
import 'package:riverpod_mutation_utils/riverpod_mutation_utils.dart';
import 'package:test/test.dart';

final _refProvider = Provider<Ref>((ref) => ref);
final _counterProvider = NotifierProvider<_CounterNotifier, int>(
  _CounterNotifier.new,
);
final _eventLogProvider = NotifierProvider<_EventLogNotifier, List<String>>(
  _EventLogNotifier.new,
);
final _asyncDependencyProvider = FutureProvider.autoDispose<int>((ref) async {
  return 1;
});
final _voidActionMutation = Mutation<int>();
var _autoDisposeSubmitterDisposeCount = 0;
final _autoDisposeSubmitterProvider =
    NotifierProvider.autoDispose<_AutoDisposeSubmitter, int>(
      _AutoDisposeSubmitter.new,
    );
final _voidActionSubmitterProvider =
    NotifierProvider.autoDispose<_VoidActionSubmitter, void>(
      _VoidActionSubmitter.new,
    );
final _sharedFamilySubmitterProvider =
    NotifierProvider.family<_SharedFamilySubmitter, int, String>(
      _SharedFamilySubmitter.new,
    );
final _keyedFamilySubmitterProvider =
    NotifierProvider.family<_KeyedFamilySubmitter, int, String>(
      _KeyedFamilySubmitter.new,
    );
final _asyncInvalidateSubmitterProvider =
    AsyncNotifierProvider.autoDispose<_AsyncInvalidateSubmitter, int>(
      _AsyncInvalidateSubmitter.new,
    );

class _CounterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void incrementBy(int value) {
    state += value;
  }
}

class _EventLogNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => <String>[];

  void add(String value) {
    state = [...state, value];
  }
}

class _AutoDisposeSubmitter extends Notifier<int> {
  static final mutation = Mutation<int>();
  final _runner = MutationRunner<int>();

  @override
  int build() {
    ref.onDispose(() {
      _autoDisposeSubmitterDisposeCount++;
    });
    return 0;
  }

  Future<int> submitWithProviderSideEffect(Completer<int> completer) {
    return _runner.submitAction(
      ref,
      mutation,
      (tx) => completer.future,
      afterSuccess: (result) {
        ref.read(_counterProvider.notifier).incrementBy(result);
      },
    );
  }

  Future<int> submitWithProviderErrorSideEffect(Completer<int> completer) {
    return _runner.submitAction(
      ref,
      mutation,
      (tx) => completer.future,
      afterError: (error, stackTrace) {
        ref.read(_eventLogProvider.notifier).add('error:$error');
      },
    );
  }
}

class _VoidActionSubmitter extends Notifier<void>
    with MutationActionMixin<int> {
  @override
  Mutation<int> get mutation => _voidActionMutation;

  @override
  void build() {
    ref.onDispose(() {
      _autoDisposeSubmitterDisposeCount++;
    });
  }

  Future<int> submitWithProviderSideEffect(Completer<int> completer) {
    return submitAction(
      (tx) => completer.future,
      afterSuccess: (result) {
        ref.read(_counterProvider.notifier).incrementBy(result);
      },
    );
  }
}

class _SharedFamilySubmitter extends Notifier<int> {
  _SharedFamilySubmitter(this.id);

  final String id;
  static final mutation = Mutation<int>();
  final _runner = MutationRunner<int>();

  @override
  int build() => 0;

  Future<int> submit(Completer<int> completer) {
    return _runner.submitAction(ref, mutation, (tx) => completer.future);
  }
}

class _KeyedFamilySubmitter extends Notifier<int> {
  _KeyedFamilySubmitter(this.id);

  final String id;
  static final mutation = Mutation<int>();
  final _runner = MutationRunner<int>();

  Mutation<int> get keyedMutation => mutation(id);

  @override
  int build() => 0;

  Future<int> submit(Completer<int> completer) {
    return _runner.submitAction(ref, keyedMutation, (tx) => completer.future);
  }
}

class _AsyncInvalidateSubmitter extends AsyncNotifier<int> {
  static final mutation = Mutation<int>();
  final _runner = MutationRunner<int>();

  @override
  Future<int> build() async {
    return ref.watch(_asyncDependencyProvider.future);
  }

  Future<int> submitAndInvalidateDependency() {
    return _runner.submitAction(
      ref,
      mutation,
      (tx) async => 5,
      afterSuccess: (_) {
        ref.invalidate(_asyncDependencyProvider);
      },
    );
  }
}

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
        afterSuccess: (result) {
          successCount++;
        },
      );

      final second = runner.submitAction(ref, mutation, (tx) async {
        runCount++;
        return -1;
      });

      expect(runCount, 1);

      completer.complete(42);

      expect(await first, 42);
      expect(await second, 42);
      expect(runCount, 1);
      expect(successCount, 1);
    });

    test('afterSuccess runs after completion and can use outer ref', () async {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final ref = container.read(_refProvider);
      final mutation = Mutation<int>();
      final runner = MutationRunner<int>();

      final result = await runner.submitAction(
        ref,
        mutation,
        (tx) async => 7,
        afterSuccess: (value) {
          ref.read(_counterProvider.notifier).incrementBy(value);
        },
      );

      expect(result, 7);
      expect(container.read(_counterProvider), 7);
    });

    test('afterError runs after failure and can use outer ref', () async {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final ref = container.read(_refProvider);
      final mutation = Mutation<int>();
      final runner = MutationRunner<int>();

      await expectLater(
        runner.submitAction(
          ref,
          mutation,
          (tx) async => throw StateError('boom'),
          afterError: (error, stackTrace) {
            ref.read(_eventLogProvider.notifier).add('error:$error');
          },
        ),
        throwsA(isA<StateError>()),
      );

      expect(container.read(_eventLogProvider), ['error:Bad state: boom']);
    });

    test('does not call success callback when the mutation fails', () async {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final ref = container.read(_refProvider);
      final mutation = Mutation<int>();
      final runner = MutationRunner<int>();
      var afterSuccessCalled = false;
      var afterErrorCalled = false;

      await expectLater(
        runner.submitAction(
          ref,
          mutation,
          (tx) async => throw StateError('boom'),
          afterSuccess: (_) {
            afterSuccessCalled = true;
          },
          afterError: (error, stackTrace) {
            afterErrorCalled = true;
          },
        ),
        throwsA(isA<StateError>()),
      );

      expect(afterSuccessCalled, isFalse);
      expect(afterErrorCalled, isTrue);
    });

    test('does not call error callback when the mutation succeeds', () async {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final ref = container.read(_refProvider);
      final mutation = Mutation<int>();
      final runner = MutationRunner<int>();
      var afterSuccessCalled = false;
      var afterErrorCalled = false;

      final result = await runner.submitAction(
        ref,
        mutation,
        (tx) async => 21,
        afterSuccess: (_) {
          afterSuccessCalled = true;
        },
        afterError: (error, stackTrace) {
          afterErrorCalled = true;
        },
      );

      expect(result, 21);
      expect(afterSuccessCalled, isTrue);
      expect(afterErrorCalled, isFalse);
    });

    test('awaits async success and error callbacks', () async {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final ref = container.read(_refProvider);
      final mutation = Mutation<int>();
      final runner = MutationRunner<int>();
      var successFinished = false;
      var errorFinished = false;

      final successResult = await runner.submitAction(
        ref,
        mutation,
        (tx) async => 3,
        afterSuccess: (_) async {
          await Future<void>.delayed(Duration.zero);
          successFinished = true;
        },
      );

      expect(successResult, 3);
      expect(successFinished, isTrue);

      await expectLater(
        runner.submitAction(
          ref,
          mutation,
          (tx) async => throw StateError('boom'),
          afterError: (error, stackTrace) async {
            await Future<void>.delayed(Duration.zero);
            errorFinished = true;
          },
        ),
        throwsA(isA<StateError>()),
      );

      expect(errorFinished, isTrue);
    });

    test(
      'keeps an auto-dispose submitter alive until completion so afterSuccess can use ref',
      () async {
        final container = ProviderContainer.test();
        addTearDown(container.dispose);
        _autoDisposeSubmitterDisposeCount = 0;

        final completer = Completer<int>();
        final future = container
            .read(_autoDisposeSubmitterProvider.notifier)
            .submitWithProviderSideEffect(completer);

        await container.pump();
        expect(_autoDisposeSubmitterDisposeCount, 0);

        completer.complete(5);
        expect(await future, 5);
        expect(container.read(_counterProvider), 5);

        await container.pump();
        expect(_autoDisposeSubmitterDisposeCount, 1);
      },
    );

    test(
      'keeps an auto-dispose submitter alive until failure so afterError can use ref',
      () async {
        final container = ProviderContainer.test();
        addTearDown(container.dispose);
        _autoDisposeSubmitterDisposeCount = 0;

        final completer = Completer<int>();
        final future = container
            .read(_autoDisposeSubmitterProvider.notifier)
            .submitWithProviderErrorSideEffect(completer);

        await container.pump();
        expect(_autoDisposeSubmitterDisposeCount, 0);

        completer.completeError(StateError('boom'));
        await expectLater(future, throwsA(isA<StateError>()));
        expect(container.read(_eventLogProvider), ['error:Bad state: boom']);

        await container.pump();
        expect(_autoDisposeSubmitterDisposeCount, 1);
      },
    );

    test(
      'skips afterSuccess if the submitting ref becomes unmounted',
      () async {
        final container = ProviderContainer.test();
        addTearDown(container.dispose);
        _autoDisposeSubmitterDisposeCount = 0;

        final completer = Completer<int>();
        final future = container
            .read(_autoDisposeSubmitterProvider.notifier)
            .submitWithProviderSideEffect(completer);

        container.invalidate(_autoDisposeSubmitterProvider);
        await container.pump();

        completer.complete(9);
        expect(await future, 9);
        expect(container.read(_counterProvider), 0);
      },
    );

    test('skips afterError if the submitting ref becomes unmounted', () async {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);
      _autoDisposeSubmitterDisposeCount = 0;

      final completer = Completer<int>();
      final future = container
          .read(_autoDisposeSubmitterProvider.notifier)
          .submitWithProviderErrorSideEffect(completer);

      container.invalidate(_autoDisposeSubmitterProvider);
      await container.pump();

      completer.completeError(StateError('boom'));
      await expectLater(future, throwsA(isA<StateError>()));
      expect(container.read(_eventLogProvider), isEmpty);
    });

    test('MutationActionMixin works with action-only void notifiers', () async {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);
      _autoDisposeSubmitterDisposeCount = 0;

      final mutationSub = container.listen(
        _voidActionMutation,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(mutationSub.close);

      final completer = Completer<int>();
      final future = container
          .read(_voidActionSubmitterProvider.notifier)
          .submitWithProviderSideEffect(completer);

      await container.pump();
      expect(_autoDisposeSubmitterDisposeCount, 0);
      expect(mutationSub.read(), isA<MutationPending<int>>());

      completer.complete(11);
      expect(await future, 11);
      expect(container.read(_counterProvider), 11);
      expect(mutationSub.read(), isA<MutationSuccess<int>>());
      expect((mutationSub.read() as MutationSuccess<int>).value, 11);

      await container.pump();
      expect(_autoDisposeSubmitterDisposeCount, 1);
      expect(mutationSub.read(), isA<MutationSuccess<int>>());
      expect((mutationSub.read() as MutationSuccess<int>).value, 11);
    });

    test('allows a new submit after a failed submit', () async {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final ref = container.read(_refProvider);
      final mutation = Mutation<int>();
      final runner = MutationRunner<int>();

      await expectLater(
        runner.submitAction(
          ref,
          mutation,
          (tx) async => throw StateError('boom'),
        ),
        throwsA(isA<StateError>()),
      );

      final result = await runner.submitAction(ref, mutation, (tx) async => 8);
      expect(result, 8);
    });

    test('allows a new submit after afterSuccess throws', () async {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final ref = container.read(_refProvider);
      final mutation = Mutation<int>();
      final runner = MutationRunner<int>();
      Object? capturedError;

      await expectLater(
        runner.submitAction(
          ref,
          mutation,
          (tx) async => 4,
          afterSuccess: (_) {
            throw StateError('after success failed');
          },
          afterError: (error, stackTrace) {
            capturedError = error;
          },
        ),
        throwsA(isA<StateError>()),
      );

      expect(capturedError, isA<StateError>());
      expect((capturedError as StateError).message, 'after success failed');

      final result = await runner.submitAction(ref, mutation, (tx) async => 6);
      expect(result, 6);
    });

    test('allows a new submit after afterError throws', () async {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final ref = container.read(_refProvider);
      final mutation = Mutation<int>();
      final runner = MutationRunner<int>();

      await expectLater(
        runner.submitAction(
          ref,
          mutation,
          (tx) async => throw StateError('boom'),
          afterError: (error, stackTrace) {
            throw ArgumentError('after error failed');
          },
        ),
        throwsA(isA<ArgumentError>()),
      );

      final result = await runner.submitAction(ref, mutation, (tx) async => 10);
      expect(result, 10);
    });

    test('coalesced callers share the same failure', () async {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final ref = container.read(_refProvider);
      final mutation = Mutation<int>();
      final runner = MutationRunner<int>();
      final completer = Completer<int>();

      final first = runner.submitAction(
        ref,
        mutation,
        (tx) => completer.future,
      );
      final second = runner.submitAction(ref, mutation, (tx) async => 99);

      completer.completeError(StateError('boom'));

      await expectLater(first, throwsA(isA<StateError>()));
      await expectLater(second, throwsA(isA<StateError>()));
    });

    test('resets the mutation when the owning provider is disposed', () async {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final notifier = container.read(_autoDisposeSubmitterProvider.notifier);
      final mutationSub = container.listen(
        _AutoDisposeSubmitter.mutation,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(mutationSub.close);

      final completer = Completer<int>()..complete(12);
      final result = await notifier.submitWithProviderSideEffect(completer);
      expect(result, 12);
      expect(mutationSub.read(), isA<MutationSuccess<int>>());

      container.invalidate(_autoDisposeSubmitterProvider);
      await container.pump();
      await Future<void>.delayed(Duration.zero);
      await container.pump();

      expect(mutationSub.read(), isA<MutationIdle<int>>());
    });

    test(
      'MutationActionMixin does not reset the mutation when the owner is disposed',
      () async {
        final container = ProviderContainer.test();
        addTearDown(container.dispose);

        final mutationSub = container.listen(
          _voidActionMutation,
          (_, _) {},
          fireImmediately: true,
        );
        addTearDown(mutationSub.close);

        final completer = Completer<int>()..complete(13);
        final result = await container
            .read(_voidActionSubmitterProvider.notifier)
            .submitWithProviderSideEffect(completer);

        expect(result, 13);
        expect(mutationSub.read(), isA<MutationSuccess<int>>());

        await container.pump();

        expect(mutationSub.read(), isA<MutationSuccess<int>>());
        expect((mutationSub.read() as MutationSuccess<int>).value, 13);
      },
    );

    test(
      'action mutations can be reset manually after owner disposal',
      () async {
        final container = ProviderContainer.test();
        addTearDown(container.dispose);

        final mutationSub = container.listen(
          _voidActionMutation,
          (_, _) {},
          fireImmediately: true,
        );
        addTearDown(mutationSub.close);

        final completer = Completer<int>()..complete(14);
        final result = await container
            .read(_voidActionSubmitterProvider.notifier)
            .submitWithProviderSideEffect(completer);

        expect(result, 14);
        expect(mutationSub.read(), isA<MutationSuccess<int>>());

        await container.pump();
        _voidActionMutation.reset(container);

        expect(mutationSub.read(), isA<MutationIdle<int>>());
      },
    );

    test(
      'afterSuccess invalidation of a watched dependency does not throw and resets to idle',
      () async {
        final container = ProviderContainer.test();
        addTearDown(container.dispose);

        final providerSub = container.listen(
          _asyncInvalidateSubmitterProvider,
          (_, _) {},
          fireImmediately: true,
        );
        final mutationSub = container.listen(
          _AsyncInvalidateSubmitter.mutation,
          (_, _) {},
          fireImmediately: true,
        );
        addTearDown(providerSub.close);
        addTearDown(mutationSub.close);

        expect(
          await container.read(_asyncInvalidateSubmitterProvider.future),
          1,
        );
        expect(mutationSub.read(), isA<MutationIdle<int>>());

        final result = await container
            .read(_asyncInvalidateSubmitterProvider.notifier)
            .submitAndInvalidateDependency();

        expect(result, 5);
        expect(mutationSub.read(), isA<MutationSuccess<int>>());

        await container.pump();
        await Future<void>.delayed(Duration.zero);
        await container.pump();

        expect(mutationSub.read(), isA<MutationIdle<int>>());
        expect(
          await container.read(_asyncInvalidateSubmitterProvider.future),
          1,
        );
      },
    );

    test(
      'family providers that reuse one mutation share pending and success state',
      () async {
        final container = ProviderContainer.test();
        addTearDown(container.dispose);
        final aEvents = <MutationState<int>>[];
        final bEvents = <MutationState<int>>[];

        final aSub = container.listen(_SharedFamilySubmitter.mutation, (
          previous,
          next,
        ) {
          aEvents.add(next);
        }, fireImmediately: true);
        final bSub = container.listen(_SharedFamilySubmitter.mutation, (
          previous,
          next,
        ) {
          bEvents.add(next);
        }, fireImmediately: true);
        addTearDown(aSub.close);
        addTearDown(bSub.close);

        final completer = Completer<int>();
        final future = container
            .read(_sharedFamilySubmitterProvider('a').notifier)
            .submit(completer);

        expect(aSub.read(), isA<MutationPending<int>>());
        expect(bSub.read(), isA<MutationPending<int>>());

        completer.complete(1);
        expect(await future, 1);
        expect(aSub.read(), isA<MutationSuccess<int>>());
        expect(bSub.read(), isA<MutationSuccess<int>>());
        expect((aSub.read() as MutationSuccess<int>).value, 1);
        expect((bSub.read() as MutationSuccess<int>).value, 1);
        expect(aEvents.last, bEvents.last);
      },
    );

    test(
      'keyed family mutations isolate pending and success state per family argument',
      () async {
        final container = ProviderContainer.test();
        addTearDown(container.dispose);

        final aMutation = _KeyedFamilySubmitter.mutation('a');
        final bMutation = _KeyedFamilySubmitter.mutation('b');
        final aSub = container.listen(
          aMutation,
          (previous, next) {},
          fireImmediately: true,
        );
        final bSub = container.listen(
          bMutation,
          (previous, next) {},
          fireImmediately: true,
        );
        addTearDown(aSub.close);
        addTearDown(bSub.close);

        final aCompleter = Completer<int>();
        final aFuture = container
            .read(_keyedFamilySubmitterProvider('a').notifier)
            .submit(aCompleter);

        expect(aSub.read(), isA<MutationPending<int>>());
        expect(bSub.read(), isA<MutationIdle<int>>());

        aCompleter.complete(10);
        expect(await aFuture, 10);
        expect(aSub.read(), isA<MutationSuccess<int>>());
        expect((aSub.read() as MutationSuccess<int>).value, 10);
        expect(bSub.read(), isA<MutationIdle<int>>());

        final bCompleter = Completer<int>();
        final bFuture = container
            .read(_keyedFamilySubmitterProvider('b').notifier)
            .submit(bCompleter);

        expect(aSub.read(), isA<MutationSuccess<int>>());
        expect((aSub.read() as MutationSuccess<int>).value, 10);
        expect(bSub.read(), isA<MutationPending<int>>());

        bCompleter.complete(20);
        expect(await bFuture, 20);
        expect(aSub.read(), isA<MutationSuccess<int>>());
        expect((aSub.read() as MutationSuccess<int>).value, 10);
        expect(bSub.read(), isA<MutationSuccess<int>>());
        expect((bSub.read() as MutationSuccess<int>).value, 20);
      },
    );

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
      expect(events, contains('MutationIdle<int>->MutationPending<int>'));
      expect(events, contains('MutationPending<int>->MutationSuccess<int>'));
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
