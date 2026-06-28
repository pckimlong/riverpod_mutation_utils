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

/// Controls who owns resetting a mutation back to idle.
enum MutationResetPolicy {
  /// Reset when the provider that submitted/listens to the mutation is disposed.
  onOwnerDispose,

  /// Never reset automatically. Call `mutation.reset(...)` explicitly.
  manual,
}

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

void _scheduleMutationReset<Result>(
  Mutation<Result> mutation,
  MutationTarget target,
) {
  Future.microtask(() {
    _resetMutationSafely(mutation, target);
  });
}

/// Low-level helper for executing and observing Riverpod experimental
/// [Mutation]s from provider code.
///
/// This runner is intentionally small:
/// - optionally resets mutation state on provider disposal
/// - coalesces concurrent submissions into the same in-flight [Future]
/// - forwards mutation success/error events via [listenMutation]
class MutationRunner<Result> {
  MutationRunner({this.resetPolicy = MutationResetPolicy.onOwnerDispose});

  final MutationResetPolicy resetPolicy;
  Future<Result>? _inFlight;
  final _registeredMutationDisposals = <Object>{};

  void ensureMutationResetOnDispose(Ref ref, Mutation<Result> mutation) {
    if (resetPolicy != MutationResetPolicy.onOwnerDispose) return;

    if (_registeredMutationDisposals.add(mutation)) {
      final container = ref.container;
      ref.onDispose(() {
        _scheduleMutationReset(mutation, container);
      });
    }
  }

  void reset(Ref ref, Mutation<Result> mutation) {
    _resetMutationSafely(mutation, ref.container);
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
    bool ignoreIfSuccess = false,
    // Runs after the mutation transaction has completed and closed.
    // This callback is skipped if the submitting provider was unmounted
    // before completion. The runner keeps the provider alive while pending to
    // avoid plain auto-dispose, but explicit invalidation/rebuilds can still
    // unmount the original ref.
    FutureOr<void> Function(Result result)? afterSuccess,
    FutureOr<void> Function(Object error, StackTrace stackTrace)? afterError,
  }) async {
    ensureMutationResetOnDispose(ref, mutation);
    if (ignoreIfSuccess) {
      final currentState = ref.container.read(mutation);
      if (currentState is MutationSuccess<Result>) {
        return currentState.value;
      }
    }
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

  /// Runs [run] like [submitAction], but returns the resulting mutation state.
  ///
  /// Use [submitAction] when the caller expects normal async function
  /// semantics: successful submissions return [Result], and failed submissions
  /// throw.
  ///
  /// Use [submitActionState] when mutation state is the caller's error/success
  /// channel, such as form UIs that render [MutationError] and do not need a
  /// thrown exception. This method still runs [afterSuccess] and [afterError],
  /// but it does not rethrow failures from the action or those callbacks.
  Future<MutationState<Result>> submitActionState(
    Ref ref,
    Mutation<Result> mutation,
    Future<Result> Function(MutationTransaction tx) run, {
    bool ignoreIfSuccess = false,
    FutureOr<void> Function(Result result)? afterSuccess,
    FutureOr<void> Function(Object error, StackTrace stackTrace)? afterError,
  }) async {
    if (ignoreIfSuccess && ref.container.read(mutation) is MutationSuccess<Result>) {
      return ref.container.read(mutation);
    }
    try {
      await submitAction(
        ref,
        mutation,
        run,
        ignoreIfSuccess: ignoreIfSuccess,
        afterSuccess: afterSuccess,
        afterError: afterError,
      );
    } catch (_) {}
    return ref.container.read(mutation);
  }

  /// Runs [run] like [submitAction], but if it has already succeeded, returns 
  /// the cached success value directly without re-executing.
  Future<Result> submitActionOnce(
    Ref ref,
    Mutation<Result> mutation,
    Future<Result> Function(MutationTransaction tx) run, {
    FutureOr<void> Function(Result result)? afterSuccess,
    FutureOr<void> Function(Object error, StackTrace stackTrace)? afterError,
  }) {
    return submitAction(
      ref,
      mutation,
      run,
      ignoreIfSuccess: true,
      afterSuccess: afterSuccess,
      afterError: afterError,
    );
  }

  /// Runs [run] like [submitActionState], but if it has already succeeded, returns 
  /// the cached success state directly without re-executing.
  Future<MutationState<Result>> submitActionStateOnce(
    Ref ref,
    Mutation<Result> mutation,
    Future<Result> Function(MutationTransaction tx) run, {
    FutureOr<void> Function(Result result)? afterSuccess,
    FutureOr<void> Function(Object error, StackTrace stackTrace)? afterError,
  }) {
    return submitActionState(
      ref,
      mutation,
      run,
      ignoreIfSuccess: true,
      afterSuccess: afterSuccess,
      afterError: afterError,
    );
  }
}

