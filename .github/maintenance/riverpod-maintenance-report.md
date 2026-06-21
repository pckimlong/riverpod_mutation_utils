# Riverpod Maintenance Report

Generated: 2026-06-21 10:38:54 UTC

This report is produced by the scheduled Riverpod maintenance workflow.
It captures dependency drift, verification output, and the manual API
review checklist needed before publishing compatibility releases.

## Upstream References

- Riverpod mutation docs:
  https://riverpod.dev/docs/concepts2/mutations
- Riverpod mutation API reference:
  https://pub.dev/documentation/riverpod/latest/experimental_mutation/
- `riverpod` changelog:
  https://pub.dev/packages/riverpod/changelog
- `riverpod_annotation` changelog:
  https://pub.dev/packages/riverpod_annotation/changelog
- `riverpod_generator` changelog:
  https://pub.dev/packages/riverpod_generator/changelog

## Riverpod API Review Checklist

- [ ] Read the current Riverpod mutation docs:
      https://riverpod.dev/docs/concepts2/mutations
- [ ] Read the current Riverpod mutation API reference:
      https://pub.dev/documentation/riverpod/latest/experimental_mutation/
- [ ] Check the latest `riverpod`, `riverpod_annotation`, and
      `riverpod_generator` changelogs for mutation, notifier, ref lifecycle,
      family, generator, or analyzer API changes.
- [ ] Confirm `Mutation.run(...)`, `Mutation.reset(...)`, keyed mutation access
      through `mutation(key)`, `MutationTransaction`, and `MutationState`
      pattern matching still match this package's public API.
- [ ] Add or update tests if Riverpod changed mutation state transitions,
      auto-dispose behavior, family key behavior, generator output, or analyzer
      APIs used by `riverpod_mutation_utils_generator`.
- [ ] If package constraints changed, confirm they follow Dart package practice:
      broad compatible ranges for libraries, narrow lower bounds only when the
      package uses APIs introduced by that version, and no unnecessary runtime
      dependency bumps.

## Initial Dependency Status

```text
Showing outdated packages.
[*] indicates versions that are not the latest available.

Package Name         Current  Upgradable  Resolvable  Latest   

direct dependencies:
analyzer             *12.1.0  *12.1.0     *12.1.0     14.0.0   

dev_dependencies: all up-to-date.

transitive dependencies:
_fe_analyzer_shared  *99.0.0  *99.0.0     *99.0.0     104.0.0  
dart_style           *3.1.8   *3.1.8      *3.1.8      3.1.9    
package_config       *2.2.0   *2.2.0      *2.2.0      3.0.0    

transitive dev_dependencies:
mockito              *5.6.4   *5.6.4      *5.6.4      5.7.0    
You are already using the newest resolvable versions listed in the 'Resolvable' column.
Newer versions, listed in 'Latest', may not be mutually compatible.
```

Exit code: 0

## Upgrade Compatible Dependencies

```text
Resolving dependencies...
Downloading packages...
  _fe_analyzer_shared 99.0.0 (104.0.0 available)
  analyzer 12.1.0 (14.0.0 available)
  dart_style 3.1.8 (3.1.9 available)
  mockito 5.6.4 (5.7.0 available)
  package_config 2.2.0 (3.0.0 available)
No dependencies changed.
5 packages have newer versions incompatible with dependency constraints.
Try `dart pub outdated` for more information.
```

Exit code: 0

## Post-upgrade Dependency Status

```text
Showing outdated packages.
[*] indicates versions that are not the latest available.

Package Name         Current  Upgradable  Resolvable  Latest   

direct dependencies:
analyzer             *12.1.0  *12.1.0     *12.1.0     14.0.0   

dev_dependencies: all up-to-date.

transitive dependencies:
_fe_analyzer_shared  *99.0.0  *99.0.0     *99.0.0     104.0.0  
dart_style           *3.1.8   *3.1.8      *3.1.8      3.1.9    
package_config       *2.2.0   *2.2.0      *2.2.0      3.0.0    

transitive dev_dependencies:
mockito              *5.6.4   *5.6.4      *5.6.4      5.7.0    
You are already using the newest resolvable versions listed in the 'Resolvable' column.
Newer versions, listed in 'Latest', may not be mutually compatible.
```

Exit code: 0

## Major Upgrade Dry Run

```text

No changes would be made to any pubspec.yaml!
Resolving dependencies...
Downloading packages...
  _fe_analyzer_shared 99.0.0 (104.0.0 available)
  analyzer 12.1.0 (14.0.0 available)
  dart_style 3.1.8 (3.1.9 available)
  mockito 5.6.4 (5.7.0 available)
  package_config 2.2.0 (3.0.0 available)
No dependencies would change.
5 packages have newer versions incompatible with dependency constraints.
Try `dart pub outdated` for more information.
```

Exit code: 0

## Generate Examples

