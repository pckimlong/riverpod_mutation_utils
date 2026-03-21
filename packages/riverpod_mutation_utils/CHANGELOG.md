## 0.5.4

- Change `MutationActionMixin` so action-only providers keep the owner alive
  while pending but no longer reset mutation state automatically on owner
  dispose.
- Add `MutationResetPolicy` and `MutationRunner.reset(...)` so reset ownership
  can be explicit and action mutations can be reset manually or by listeners.
- Keep `StateFormMixin` and `AsyncStateFormMixin` on reset-on-owner-dispose by
  default.

## 0.5.3

- Fix provider-disposal mutation reset timing by deferring `mutation.reset(...)`
  out of `ref.onDispose`, which avoids illegal provider writes during
  invalidation-driven rebuilds.
- Add regression coverage for async submitters that invalidate watched
  dependencies from `afterSuccess`.
- Bump the companion generator dependency to `0.5.3`.

## 0.5.2

- Revert the `0.5.1` `MutationActionMixin<Result>` default `build()` change.
  Action providers must declare `build(...)` explicitly so family providers
  keep their required parameter shape.
- Bump the companion generator dependency to `0.5.2`.

## 0.5.1

- Bump the companion generator dependency to `0.5.1`.

## 0.5.0

- Breaking: `MutationActionMixin<Result>` now requires `Notifier<void>` so
  action-only providers cannot use `MutationState<Result>` as their own state.
  Watch the separate mutation accessor for pending/success/error instead.
- Bump the companion generator dependency to `0.5.0`.

## 0.4.0

- Breaking: simplify runtime mixins to require a single `mutation` getter
  instead of `mutationBase` and `mutationKey`.
- Add a generated convenience base such as `_$ItemUpdateFormMutation`, so
  generated providers can keep `StateFormMixin<...>` explicit while hiding the
  wiring mixin.
- Bump the companion generator dependency to `0.4.0`.

## 0.3.4

- Retry the first automated pub.dev release after fixing release tag pushes to use `RELEASE_TAG_TOKEN`.
- Bump the companion generator dependency to `0.3.4`.

## 0.3.3

- Prepare the first automated pub.dev release after enabling GitHub Actions publishing.
- Bump the companion generator dependency to `0.3.3`.

## 0.3.2

- Restored hosted pub.dev release metadata and installation guidance.
- Added pub.dev automated publishing workflow support for tagged releases.
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
