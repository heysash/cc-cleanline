#!/usr/bin/env bats
# End-to-end snapshot tests for cc-cleanline.sh.
# Each fixture is piped through the real script; the output (ANSI-stripped)
# is compared against tests/snapshots/<fixture>.txt.
#
# Re-generate snapshots after intentional formatting changes:
#   BATS_UPDATE_SNAPSHOTS=1 bats tests/integration/
#
# To keep snapshots deterministic:
#   • HAPPY_MODE is forced off (otherwise easter eggs randomise output).
#   • The script runs in a fresh tmpdir without a git repo, so the git
#     status segment renders the static "no git repository" string.
#   • CC_CLEANLINE_MOCK_NOW pins the clock so resets_at math is stable.

load '../helpers.bash'

setup() {
    SNAPSHOT_TMPDIR="$(mktemp -d)"
    export SNAPSHOT_TMPDIR
}

teardown() {
    [[ -n "$SNAPSHOT_TMPDIR" && -d "$SNAPSHOT_TMPDIR" ]] && rm -rf "$SNAPSHOT_TMPDIR"
    unset SNAPSHOT_TMPDIR
}

# Run the main script against a fixture, in an isolated cwd (no git repo),
# strip ANSI escapes, and trim trailing whitespace so snapshots stay tidy.
_run_for_snapshot() {
    local fixture="$1"
    (
        cd "$SNAPSHOT_TMPDIR" || exit 1
        CC_CLEANLINE_MOCK_NOW=1748269800 \
        HAPPY_MODE=false \
            "${REPO_ROOT}/cc-cleanline.sh" < "${FIXTURES_DIR}/${fixture}.json"
    ) | sed -E $'s/\x1b\\[[0-9;]*[A-Za-z]//g'
}

run_snapshot() {
    local name="$1"
    local actual
    actual=$(_run_for_snapshot "$name")
    assert_snapshot "$name" "$actual"
}

@test "snapshot: fable-5" {
    require_jq
    run_snapshot fable-5
}

@test "snapshot: opus-4-8-basic" {
    require_jq
    run_snapshot opus-4-8-basic
}

@test "snapshot: opus-4-8-1m-context" {
    require_jq
    run_snapshot opus-4-8-1m-context
}

@test "snapshot: sonnet-5" {
    require_jq
    run_snapshot sonnet-5
}

@test "snapshot: opus-4-7-basic" {
    require_jq
    run_snapshot opus-4-7-basic
}

@test "snapshot: opus-4-7-1m-context" {
    require_jq
    run_snapshot opus-4-7-1m-context
}

@test "snapshot: sonnet-4-6" {
    require_jq
    run_snapshot sonnet-4-6
}

@test "snapshot: haiku-4-5" {
    require_jq
    run_snapshot haiku-4-5
}

@test "snapshot: legacy-opus-4-1" {
    require_jq
    run_snapshot legacy-opus-4-1
}

@test "snapshot: with-worktree" {
    require_jq
    run_snapshot with-worktree
}

@test "snapshot: with-vim-mode" {
    require_jq
    run_snapshot with-vim-mode
}

@test "snapshot: with-output-style" {
    require_jq
    run_snapshot with-output-style
}

@test "snapshot: with-pr-context" {
    require_jq
    run_snapshot with-pr-context
}

@test "snapshot: max-effort" {
    require_jq
    run_snapshot max-effort
}

@test "snapshot: high-rate-limit" {
    require_jq
    run_snapshot high-rate-limit
}
