# Verified Patterns

Use these patterns as the source of truth for this workspace. They are derived from the runtime code in `packages/riverpod_mutation_utils/lib/src/mutation_utils.dart`, the generator in `packages/riverpod_mutation_utils_generator/lib/src/generate_mutation_generator.dart`, and the examples and tests under `packages/riverpod_mutation_utils`.

## Pick A Pattern

- Direct runtime helper: use `MutationRunner<Result>` when not relying on `riverpod_annotation`.
- Manual annotation wiring: use `StateFormMixin`, `AsyncStateFormMixin`, or `MutationActionMixin` and implement the `mutation` getter yourself.
- Generated wiring: add `@generateMutation` and extend the generated abstract base instead of the plain Riverpod base.

## Direct Runner

Use this when the provider is plain Riverpod code:

```dart
final saveCounterMutation = Mutation<int>();

class CounterSaveController extends Notifier<int> {
  final _runner = MutationRunner<int>();

  @override
  int build() => 0;

  Future<int> save() {
    return _runner.submitAction(
      ref,
      saveCounterMutation,
      (tx) async {
        final next = state + 1;
        state = next;
        return next;
      },
    );
  }
}
```

What this guarantees:

- Concurrent `submitAction(...)` calls on the same runner share one in-flight `Future`.
- `afterSuccess` and `afterError` can use the outer `ref`, but only while `ref.mounted` is still true.
- The default reset policy resets the mutation when the owning provider is disposed.

## Manual `riverpod_annotation` Wiring

Non-family providers use one stable mutation directly:

```dart
final counterSaveMutation = Mutation<int>();

@riverpod
class ManualCounterSave extends _$ManualCounterSave
    with StateFormMixin<int, int> {
  @override
  int build() => 0;

  @override
  Mutation<int> get mutation => counterSaveMutation;

  Future<int> save() {
    return submit((tx, form) async {
      state = form + 1;
      return state;
    });
  }
}
```

Family providers must key the mutation when state isolation matters:

```dart
final itemUpdateFormMutationBase = Mutation<String>();

Mutation<String> itemUpdateFormMutation(String id) {
  return itemUpdateFormMutationBase(id);
}

@riverpod
class ManualItemUpdateForm extends _$ManualItemUpdateForm
    with StateFormMixin<String, String> {
  @override
  String build(String id) => id;

  @override
  Mutation<String> get mutation => itemUpdateFormMutation(id);

  Future<String> save() {
    return submit((tx, form) async => 'saved:$form');
  }
}
```

Important test-backed rule:

- Reusing one unkeyed `Mutation<int>()` across family instances shares pending and success state.
- Keying with `base(id)` isolates state per family argument.

## Generated Wiring

Generated non-family provider:

```dart
@generateMutation
@riverpod
class GeneratedCounterSave extends _$GeneratedCounterSaveMutation
    with StateFormMixin<int, int> {
  @override
  int build() => 0;

  Future<int> save() {
    return submit((tx, form) async {
      state = form + 1;
      return state;
    });
  }
}
```

Verified generated members:

- Mutation accessor: `generatedCounterSaveMutation()`
- Generated abstract base: `_$GeneratedCounterSaveMutation`
- Generated mutation getter body: `_$generatedCounterSaveMutationBase`

Generated family provider:

```dart
@generateMutation
@riverpod
class ItemUpdateForm extends _$ItemUpdateFormMutation
    with StateFormMixin<String, String> {
  @override
  String build(String id) => id;

  Future<String> save() {
    return submit((tx, form) async => 'saved:$form');
  }
}
```

Verified generated members:

- Mutation accessor: `itemUpdateFormMutation(String id)`
- Generated abstract base: `_$ItemUpdateFormMutation`
- Generated mutation getter body: `_$itemUpdateFormMutationBase(id)`

Generated multi-parameter family providers use a record key:

```dart
@generateMutation
@riverpod
class GeneratedScopedItemUpdate extends _$GeneratedScopedItemUpdateMutation
    with StateFormMixin<String, String> {
  @override
  String build(String id, {required String orgId}) => '$orgId:$id';
}
```

Verified generated members:

- Mutation accessor: `generatedScopedItemUpdateMutation(String id, {required String orgId})`
- Keyed mutation base usage: `_$generatedScopedItemUpdateMutationBase((id, orgId))`
- Generated provider family argument type: `(String, {String orgId})`

## Action-Only Providers

Use `MutationActionMixin<Result>` on `Notifier<void>` providers:

```dart
final counterSaveMutation = Mutation<int>();

@riverpod
class ManualCounterAction extends _$ManualCounterAction
    with MutationActionMixin<int> {
  @override
  void build() {}

  @override
  Mutation<int> get mutation => counterSaveMutation;

  Future<int> save() {
    return submitAction((tx) async => 1);
  }
}
```

Important behavior:

- The mutation stays successful after the owner is disposed.
- Call `resetMutation()` or `counterSaveMutation.reset(ref.container)` to clear it.

## Async Forms

Use `AsyncStateFormMixin<FormState, Result>` only when the async state has already resolved:

```dart
@riverpod
class AsyncSave extends _$AsyncSave with AsyncStateFormMixin<int, int> {
  @override
  Future<int> build() async => 0;

  @override
  Mutation<int> get mutation => asyncSaveMutation;

  Future<int> save() {
    return submit((tx, form) async {
      final next = form + 1;
      state = AsyncData(next);
      return next;
    });
  }
}
```

Important behavior:

- `submit()` throws `StateError` if `state.hasValue` is still false.

## What To Test

Mirror the existing tests when adding package behavior:

- Pending to success flow for one mutation accessor.
- Isolation between family instances.
- Shared state when family instances intentionally reuse one unkeyed mutation.
- Reset semantics for form mixins versus action mixins.
- `afterSuccess` and `afterError` behavior when the provider is invalidated mid-flight.
- Coalescing when `submitAction(...)` is called concurrently.
