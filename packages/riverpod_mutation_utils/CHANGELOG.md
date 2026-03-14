## 0.3.2

- Switched the package to a git-only release model with `publish_to: none`.
- Updated installation docs to use git tags instead of hosted pub versions.
- Bumped the companion generator dependency to `0.3.2`.

## 0.3.1

- Added generated usage examples for non-family, single-parameter family, and
  multi-parameter family providers.
- Stopped committing generated example `.g.dart` files and updated CI to
  regenerate them before analysis and tests.
- Expanded the package README with installation, quick-start, and design notes.

## 0.3.0

- Added `GenerateMutation` for generator-driven mutation wiring.
- Added `generateMutation` as a const annotation instance for `@generateMutation`.
- Added a no-codegen example using `MutationRunner` directly.
- Added a handwritten `riverpod_annotation` example for manual mutation wiring.
- Added a handwritten non-family `riverpod_annotation` example.
- Switched mixins to derive `mutation` from `mutationBase` and optional
  `mutationKey`, which makes family-safe mutation generation possible.
- Re-exported Riverpod experimental mutation APIs from the runtime package.

## 0.2.0

- Changed `afterSuccess` callbacks to receive only the mutation result.
- Kept submitting providers alive while mutations are pending and skip
  `afterSuccess` if the original ref becomes unmounted.
- Removed deprecated `perform` and `performAction` helpers.

## 0.1.0

- Added `MutationRunner<Result>` for reusable mutation execution and listening.
- Added `StateFormMixin`, `AsyncStateFormMixin`, and `MutationActionMixin`.
- Replaced scaffold placeholders with working package docs, example, and tests.
