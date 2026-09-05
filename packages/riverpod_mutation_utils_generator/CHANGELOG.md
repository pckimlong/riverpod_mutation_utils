## 0.5.6

- Support analyzer `>=13.3.0 <15.0.0`, including analyzer 13.3 and 14, using
  public analyzer and source_gen APIs.
- Preserve optional positional and named parameter syntax, declared defaults,
  nullable types, and nested generic types in generated mutation accessors.
- Verify clean and incremental generation with current Riverpod generators and
  document compatible build/source_gen combinations.

## 0.5.5

- Improve the pub.dev README by removing local filesystem links and refreshing
  installation guidance for the current runtime package version.
- Bump the runtime package dependency to `0.5.5`.

## 0.5.4

- Relax the `analyzer` constraint to support `riverpod_generator 4.0.4`, which
  depends on `analyzer ^12.0.0`.
- Bump the runtime package dependency to `0.5.4`.

## 0.5.3

- Bump the runtime package dependency to `0.5.3`.

## 0.5.2

- Bump the runtime package dependency to `0.5.2`.

## 0.5.1

- Bump the runtime package dependency to `0.5.1`.

## 0.5.0

- Bump the runtime package dependency to `0.5.0`.

## 0.4.0

- Breaking: generate provider `mutation` overrides instead of `mutationBase`
  and `mutationKey` wiring.
- Add a convenience abstract base such as `_$ItemUpdateFormMutation`, plus a
  separate `_$ItemUpdateFormMutationWiring` mixin for compatibility.
- Bump the runtime package dependency to `0.4.0`.

## 0.3.4

- Retry the first automated pub.dev release after fixing release tag pushes to use `RELEASE_TAG_TOKEN`.
- Bump the runtime package dependency to `0.3.4`.

## 0.3.3

- Prepare the first automated pub.dev release after enabling GitHub Actions publishing.
- Bump the runtime package dependency to `0.3.3`.

## 0.3.2

- Restored hosted pub.dev dependency metadata for the runtime package.
- Added pub.dev automated publishing workflow support for tagged releases.
- Updated installation docs to use hosted pub versions.

## 0.3.1

- Fixed generated mutation accessors for family providers with named
  parameters.
- Expanded generator usage docs and added checked runtime examples that verify
  non-family, single-parameter family, and multi-parameter family generation.

## 0.3.0

- Initial generator release.
- Added `@GenerateMutation()` support for runtime mixins.
- Generates family-safe keyed mutation accessors and mixins.
