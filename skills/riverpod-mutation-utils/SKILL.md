---
name: riverpod-mutation-utils
description: Implement, refactor, or debug Riverpod experimental mutations with the `riverpod_mutation_utils` and `riverpod_mutation_utils_generator` packages. Use when Codex needs to add `MutationRunner`, `StateFormMixin`, `AsyncStateFormMixin`, `MutationActionMixin`, or `@generateMutation`; wire keyed mutation accessors for family providers; choose reset behavior; or write tests for pending, success, error, and coalescing flows in Dart or Flutter codebases.
---

# Riverpod Mutation Utils

Use this skill to apply the patterns supported by this workspace instead of inventing new mutation helpers. Prefer the existing runtime mixins and generator output, then shape provider code around them.

## Choose The Integration Level

Pick the smallest supported pattern that fits the provider:

- Use `MutationRunner<Result>` when the provider is not using `riverpod_annotation` or when only low-level mutation execution is needed.
- Use `StateFormMixin<FormState, Result>` for sync `Notifier` state that should be passed into `submit(...)`.
- Use `AsyncStateFormMixin<FormState, Result>` for `AsyncNotifier` state after the async build has resolved.
- Use `MutationActionMixin<Result>` for action-only `Notifier<void>` providers that do not own form state.
- Use `@generateMutation` when `riverpod_annotation` is already in play and the provider should receive generated mutation wiring.

## Apply The Supported Rules

Follow these package-specific rules:

- Define one stable `Mutation<Result>` base per logical mutation.
- Key family mutations by their family arguments when each family instance needs isolated pending and success state.
- Reuse one unkeyed `Mutation<Result>` across family instances only when shared state is intentional.
- Keep transaction-owned state writes inside `submit(...)` or `submitAction(...)`.
- Use `afterSuccess` or `afterError` only for post-transaction side effects. Assume those callbacks are skipped if the submitting provider becomes unmounted before completion.
- Expect concurrent calls through the same runner to coalesce into the same in-flight `Future`.
- Reset form-style mutations with `resetMutation()` or by disposing the owner. Reset action-only mutations manually.

## Implement Carefully

When adding or reviewing code:

1. Determine whether the provider is non-family, single-argument family, or multi-parameter family.
2. Choose manual wiring or `@generateMutation`.
3. Make the UI watch the mutation accessor, not just the provider state.
4. For async forms, ensure the provider has finished building before calling `submit()`.
5. Preserve the public generated names that come from the class name, such as `itemUpdateFormMutation(...)` and `_$ItemUpdateFormMutation`.

## Verify

- Run `dart run build_runner build --delete-conflicting-outputs` inside `packages/riverpod_mutation_utils` after changing annotated examples or providers.
- Run targeted tests in `packages/riverpod_mutation_utils/test` and `packages/riverpod_mutation_utils_generator/test` when changing behavior.
- Read `references/patterns.md` for verified examples and behavior notes before drafting new code.