/// Shared helper for provider forms backed by sync build state.
mixin StateFormMixin<FormState, Result> on $Notifier<FormState> {
  final _runner = MutationRunner<Result>(
    resetPolicy: MutationResetPolicy.onOwnerDispose,
  );

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
    bool ignoreIfSuccess = false,
    FutureOr<void> Function(Result result)? afterSuccess,
    FutureOr<void> Function(Object error, StackTrace stackTrace)? afterError,
  }) {
    return _runner.submitAction(
      ref,
      mutation,
      (tx) => run(tx, _formState),
      ignoreIfSuccess: ignoreIfSuccess,
      afterSuccess: afterSuccess,
      afterError: afterError,
    );
  }

  /// Runs [run] like [submit], but returns [mutation]'s resulting state instead
  /// of throwing on failure.
  Future<MutationState<Result>> submitState(
    Future<Result> Function(MutationTransaction tx, FormState form) run, {
    bool ignoreIfSuccess = false,
    FutureOr<void> Function(Result result)? afterSuccess,
    FutureOr<void> Function(Object error, StackTrace stackTrace)? afterError,
  }) {
    return _runner.submitActionState(
      ref,
      mutation,
      (tx) => run(tx, _formState),
      ignoreIfSuccess: ignoreIfSuccess,
      afterSuccess: afterSuccess,
      afterError: afterError,
    );
  }

  /// Runs [run] like [submit], but if it has already succeeded, returns 
  /// the cached success value directly without re-executing.
  Future<Result> submitOnce(
    Future<Result> Function(MutationTransaction tx, FormState form) run, {
    FutureOr<void> Function(Result result)? afterSuccess,
    FutureOr<void> Function(Object error, StackTrace stackTrace)? afterError,
  }) {
    return submit(
      run,
      ignoreIfSuccess: true,
      afterSuccess: afterSuccess,
      afterError: afterError,
    );
  }

  /// Runs [run] like [submitState], but if it has already succeeded, returns 
  /// the cached success state directly without re-executing.
  Future<MutationState<Result>> submitStateOnce(
    Future<Result> Function(MutationTransaction tx, FormState form) run, {
    FutureOr<void> Function(Result result)? afterSuccess,
    FutureOr<void> Function(Object error, StackTrace stackTrace)? afterError,
  }) {
    return submitState(
      run,
      ignoreIfSuccess: true,
      afterSuccess: afterSuccess,
      afterError: afterError,
    );
  }

  void resetMutation() {
    _runner.reset(ref, mutation);
  }
}

