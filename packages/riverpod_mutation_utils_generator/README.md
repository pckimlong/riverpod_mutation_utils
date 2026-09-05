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
  riverpod_mutation_utils: ^0.5.5

dev_dependencies:
  build_runner: ^2.15.1
  riverpod_generator: ^4.0.4
  riverpod_mutation_utils_generator: ^0.5.6
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
dart run build_runner build
```

The generator emits:

- a top-level `Mutation<Result>` base
- a public mutation accessor such as `itemUpdateFormMutation(...)`
- a convenience abstract base such as `_$ItemUpdateFormMutation`
- a wiring mixin such as `_$ItemUpdateFormMutationWiring`

Family providers are keyed automatically. If the family has multiple
parameters, the generated accessor key becomes a record of those arguments.
Optional positional and named parameters retain their declared types and
default values in the mutation accessor.

## Compatibility

Version 0.5.6 supports:

| Dependency | Supported versions |
| --- | --- |
| Dart | `>=3.11.1 <4.0.0` |
| analyzer | `>=13.3.0 <15.0.0` |
| build | `>=4.0.8 <5.0.0` |
| source_gen | `>=4.2.4 <5.0.0` |
| riverpod_annotation | `>=4.0.2 <5.0.0` |
| riverpod_mutation_utils | `>=0.5.5 <0.6.0` |

The lower bounds remain usable; consumers do not need to pin every codegen
dependency to its latest release. Analyzer 13.3 uses the source_gen 4.2 line,
while analyzer 14 can use source_gen 4.2.4 or 4.3.x. A compatible build_runner
2.x release is selected through `build`; build_runner 2.15.1 or newer is
recommended for this analyzer range.

This builder and Riverpod's generator both emit shared parts that are combined
by `source_gen`. No `runs_before` ordering is required. Other shared-part
generators, including schema generators, can participate in the same build.
