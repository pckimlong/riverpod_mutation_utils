## 0.3.2

- Switched the generator to a git-only release model with `publish_to: none`.
- Changed the runtime dependency to resolve from matching git tags instead of
  hosted pub.
- Updated installation docs to use git tags instead of hosted pub versions.

## 0.3.1

- Fixed generated mutation accessors for family providers with named
  parameters.
- Expanded generator usage docs and added checked runtime examples that verify
  non-family, single-parameter family, and multi-parameter family generation.

## 0.3.0

- Initial generator release.
- Added `@GenerateMutation()` support for runtime mixins.
- Generates family-safe keyed mutation accessors and mixins.
