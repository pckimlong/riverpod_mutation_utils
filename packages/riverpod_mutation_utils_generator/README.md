# riverpod_mutation_utils_generator

Code generation for `riverpod_mutation_utils`.

This package generates:

- a stable `Mutation<Result>` base
- a keyed mutation accessor for family providers
- a convenience base and wiring mixin for the provider `mutation` getter

## Install

```yaml
dependencies:
  riverpod_annotation: ^4.0.2
  riverpod_mutation_utils: ^0.5.0

dev_dependencies:
  build_runner: ^2.7.1
  riverpod_generator: ^4.0.2
  riverpod_mutation_utils_generator: ^0.5.0
```

## Usage

Use it together with `@generateMutation` or `@GenerateMutation()` from the
runtime package.

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_mutation_utils/riverpod_mutation_utils.dart';

part 'item_update_form.g.dart';

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

Then run:

```sh
dart run build_runner build --delete-conflicting-outputs
```

The generator emits:

- a top-level `Mutation<Result>` base
- a public mutation accessor such as `itemUpdateFormMutation(...)`
- a convenience abstract base such as `_$ItemUpdateFormMutation`
- a wiring mixin such as `_$ItemUpdateFormMutationWiring`

Family providers are keyed automatically. If the family has multiple
parameters, the generated accessor key becomes a record of those arguments.

See:

- [generated_non_family_example.dart](/Users/kim/Development/Projects/MyPackages/riverpod_mutation_utils/packages/riverpod_mutation_utils/example/generated_non_family_example.dart)
- [riverpod_mutation_utils_example.dart](/Users/kim/Development/Projects/MyPackages/riverpod_mutation_utils/packages/riverpod_mutation_utils/example/riverpod_mutation_utils_example.dart)
- [generated_multi_param_example.dart](/Users/kim/Development/Projects/MyPackages/riverpod_mutation_utils/packages/riverpod_mutation_utils/example/generated_multi_param_example.dart)
