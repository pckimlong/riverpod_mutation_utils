# riverpod_mutation_utils

Runtime helpers, annotations, and mixins for Riverpod experimental mutations.

This package provides a simple way to orchestrate mutation states (`idle`, `pending`, `success`, `error`) directly from Riverpod providers.

---

## Install

Add the runtime package and companion generator:

```yaml
dependencies:
  riverpod_mutation_utils: ^0.5.7

dev_dependencies:
  build_runner: ^2.7.1
  riverpod_mutation_utils_generator: ^0.5.5
```

---

## Quick Start (The Standard Action Pattern)

Use **`MutationActionMixin`** for action-only providers (e.g., login, creating/updating records) that do not hold their own state.

### 1. Define the Provider (Logic)

Annotate your notifier with `@generateMutation` and mix in `MutationActionMixin`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_mutation_utils/riverpod_mutation_utils.dart';

part 'dentist_create_provider.g.dart';

@generateMutation
@riverpod
class DentistCreate extends _$DentistCreateMutation with MutationActionMixin<DentistModel> {
  @override
  void build() {} // Always returns void for action mixins

  Future<MutationState<DentistModel>> call(DentistCreateInput input) async {
    // submitActionState runs the action and returns the MutationState (Success/Error) instead of throwing.
    return await submitActionState(
      (tsx) async {
        final repo = await tsx.get(dentistRepoProvider.future);
        return repo.create(input);
      },
    );
  }
}
```

### 2. Observe in UI (Presentation)

Use the generated top-level `[notifierName]Mutation` accessor to watch or listen to the state in your widgets:

```dart
Widget build(BuildContext context, WidgetRef ref) {
  // Watch the mutation state to show loading overlays or disable buttons
  final mutation = ref.watch(dentistCreateMutation());
  final isPending = mutation is MutationPending;

  return ElevatedButton(
    onPressed: isPending ? null : () {
      ref.read(dentistCreateProvider.notifier).call(input);
    },
    child: isPending ? CircularProgressIndicator() : Text('Save'),
  );
}
```

---

## Key Features

### 🚫 Prevent Resubmissions on Success (`submitActionOnce`)
To automatically skip execution if the mutation has already succeeded, suffix the submit method with `Once`:

```dart
Future<MutationState<DentistModel>> call(DentistCreateInput input) async {
  // If already successful, returns cached state immediately without calling repo.create
  return await submitActionStateOnce((tsx) async {
    final repo = await tsx.get(dentistRepoProvider.future);
    return repo.create(input);
  });
}
```

### 🔄 Action Submissions vs. State Submissions
* **`submitAction` / `submit`** acts like a normal async call: returns the raw result on success and **throws** on failure.
* **`submitActionState` / `submitState`** acts as a UI-friendly channel: catches failures internally and returns the final **`MutationState`** (either `MutationSuccess` or `MutationError`).

---

## Form Patterns

If your notifier holds sync or async form state and you want the mutation to reset automatically when the provider is disposed, mix in `StateFormMixin` or `AsyncStateFormMixin` instead of `MutationActionMixin`.

### Example (Sync Form):
```dart
@generateMutation
@riverpod
class ItemUpdateForm extends _$ItemUpdateFormMutation with StateFormMixin<ItemFormState, String> {
  @override
  ItemFormState build() => ItemFormState();

  Future<String> save() {
    // Passes the current state (form) to your run callback
    return submit((tx, form) async {
      return await api.update(form);
    });
  }
}
```

---

## Core API Reference

- `MutationRunner<Result>` — Low-level helper runner.
- `MutationActionMixin<Result>` — For action-only providers (`Notifier<void>`).
- `StateFormMixin<FormState, Result>` — For synchronous form state providers.
- `AsyncStateFormMixin<FormState, Result>` — For asynchronous form state providers.
