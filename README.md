# riverpod_mutation_utils workspace

Monorepo for:

- `packages/riverpod_mutation_utils`: runtime mixins, annotations, and helpers
- `packages/riverpod_mutation_utils_generator`: code generation for mutation wiring

This repo uses a Dart workspace so both packages can evolve and test together.

Common workspace commands:

```sh
dart pub get
dart format .
cd packages/riverpod_mutation_utils && dart run build_runner build --delete-conflicting-outputs
cd packages/riverpod_mutation_utils && dart test
cd packages/riverpod_mutation_utils_generator && dart test
```
