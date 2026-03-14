# riverpod_mutation_utils

Shared helpers for Riverpod experimental mutations.

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

## Usage

```dart
import 'package:riverpod/experimental/mutation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_mutation_utils/riverpod_mutation_utils.dart';

part 'example.g.dart';

@riverpod
class CounterSave extends _$CounterSave with StateFormMixin<int, int> {
  static final _mutation = Mutation<int>();

  @override
  int build() => 0;

  @override
  Mutation<int> get mutation => _mutation;

  Future<int> call() {
    return submit((tx, form) async {
      return form + 1;
    });
  }
}
```

## API

- `MutationRunner<Result>`
- `StateFormMixin<FormState, Result>`
- `AsyncStateFormMixin<FormState, Result>`
- `MutationActionMixin<Result>`
