#!/usr/bin/env bats
# Integration tests for lib/happy-mode-integration.sh — context classification
# and HAPPY_CTX_* publishing.

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
    # shellcheck disable=SC1090
    source "${REPO_ROOT}/lib/happy-mode-integration.sh"
}

teardown() {
    [[ -n "$XDG_CACHE_HOME" && -d "$XDG_CACHE_HOME" ]] && rm -rf "$XDG_CACHE_HOME"
    unset XDG_CACHE_HOME CC_CLEANLINE_MOCK_NOW CC_CLEANLINE_MOCK_HHMM
    unset worktree_name effort_level exceeds_200k rate_limit_5h_pct output_style_name
    unset HAPPY_CTX_WORKTREE_NAME HAPPY_CTX_EFFORT HAPPY_CTX_EXCEEDS_200K
    unset HAPPY_CTX_RATE_LIMIT_PCT HAPPY_CTX_OUTPUT_STYLE
}

# --- Short-circuits -----------------------------------------------------------

@test "integration: no output when HAPPY_MODE=false" {
    HAPPY_MODE=false
    result=$(trigger_happy_mode_context)
    [ -z "$result" ]
}

@test "integration: missing engine function → silent return" {
    # Defensively unset trigger_happy_mode to simulate missing engine.
    unset -f trigger_happy_mode
    HAPPY_MODE=test
    run trigger_happy_mode_context
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# --- HAPPY_CTX_* publishing ---------------------------------------------------

@test "integration: publishes HAPPY_CTX_* from caller globals" {
    HAPPY_MODE=test
    CC_CLEANLINE_MOCK_HHMM=1500  # daytime, no time-trigger
    worktree_name='curious-feature'
    effort_level='max'
    exceeds_200k='true'
    rate_limit_5h_pct='85'
    output_style_name='Plan'
    trigger_happy_mode_context > /dev/null
    [ "$HAPPY_CTX_WORKTREE_NAME" = 'curious-feature' ]
    [ "$HAPPY_CTX_EFFORT" = 'max' ]
    [ "$HAPPY_CTX_EXCEEDS_200K" = 'true' ]
    [ "$HAPPY_CTX_RATE_LIMIT_PCT" = '85' ]
    [ "$HAPPY_CTX_OUTPUT_STYLE" = 'Plan' ]
}

@test "integration: empty caller globals → empty HAPPY_CTX_*" {
    HAPPY_MODE=test
    CC_CLEANLINE_MOCK_HHMM=1500
    # All caller globals intentionally unset.
    trigger_happy_mode_context > /dev/null
    [ -z "$HAPPY_CTX_WORKTREE_NAME" ]
    [ -z "$HAPPY_CTX_EFFORT" ]
    [ "$HAPPY_CTX_EXCEEDS_200K" = 'false' ]
    [ "$HAPPY_CTX_RATE_LIMIT_PCT" = '0' ]
    [ -z "$HAPPY_CTX_OUTPUT_STYLE" ]
}

# --- End-to-end: achievement fires through the integration --------------------

@test "integration: 'first-trigger' achievement reaches output" {
    HAPPY_MODE=test
    CC_CLEANLINE_MOCK_HHMM=1500
    result=$(trigger_happy_mode_context)
    assert_contains "$result" 'Welcome to Happy Mode'
}

@test "integration: in_worktree achievement reaches output when worktree set" {
    HAPPY_MODE=test
    CC_CLEANLINE_MOCK_HHMM=1500
    worktree_name='curious-feature'
    # Consume first-trigger
    trigger_happy_mode_context > /dev/null
    # Second call should now surface worktree-explorer
    result=$(trigger_happy_mode_context)
    assert_contains "$result" 'Worktree pioneer'
}
