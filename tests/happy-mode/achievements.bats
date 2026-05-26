#!/usr/bin/env bats
# Achievement-state persistence and idempotency.

load '../helpers.bash'

setup() {
    XDG_CACHE_HOME="$(mktemp -d)"
    export XDG_CACHE_HOME
    export CC_CLEANLINE_MOCK_NOW=1748269800
    # shellcheck disable=SC1090
    source "${REPO_ROOT}/cc-cleanline.config.sh"
    # shellcheck disable=SC1090
    source "${REPO_ROOT}/happy-mode/rainbow.sh"
    # shellcheck disable=SC1090
    source "${REPO_ROOT}/happy-mode/engine.sh"
    HAPPY_MODE=true
}

teardown() {
    [[ -n "$XDG_CACHE_HOME" && -d "$XDG_CACHE_HOME" ]] && rm -rf "$XDG_CACHE_HOME"
    unset XDG_CACHE_HOME CC_CLEANLINE_MOCK_NOW
    unset HAPPY_CTX_WORKTREE_NAME HAPPY_CTX_EFFORT HAPPY_CTX_EXCEEDS_200K
    unset HAPPY_CTX_RATE_LIMIT_PCT HAPPY_CTX_OUTPUT_STYLE
}

# --- Achievement storage in XDG cache ----------------------------------------

@test "achievements: 'always' condition fires once for first-trigger" {
    result=$(get_pending_achievement)
    assert_contains "$result" 'Welcome to Happy Mode'
}

@test "achievements: idempotent — same achievement does not fire twice" {
    first=$(get_pending_achievement)
    assert_contains "$first" 'Welcome to Happy Mode'
    # Now the file should contain "first-trigger". A second call should skip
    # this row and either return another newly-earned one or nothing.
    second=$(get_pending_achievement)
    assert_not_contains "$second" 'Welcome to Happy Mode'
}

@test "achievements: state file lives under XDG cache" {
    get_pending_achievement > /dev/null
    [[ -f "${XDG_CACHE_HOME}/cc-cleanline/achievements" ]]
}

@test "achievements: state file lists earned achievement IDs" {
    get_pending_achievement > /dev/null
    grep -Fxq 'first-trigger' "${XDG_CACHE_HOME}/cc-cleanline/achievements"
}

# --- Context-conditional achievements ----------------------------------------

@test "achievements: in_worktree condition fires when worktree context set" {
    # Get the always-trigger out of the way first.
    get_pending_achievement > /dev/null
    export HAPPY_CTX_WORKTREE_NAME='curious-feature'
    result=$(get_pending_achievement)
    assert_contains "$result" 'Worktree pioneer'
}

@test "achievements: effort_max fires when effort context = max" {
    get_pending_achievement > /dev/null  # consume first-trigger
    export HAPPY_CTX_EFFORT='max'
    result=$(get_pending_achievement)
    assert_contains "$result" 'maximum effort'
}

@test "achievements: context_1m fires when exceeds_200k context = true" {
    get_pending_achievement > /dev/null
    export HAPPY_CTX_EXCEEDS_200K='true'
    result=$(get_pending_achievement)
    assert_contains "$result" '1M context unlocked'
}

@test "achievements: long_session fires when rate_limit > 80" {
    get_pending_achievement > /dev/null
    export HAPPY_CTX_RATE_LIMIT_PCT='85'
    result=$(get_pending_achievement)
    assert_contains "$result" 'Endurance coder'
}

@test "achievements: plan_mode fires when output_style = Plan" {
    get_pending_achievement > /dev/null
    export HAPPY_CTX_OUTPUT_STYLE='Plan'
    result=$(get_pending_achievement)
    assert_contains "$result" 'Plan Mode philosopher'
}

@test "achievements: no condition met → empty result" {
    get_pending_achievement > /dev/null  # consume first-trigger
    # Leave all HAPPY_CTX_* unset → no condition can match.
    unset HAPPY_CTX_WORKTREE_NAME HAPPY_CTX_EFFORT HAPPY_CTX_EXCEEDS_200K
    unset HAPPY_CTX_RATE_LIMIT_PCT HAPPY_CTX_OUTPUT_STYLE
    result=$(get_pending_achievement)
    [ -z "$result" ]
}
