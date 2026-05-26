#!/usr/bin/env bash
# Shared test helpers for cc-cleanline bats suite.

# Absolute path to the repo root (one level up from tests/).
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${TESTS_DIR}/.." && pwd)"
FIXTURES_DIR="${TESTS_DIR}/fixtures"
SNAPSHOTS_DIR="${TESTS_DIR}/snapshots"

# Run cc-cleanline.sh with a fixture JSON piped to stdin.
# Usage: run_cleanline_with <fixture-name-without-extension>
run_cleanline_with() {
    local fixture="$1"
    local fixture_path="${FIXTURES_DIR}/${fixture}.json"
    if [[ ! -f "$fixture_path" ]]; then
        echo "Fixture not found: $fixture_path" >&2
        return 1
    fi
    HAPPY_MODE=false "${REPO_ROOT}/cc-cleanline.sh" < "$fixture_path"
}

# Source a single module in isolation for unit tests.
# Usage: source_module <relative-path-from-repo-root>
source_module() {
    local module="$1"
    # shellcheck disable=SC1090
    source "${REPO_ROOT}/cc-cleanline.config.sh"
    # shellcheck disable=SC1090
    source "${REPO_ROOT}/${module}"
}

# Compare output against a snapshot file. Snapshots live under tests/snapshots/.
# If BATS_UPDATE_SNAPSHOTS=1 is set, the snapshot is (re)written instead of compared.
# Usage: assert_snapshot <snapshot-name-without-extension> <actual-output>
assert_snapshot() {
    local name="$1"
    local actual="$2"
    local snapshot_path="${SNAPSHOTS_DIR}/${name}.txt"

    if [[ "${BATS_UPDATE_SNAPSHOTS:-0}" = "1" ]]; then
        mkdir -p "$(dirname "$snapshot_path")"
        printf '%s' "$actual" > "$snapshot_path"
        return 0
    fi

    if [[ ! -f "$snapshot_path" ]]; then
        echo "Missing snapshot: $snapshot_path" >&2
        echo "Run with BATS_UPDATE_SNAPSHOTS=1 to create it." >&2
        return 1
    fi

    local expected
    expected="$(cat "$snapshot_path")"
    if [[ "$actual" != "$expected" ]]; then
        echo "Snapshot mismatch for $name:" >&2
        diff <(printf '%s' "$expected") <(printf '%s' "$actual") >&2 || true
        return 1
    fi
}

# Assert a substring is present in a string.
assert_contains() {
    local haystack="$1"
    local needle="$2"
    if [[ "$haystack" != *"$needle"* ]]; then
        echo "Expected to find '${needle}' in:" >&2
        echo "$haystack" >&2
        return 1
    fi
}

# Assert a substring is NOT present in a string.
assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    if [[ "$haystack" == *"$needle"* ]]; then
        echo "Did NOT expect to find '${needle}' in:" >&2
        echo "$haystack" >&2
        return 1
    fi
}

# Strip ANSI escape sequences from a string. Useful for snapshot tests
# where color output would otherwise dominate the diff.
strip_ansi() {
    printf '%s' "$1" | sed -E $'s/\x1b\\[[0-9;]*[A-Za-z]//g'
}

# Skip the test if `jq` is not installed (cc-cleanline depends on it).
require_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        skip "jq not installed"
    fi
}