```text
  0s riverpod_mutation_utils_generator on 13 inputs; example/generated_multi_param_example.dart
  0s riverpod_mutation_utils_generator on 13 inputs: 13 skipped
  0s riverpod_generator on 13 inputs; example/generated_multi_param_example.dart
  0s riverpod_generator on 13 inputs: 13 skipped
  0s source_gen:combining_builder on 13 inputs; example/generated_multi_param_example.dart
  0s source_gen:combining_builder on 13 inputs: 13 skipped
  Built with build_runner/aot in 0s; wrote 0 outputs.
```

Exit code: 0

## Analyze Runtime Package

```text
Analyzing riverpod_mutation_utils...
No issues found!
```

Exit code: 0

## Analyze Generator Package

```text
Analyzing riverpod_mutation_utils_generator...
No issues found!
```

Exit code: 0

## Test Runtime Package

```text
00:00 +0: loading test/manual_annotation_non_family_example_test.dart
00:00 +0: test/manual_annotation_non_family_example_test.dart: manual non-family annotation example uses the base mutation directly
00:00 +1: test/riverpod_mutation_utils_test.dart: MutationRunner coalesces concurrent submits into one execution
00:00 +2: test/generated_example_test.dart: generated family mutation accessor isolates state by id
00:00 +3: test/generated_example_test.dart: generated family mutation accessor isolates state by id
00:00 +4: test/generated_example_test.dart: generated family mutation accessor isolates state by id
00:00 +5: test/generated_example_test.dart: generated family mutation accessor isolates state by id
00:00 +6: test/generated_example_test.dart: generated family mutation accessor isolates state by id
00:00 +7: test/generated_multi_param_example_test.dart: generated multi-param family mutation accessor isolates state by record key
00:00 +8: test/generated_multi_param_example_test.dart: generated multi-param family mutation accessor isolates state by record key
00:00 +9: test/generated_multi_param_example_test.dart: generated multi-param family mutation accessor isolates state by record key
00:00 +10: test/generated_multi_param_example_test.dart: generated multi-param family mutation accessor isolates state by record key
00:00 +11: test/generated_multi_param_example_test.dart: generated multi-param family mutation accessor isolates state by record key
00:00 +12: test/generated_multi_param_example_test.dart: generated multi-param family mutation accessor isolates state by record key
00:00 +13: test/manual_annotation_example_test.dart: manual annotation example isolates mutation state by id
00:00 +14: test/manual_annotation_example_test.dart: manual annotation example isolates mutation state by id
00:00 +15: test/manual_annotation_example_test.dart: manual annotation example isolates mutation state by id
00:00 +16: test/manual_annotation_example_test.dart: manual annotation example isolates mutation state by id
00:00 +17: test/manual_annotation_example_test.dart: manual annotation example isolates mutation state by id
00:00 +18: test/manual_annotation_example_test.dart: manual annotation example isolates mutation state by id
00:00 +19: test/manual_annotation_example_test.dart: manual annotation example isolates mutation state by id
00:00 +20: test/generated_non_family_example_test.dart: generated non-family mutation accessor uses the base mutation directly
00:00 +21: test/generated_non_family_example_test.dart: generated non-family mutation accessor uses the base mutation directly
00:00 +22: test/generated_non_family_example_test.dart: generated non-family mutation accessor uses the base mutation directly
00:00 +23: test/generated_non_family_example_test.dart: generated non-family mutation accessor uses the base mutation directly
00:00 +24: test/riverpod_mutation_utils_test.dart: MutationRunner family providers that reuse one mutation share pending and success state
00:00 +25: test/riverpod_mutation_utils_test.dart: MutationRunner keyed family mutations isolate pending and success state per family argument
00:00 +26: test/riverpod_mutation_utils_test.dart: MutationRunner forwards mutation success notifications
00:00 +27: test/riverpod_mutation_utils_test.dart: MutationRunner forwards mutation error notifications
00:00 +28: All tests passed!
```

Exit code: 0

## Test Generator Package

```text
00:00 +0: loading test/generate_mutation_generator_test.dart
00:00 +0: test/generate_mutation_generator_test.dart: renderMutationSpec renders an unkeyed mutation for non-family notifiers
00:00 +1: test/generate_mutation_generator_test.dart: renderMutationSpec renders keyed mutations for family notifiers
00:00 +2: All tests passed!
```

Exit code: 0

## Format Check

```text
Formatted 21 files (0 changed) in 0.03 seconds.
```

Exit code: 0

## Publish Decision

Use this PR to decide whether a package release is needed:

- If only `pubspec.lock` changed and all APIs still match, merge is optional
  unless the repo wants a refreshed verification baseline.
- If constraints changed or downstream apps cannot solve packages, update the
  affected package version and changelog before publishing.
- If Riverpod's mutation model changed, keep runtime behavior covered by focused
  tests before publishing.

## Workflow Result

All automated maintenance commands passed.
