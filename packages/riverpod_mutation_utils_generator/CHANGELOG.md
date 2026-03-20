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
