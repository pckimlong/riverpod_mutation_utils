# riverpod_mutation_utils_generator

Code generation for `riverpod_mutation_utils`.

This package generates:

- a stable `Mutation<Result>` base
- a keyed mutation accessor for family providers
- a generated mixin that wires `mutationBase` and `mutationKey`

## Install

```yaml
dependencies:
  riverpod_annotation: ^4.0.2
  riverpod_mutation_utils:
    git:
      url: https://github.com/pckimlong/riverpod_mutation_utils.git
      path: packages/riverpod_mutation_utils
      ref: riverpod_mutation_utils-v0.3.2

dev_dependencies:
  build_runner: ^2.7.1
  riverpod_generator: ^4.0.2
  riverpod_mutation_utils_generator:
    git:
      url: https://github.com/pckimlong/riverpod_mutation_utils.git
      path: packages/riverpod_mutation_utils_generator
      ref: riverpod_mutation_utils_generator-v0.3.2
```

Keep both refs on the same release version. Internally, the generator package
resolves the runtime package from the matching `riverpod_mutation_utils-v{{version}}`
tag.

## Usage

Use it together with `@generateMutation` or `@GenerateMutation()` from the
runtime package.

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_mutation_utils/riverpod_mutation_utils.dart';

part 'item_update_form.g.dart';

@generateMutation
@riverpod
class ItemUpdateForm extends _$ItemUpdateForm
    with StateFormMixin<String, String>, _$ItemUpdateFormMutation {
  @override
  String build(String id) => id;

  Future<String> save() {
    return submit((tx, form) async => 'saved:$form');
  }
}
```

Then run:

```sh
dart run build_runner build --delete-conflicting-outputs
```

The generator emits:

- a top-level `Mutation<Result>` base
- a public mutation accessor such as `itemUpdateFormMutation(...)`
- a mixin such as `_$ItemUpdateFormMutation`

Family providers are keyed automatically. If the family has multiple
parameters, the generated mutation key becomes a record of those arguments.

See:

- [generated_non_family_example.dart](/Users/kim/Development/Projects/MyPackages/riverpod_mutation_utils/packages/riverpod_mutation_utils/example/generated_non_family_example.dart)
- [riverpod_mutation_utils_example.dart](/Users/kim/Development/Projects/MyPackages/riverpod_mutation_utils/packages/riverpod_mutation_utils/example/riverpod_mutation_utils_example.dart)
- [generated_multi_param_example.dart](/Users/kim/Development/Projects/MyPackages/riverpod_mutation_utils/packages/riverpod_mutation_utils/example/generated_multi_param_example.dart)
