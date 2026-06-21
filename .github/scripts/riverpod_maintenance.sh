#!/usr/bin/env bash
set -euo pipefail

report_path=".github/maintenance/riverpod-maintenance-report.md"
runtime_dir="packages/riverpod_mutation_utils"
generator_dir="packages/riverpod_mutation_utils_generator"
maintenance_failed=0

mkdir -p "$(dirname "${report_path}")"

run_section() {
  local title="$1"
  shift

  {
    echo
    echo "## ${title}"
    echo
    echo '```text'
  } >>"${report_path}"

  set +e
  "$@" >>"${report_path}" 2>&1
  local status=$?
  set -e

  {
    echo '```'
    echo
    echo "Exit code: ${status}"
  } >>"${report_path}"

  return "${status}"
}

append_checklist() {
  cat >>"${report_path}" <<'EOF'

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
EOF
}

{
  echo "# Riverpod Maintenance Report"
  echo
  echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo
  echo "This report is produced by the scheduled Riverpod maintenance workflow."
  echo "It captures dependency drift, verification output, and the manual API"
  echo "review checklist needed before publishing compatibility releases."
} >"${report_path}"

append_checklist

run_section "Initial Dependency Status" dart pub outdated || true

run_section "Upgrade Compatible Dependencies" dart pub upgrade || maintenance_failed=1

run_section "Post-upgrade Dependency Status" dart pub outdated || true

run_section "Major Upgrade Dry Run" dart pub upgrade --major-versions --dry-run || true

run_section "Generate Examples" bash -lc "cd '${runtime_dir}' && dart run build_runner build" || maintenance_failed=1

run_section "Analyze Runtime Package" bash -lc "cd '${runtime_dir}' && dart analyze" || maintenance_failed=1
run_section "Analyze Generator Package" bash -lc "cd '${generator_dir}' && dart analyze" || maintenance_failed=1

run_section "Test Runtime Package" bash -lc "cd '${runtime_dir}' && dart test" || maintenance_failed=1
run_section "Test Generator Package" bash -lc "cd '${generator_dir}' && dart test" || maintenance_failed=1

run_section "Format Check" dart format --output=none --set-exit-if-changed . || maintenance_failed=1

cat >>"${report_path}" <<'EOF'

## Publish Decision

Use this PR to decide whether a package release is needed:

- If only `pubspec.lock` changed and all APIs still match, merge is optional
  unless the repo wants a refreshed verification baseline.
- If constraints changed or downstream apps cannot solve packages, update the
  affected package version and changelog before publishing.
- If Riverpod's mutation model changed, keep runtime behavior covered by focused
  tests before publishing.
EOF

if [[ "${maintenance_failed}" -ne 0 ]]; then
  {
    echo
    echo "## Workflow Result"
    echo
    echo "At least one maintenance command failed. Keep the PR open and fix the"
    echo "reported issue before publishing."
  } >>"${report_path}"
else
  {
    echo
    echo "## Workflow Result"
    echo
    echo "All automated maintenance commands passed."
  } >>"${report_path}"
fi
