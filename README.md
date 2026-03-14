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

Install the bundled Codex skill from this repository with:

```sh
npx skills add pckimlong/riverpod_mutation_utils
```

## Publishing

This repo is configured for pub.dev automated publishing from GitHub Actions.

Before automation can work:

- Publish the first version of each package manually on pub.dev.
- In each package's pub.dev Admin tab, enable automated publishing from `pckimlong/riverpod_mutation_utils`.
- Add a repository secret named `RELEASE_TAG_TOKEN` so `.github/workflows/release.yml` can push tags without using the default `GITHUB_TOKEN`.
- Configure these tag patterns:
  - `riverpod_mutation_utils-v{{version}}`
  - `riverpod_mutation_utils_generator-v{{version}}`

After that, version bumps merged to `main` trigger [`.github/workflows/release.yml`](/Users/kim/Development/Projects/MyPackages/riverpod_mutation_utils/.github/workflows/release.yml), which creates per-package tags and GitHub releases. Those tag pushes trigger the publish workflows for pub.dev.
