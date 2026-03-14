# riverpod_mutation_utils

Runtime helpers, annotations, and mixins for Riverpod experimental mutations.

For local development in this package, run `dart run build_runner build --delete-conflicting-outputs`
inside [packages/riverpod_mutation_utils](/Users/kim/Development/Projects/MyPackages/riverpod_mutation_utils/packages/riverpod_mutation_utils)
before `dart analyze` or `dart test`. Example `.g.dart` files are generated in CI and are not committed.

This package extracts the non-UI mutation layer so multiple apps can share:
- reset-on-dispose mutation handling
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
  riverpod_mutation_utils:
    git:
      url: https://github.com/pckimlong/riverpod_mutation_utils.git
      path: packages/riverpod_mutation_utils
      ref: riverpod_mutation_utils-v0.3.2
```

If you use `riverpod_annotation`, also add:

```yaml
dependencies:
  riverpod_annotation: ^4.0.2

dev_dependencies:
  build_runner: ^2.7.1
  riverpod_generator: ^4.0.2
```

If you want generated mutation wiring, also add:

```yaml
dev_dependencies:
  riverpod_mutation_utils_generator:
    git:
      url: https://github.com/pckimlong/riverpod_mutation_utils.git
      path: packages/riverpod_mutation_utils_generator
      ref: riverpod_mutation_utils_generator-v0.3.2
```

Keep both refs on the same release version. The generator resolves
`riverpod_mutation_utils` from the matching runtime tag.

## Quick Start

Pick one integration level:

- `MutationRunner` if you are not using `riverpod_annotation`
- `StateFormMixin` / `AsyncStateFormMixin` if you want handwritten mutation wiring
- `@generateMutation` if you want family-safe mutation wiring generated for you

The common shape is:

1. Define a stable `Mutation<Result>` base.
2. Run the mutation with `submit(...)` or `submitAction(...)`.
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
}
```

See [example/manual_runner_example.dart](/Users/kim/Development/Projects/MyPackages/riverpod_mutation_utils/packages/riverpod_mutation_utils/example/manual_runner_example.dart).

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
  Mutation<int> get mutationBase => counterSaveMutation;

  Future<int> save() {
    return submit((tx, form) async => form + 1);
  }
}
```

See [example/manual_annotation_non_family_example.dart](/Users/kim/Development/Projects/MyPackages/riverpod_mutation_utils/packages/riverpod_mutation_utils/example/manual_annotation_non_family_example.dart).

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
  Mutation<String> get mutationBase => itemUpdateFormMutationBase;

  @override
  Object get mutationKey => id;

  Future<String> save() {
    return submit((tx, form) async {
      return 'saved:$form';
    });
  }
}
```

See [example/manual_annotation_example.dart](/Users/kim/Development/Projects/MyPackages/riverpod_mutation_utils/packages/riverpod_mutation_utils/example/manual_annotation_example.dart).

## Generated Usage

The companion generator package can generate `mutationBase`, `mutationKey`, and
a public mutation accessor for you:

Non-family:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_mutation_utils/riverpod_mutation_utils.dart';

part 'generated_non_family_example.g.dart';

@generateMutation
@riverpod
class GeneratedCounterSave extends _$GeneratedCounterSave
    with StateFormMixin<int, int>, _$GeneratedCounterSaveMutation {
  @override
  int build() => 0;

  Future<int> save() {
    return submit((tx, form) async => form + 1);
  }
}
```

See [example/generated_non_family_example.dart](/Users/kim/Development/Projects/MyPackages/riverpod_mutation_utils/packages/riverpod_mutation_utils/example/generated_non_family_example.dart).

Family:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_mutation_utils/riverpod_mutation_utils.dart';

part 'item_update_form.g.dart';

@generateMutation
@riverpod
class ItemUpdateForm extends _$ItemUpdateForm
    with StateFormMixin<int, String>, _$ItemUpdateFormMutation {
  @override
  int build(String id) => 0;
}
```

That generated mixin wires the correct keyed mutation automatically, and the
generated top-level `itemUpdateFormMutation(...)` accessor can be watched from
the UI.

See [example/riverpod_mutation_utils_example.dart](/Users/kim/Development/Projects/MyPackages/riverpod_mutation_utils/packages/riverpod_mutation_utils/example/riverpod_mutation_utils_example.dart).

When a family has multiple parameters, the generated `mutationKey` becomes a
record of those arguments, so each parameter combination gets isolated mutation
state. See [example/generated_multi_param_example.dart](/Users/kim/Development/Projects/MyPackages/riverpod_mutation_utils/packages/riverpod_mutation_utils/example/generated_multi_param_example.dart).

`submit(...)` keeps the submitting provider alive while the mutation is pending,
which makes `afterSuccess` safe to use with `ref` for the common auto-dispose
case. If the provider is explicitly invalidated or rebuilt before completion,
the original ref becomes unmounted and `afterSuccess` is skipped.

## Design Notes

- `run(tx, ...)` is the only place where `MutationTransaction` is guaranteed to
  be valid.
- `afterSuccess` and `afterError` are post-transaction hooks.
- Family providers must use keyed mutations. Use `mutationKey` manually or
  prefer `@generateMutation` so the key is derived automatically.
- Multiple family parameters are keyed as a Dart record.
- Mutation state is transient. Watch the mutation if the UI needs to reflect
  pending, success, or error states.

## API

- `MutationRunner<Result>`
- `StateFormMixin<FormState, Result>`
- `AsyncStateFormMixin<FormState, Result>`
- `MutationActionMixin<Result>`
