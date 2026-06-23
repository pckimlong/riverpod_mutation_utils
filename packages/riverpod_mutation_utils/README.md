# riverpod_mutation_utils

Runtime helpers, annotations, and mixins for Riverpod experimental mutations.

This package extracts the non-UI mutation layer so multiple apps can share:
- configurable mutation reset handling
- in-flight submit coalescing
- sync and async form mixins
- mutation-only action mixins

## Scope

This package is intentionally small. It does not include:
- dialogs or pages
- toasts or error banners
- navigation helpers
- form widgets

Keep those concerns inside each app.

## Install

Runtime package:

```yaml
dependencies:
  riverpod_mutation_utils: ^0.5.5
```

If you use `riverpod_annotation`, also add:

```yaml
dependencies:
  riverpod_annotation: ^4.0.3

dev_dependencies:
  build_runner: ^2.7.1
  riverpod_generator: ^4.0.4
```

If you want generated mutation wiring, also add:

```yaml
dev_dependencies:
  riverpod_mutation_utils_generator: ^0.5.5
```

## Quick Start

Pick one integration level:

- `MutationRunner` if you are not using `riverpod_annotation`
- `StateFormMixin` / `AsyncStateFormMixin` if you want handwritten mutation wiring
- `MutationActionMixin` if you want an action-only provider with no own state
- `@generateMutation` if you want family-safe mutation wiring generated for you

The common shape is:

1. Define a stable `Mutation<Result>` base.
2. Run the mutation with `submit(...)` / `submitAction(...)`, or use the
   state-returning variants when the caller wants mutation state instead of a
   thrown error.
3. Watch the mutation accessor from the UI.

Example UI usage:

```dart
final mutation = ref.watch(itemUpdateFormMutation('item-1'));

if (mutation is MutationPending<String>) {
  return const CircularProgressIndicator();
}
```

`afterSuccess` runs after the transaction has closed. Use it for post-success
side effects that can safely use `ref` when the submitting provider is still
mounted. If a provider write is part of the mutation itself, keep it inside the
`run(tx, ...)` callback instead of `afterSuccess`.

`submit(...)` and `submitAction(...)` intentionally behave like normal async
functions: successful submissions return the mutation result, and failed
submissions throw. The mutation state is still updated so UI can observe
pending/success/error.

If mutation state is the caller's success/error channel, use `submitState(...)`
or `submitActionState(...)`. These methods return the final `MutationState`
instead of throwing, which is useful for form widgets that render
`MutationError` directly.

Action-only providers should return `void` from `build()` and expose mutation
progress by watching the separate `Mutation<Result>`. They stay alive while a
submission is pending, but do not automatically reset the mutation on provider
dispose. Reset them explicitly with `mutation.reset(ref)` when the UI or a
listener decides the transient state is no longer needed.

## Direct Runner Usage

If you are not using `riverpod_annotation`, use `MutationRunner` directly:

```dart
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_mutation_utils/riverpod_mutation_utils.dart';

final saveCounterMutation = Mutation<int>();

final counterSaveControllerProvider =
    NotifierProvider<CounterSaveController, int>(CounterSaveController.new);

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

  Future<MutationState<int>> saveAsState() {
    return _runner.submitActionState(
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

## Manual Usage With `riverpod_annotation`

This is still Riverpod codegen, but the mutation wiring is handwritten:

Non-family:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_mutation_utils/riverpod_mutation_utils.dart';

part 'manual_annotation_non_family_example.g.dart';

final counterSaveMutation = Mutation<int>();

@riverpod
class ManualCounterSave extends _$ManualCounterSave
    with StateFormMixin<int, int> {
  @override
  int build() => 0;

  @override
  Mutation<int> get mutation => counterSaveMutation;

  Future<int> save() {
    return submit((tx, form) async => form + 1);
  }
}
```

Family:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_mutation_utils/riverpod_mutation_utils.dart';

part 'manual_annotation_example.g.dart';

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
    return submit((tx, form) async {
      return 'saved:$form';
    });
  }
}
```

Action-only:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_mutation_utils/riverpod_mutation_utils.dart';

part 'manual_action_example.g.dart';

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

  Future<MutationState<int>> saveAsState() {
    return submitActionState((tx) async => 1);
  }
}
```

## Generated Usage

The companion generator package can generate a stable mutation base, a keyed
mutation accessor, and a convenience abstract base for you:

Non-family:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_mutation_utils/riverpod_mutation_utils.dart';

part 'generated_non_family_example.g.dart';

@generateMutation
@riverpod
class GeneratedCounterSave extends _$GeneratedCounterSaveMutation
    with StateFormMixin<int, int> {
  @override
  int build() => 0;

  Future<int> save() {
    return submit((tx, form) async => form + 1);
  }
}
```

Family:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_mutation_utils/riverpod_mutation_utils.dart';

part 'item_update_form.g.dart';

@generateMutation
@riverpod
class ItemUpdateForm extends _$ItemUpdateFormMutation
    with StateFormMixin<int, String> {
  @override
  int build(String id) => 0;
}
```

That generated base hides the wiring mixin while keeping
`StateFormMixin<...>` explicit, and the generated top-level
`itemUpdateFormMutation(...)` accessor can be watched from the UI.

When a family has multiple parameters, the generated accessor keys mutations by
a Dart record of those arguments, so each parameter combination gets isolated
mutation state.

`submit(...)` keeps the submitting provider alive while the mutation is pending,
which makes `afterSuccess` safe to use with `ref` for the common auto-dispose
case. If the provider is explicitly invalidated or rebuilt before completion,
the original ref becomes unmounted and `afterSuccess` is skipped.

Form mixins keep the previous default of resetting their mutation on owner
dispose. `MutationActionMixin` intentionally does not.

## Design Notes

- `run(tx, ...)` is the only place where `MutationTransaction` is guaranteed to
  be valid.
- `submit(...)` and `submitAction(...)` return `Result` and rethrow failures.
- `submitState(...)` and `submitActionState(...)` return the final
  `MutationState<Result>` and do not rethrow failures.
- `afterSuccess` and `afterError` are post-transaction hooks.
- `MutationActionMixin` is for `Notifier<void>` providers only.
- `MutationResetPolicy.onOwnerDispose` is the default for forms and direct
  `MutationRunner()` usage.
- `MutationResetPolicy.manual` is the default for `MutationActionMixin`.
- Family providers must return a keyed `mutation`. Prefer `@generateMutation`
  so the accessor is derived automatically.
- Multiple family parameters are keyed as a Dart record.
- Mutation state is transient. Watch the mutation if the UI needs to reflect
  pending, success, or error states.

## API

- `MutationRunner<Result>`
- `MutationResetPolicy`
- `StateFormMixin<FormState, Result>`
- `AsyncStateFormMixin<FormState, Result>`
- `MutationActionMixin<Result>`