/// Shared helper for provider forms backed by async build state.
mixin AsyncStateFormMixin<FormState, Result> on $AsyncNotifier<FormState> {
  final _runner = MutationRunner<Result>(
    resetPolicy: MutationResetPolicy.onOwnerDispose,
  );

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
    bool ignoreIfSuccess = false,
    FutureOr<void> Function(Result result)? afterSuccess,
    FutureOr<void> Function(Object error, StackTrace stackTrace)? afterError,
  }) {
    return _runner.submitAction(
      ref,
      mutation,
      (tx) => run(tx, _formState),
      ignoreIfSuccess: ignoreIfSuccess,
      afterSuccess: afterSuccess,
      afterError: afterError,
    );
  }

  /// Runs [run] like [submit], but returns [mutation]'s resulting state instead
  /// of throwing on failure.
  Future<MutationState<Result>> submitState(
    Future<Result> Function(MutationTransaction tx, FormState form) run, {
    bool ignoreIfSuccess = false,
    FutureOr<void> Function(Result result)? afterSuccess,
    FutureOr<void> Function(Object error, StackTrace stackTrace)? afterError,
  }) {
    return _runner.submitActionState(
      ref,
      mutation,
      (tx) => run(tx, _formState),
      ignoreIfSuccess: ignoreIfSuccess,
      afterSuccess: afterSuccess,
      afterError: afterError,
    );
  }

  /// Runs [run] like [submit], but if it has already succeeded, returns 
  /// the cached success value directly without re-executing.
  Future<Result> submitOnce(
    Future<Result> Function(MutationTransaction tx, FormState form) run, {
    FutureOr<void> Function(Result result)? afterSuccess,
    FutureOr<void> Function(Object error, StackTrace stackTrace)? afterError,
  }) {
    return submit(
      run,
      ignoreIfSuccess: true,
      afterSuccess: afterSuccess,
      afterError: afterError,
    );
  }

  /// Runs [run] like [submitState], but if it has already succeeded, returns 
  /// the cached success state directly without re-executing.
  Future<MutationState<Result>> submitStateOnce(
    Future<Result> Function(MutationTransaction tx, FormState form) run, {
    FutureOr<void> Function(Result result)? afterSuccess,
    FutureOr<void> Function(Object error, StackTrace stackTrace)? afterError,
  }) {
    return submitState(
      run,
      ignoreIfSuccess: true,
      afterSuccess: afterSuccess,
      afterError: afterError,
    );
  }

  void resetMutation() {
    _runner.reset(ref, mutation);
  }
}

/// Shared helper for action-only providers with no own state.
///
/// Providers using this mixin should return `void` from `build()` and expose
/// mutation progress by watching the separate [mutation] accessor.
mixin MutationActionMixin<Result> on $Notifier<void> {
  final _runner = MutationRunner<Result>(
    resetPolicy: MutationResetPolicy.manual,
  );

  Mutation<Result> get mutation;

  Future<Result> submitAction(
    Future<Result> Function(MutationTransaction tx) run, {
    bool ignoreIfSuccess = false,
    FutureOr<void> Function(Result result)? afterSuccess,
    FutureOr<void> Function(Object error, StackTrace stackTrace)? afterError,
  }) {
    return _runner.submitAction(
      ref,
      mutation,
      run,
      ignoreIfSuccess: ignoreIfSuccess,
      afterSuccess: afterSuccess,
      afterError: afterError,
    );
  }

  /// Runs [run] like [submitAction], but returns [mutation]'s resulting state
  /// instead of throwing on failure.
  Future<MutationState<Result>> submitActionState(
    Future<Result> Function(MutationTransaction tx) run, {
    bool ignoreIfSuccess = false,
    FutureOr<void> Function(Result result)? afterSuccess,
    FutureOr<void> Function(Object error, StackTrace stackTrace)? afterError,
  }) {
    return _runner.submitActionState(
      ref,
      mutation,
      run,
      ignoreIfSuccess: ignoreIfSuccess,
      afterSuccess: afterSuccess,
      afterError: afterError,
    );
  }

  /// Runs [run] like [submitAction], but if it has already succeeded, returns 
  /// the cached success value directly without re-executing.
  Future<Result> submitActionOnce(
    Future<Result> Function(MutationTransaction tx) run, {
    FutureOr<void> Function(Result result)? afterSuccess,
    FutureOr<void> Function(Object error, StackTrace stackTrace)? afterError,
  }) {
    return submitAction(
      run,
      ignoreIfSuccess: true,
      afterSuccess: afterSuccess,
      afterError: afterError,
    );
  }

  /// Runs [run] like [submitActionState], but if it has already succeeded, returns 
  /// the cached success state directly without re-executing.
  Future<MutationState<Result>> submitActionStateOnce(
    Future<Result> Function(MutationTransaction tx) run, {
    FutureOr<void> Function(Result result)? afterSuccess,
    FutureOr<void> Function(Object error, StackTrace stackTrace)? afterError,
  }) {
    return submitActionState(
      run,
      ignoreIfSuccess: true,
      afterSuccess: afterSuccess,
      afterError: afterError,
    );
  }

  void resetMutation() {
    _runner.reset(ref, mutation);
  }
}
