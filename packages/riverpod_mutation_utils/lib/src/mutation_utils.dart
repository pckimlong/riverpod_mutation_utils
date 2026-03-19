import 'dart:async';

import 'package:riverpod/experimental/mutation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

class GenerateMutation {
  const GenerateMutation();
}

const generateMutation = GenerateMutation();

typedef MutationChangedCallback<Result> =
    void Function(MutationState<Result>? previous, MutationState<Result> next);

typedef MutationSuccessCallback<Result> =
    void Function(MutationState<Result>? previous, Result result);

void _listenMutationImpl<Result>(
  Ref ref,
  Mutation<Result> mutation, {
  MutationChangedCallback<Result>? onChanged,
  MutationSuccessCallback<Result>? onSuccess,
  void Function(
    MutationState<Result>? previous,
    Object error,
    StackTrace? stackTrace,
  )?
  onError,
}) {
  ref.listen<MutationState<Result>>(mutation, (previous, next) {
    onChanged?.call(previous, next);
    if (next case MutationSuccess(:final value)) {
      onSuccess?.call(previous, value);
    } else if (next case MutationError(:final error, :final stackTrace)) {
      onError?.call(previous, error, stackTrace);
    }
  });
}

void _resetMutationSafely<Result>(
  Mutation<Result> mutation,
  MutationTarget target,
) {
  try {
    mutation.reset(target);
  } on StateError catch (error) {
    final message = error.message.toString();
    if (!message.contains('already disposed')) rethrow;
  }
}

/// Low-level helper for executing and observing Riverpod experimental
/// [Mutation]s from provider code.
///
/// This runner is intentionally small:
/// - ensures mutation state is reset on provider disposal
/// - coalesces concurrent submissions into the same in-flight [Future]
/// - forwards mutation success/error events via [listenMutation]
class MutationRunner<Result> {
  Future<Result>? _inFlight;
  final _registeredMutationDisposals = <Object>{};

  void ensureMutationResetOnDispose(Ref ref, Mutation<Result> mutation) {
    if (_registeredMutationDisposals.add(mutation)) {
      final container = ref.container;
      ref.onDispose(() {
        _resetMutationSafely(mutation, container);
      });
    }
  }

  void listenMutation(
    Ref ref,
    Mutation<Result> mutation, {
    MutationChangedCallback<Result>? onChanged,
    MutationSuccessCallback<Result>? onSuccess,
    void Function(
      MutationState<Result>? previous,
      Object error,
      StackTrace? stackTrace,
    )?
    onError,
  }) {
    ensureMutationResetOnDispose(ref, mutation);
    _listenMutationImpl(
      ref,
      mutation,
      onChanged: onChanged,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  Future<Result> submitAction(
    Ref ref,
    Mutation<Result> mutation,
    Future<Result> Function(MutationTransaction tx) run, {
    // Runs after the mutation transaction has completed and closed.
    // This callback is skipped if the submitting provider was unmounted
    // before completion. The runner keeps the provider alive while pending to
    // avoid plain auto-dispose, but explicit invalidation/rebuilds can still
    // unmount the original ref.
    FutureOr<void> Function(Result result)? afterSuccess,
    FutureOr<void> Function(Object error, StackTrace stackTrace)? afterError,
  }) async {
    ensureMutationResetOnDispose(ref, mutation);
    if (_inFlight != null) return _inFlight!;

    final keepAliveLink = ref.keepAlive();
    final future = mutation.run(ref, run);
    _inFlight = future;

    try {
      final result = await future;
      if (ref.mounted) {
        await afterSuccess?.call(result);
      }
      return result;
    } catch (error, stackTrace) {
      if (ref.mounted) {
        await afterError?.call(error, stackTrace);
      }
      rethrow;
    } finally {
      keepAliveLink.close();
      _inFlight = null;
    }
  }
}

/// Shared helper for provider forms backed by sync build state.
mixin StateFormMixin<FormState, Result> on $Notifier<FormState> {
  final _runner = MutationRunner<Result>();

  FormState get _formState => state;
  Mutation<Result> get mutation;

  void listenMutation({
    MutationChangedCallback<Result>? onChanged,
    MutationSuccessCallback<Result>? onSuccess,
    void Function(
      MutationState<Result>? previous,
      Object error,
      StackTrace? stackTrace,
    )?
    onError,
  }) {
    _runner.listenMutation(
      ref,
      mutation,
      onChanged: onChanged,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  Future<Result> submit(
    Future<Result> Function(MutationTransaction tx, FormState form) run, {
    FutureOr<void> Function(Result result)? afterSuccess,
    FutureOr<void> Function(Object error, StackTrace stackTrace)? afterError,
  }) {
    return _runner.submitAction(
      ref,
      mutation,
      (tx) => run(tx, _formState),
      afterSuccess: afterSuccess,
      afterError: afterError,
    );
  }
}

/// Shared helper for provider forms backed by async build state.
mixin AsyncStateFormMixin<FormState, Result> on $AsyncNotifier<FormState> {
  final _runner = MutationRunner<Result>();

  Mutation<Result> get mutation;

  FormState get _formState {
    if (!state.hasValue) {
      throw StateError(
        'Cannot call submit() before the async notifier has finished building. '
        'Await the provider future first.',
      );
    }

    return state.requireValue;
  }

  void listenMutation({
    MutationChangedCallback<Result>? onChanged,
    MutationSuccessCallback<Result>? onSuccess,
    void Function(
      MutationState<Result>? previous,
      Object error,
      StackTrace? stackTrace,
    )?
    onError,
  }) {
    _runner.listenMutation(
      ref,
      mutation,
      onChanged: onChanged,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  Future<Result> submit(
    Future<Result> Function(MutationTransaction tx, FormState form) run, {
    FutureOr<void> Function(Result result)? afterSuccess,
    FutureOr<void> Function(Object error, StackTrace stackTrace)? afterError,
  }) {
    return _runner.submitAction(
      ref,
      mutation,
      (tx) => run(tx, _formState),
      afterSuccess: afterSuccess,
      afterError: afterError,
    );
  }
}

/// Shared helper for action-only providers with no own state.
///
/// Providers using this mixin should return `void` from `build()` and expose
/// mutation progress by watching the separate [mutation] accessor.
///
/// Non-family notifiers can omit an empty `build()` override because this
/// mixin provides a default no-op implementation. Family notifiers still need
/// to declare `build(...)` so Riverpod can expose their parameters.
mixin MutationActionMixin<Result> on $Notifier<void> {
  final _runner = MutationRunner<Result>();

  Mutation<Result> get mutation;

  void build() {}

  Future<Result> submitAction(
    Future<Result> Function(MutationTransaction tx) run, {
    FutureOr<void> Function(Result result)? afterSuccess,
    FutureOr<void> Function(Object error, StackTrace stackTrace)? afterError,
  }) {
    return _runner.submitAction(
      ref,
      mutation,
      run,
      afterSuccess: afterSuccess,
      afterError: afterError,
    );
  }
}
