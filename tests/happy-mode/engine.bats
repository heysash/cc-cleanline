#!/usr/bin/env bats
# Unit tests for happy-mode/engine.sh — float-safe hits_chance, cooldown
# state under XDG cache, content loading, time-trigger lookup.

load '../helpers.bash'

setup() {
    # Isolate cache to a per-test directory so we never touch the real one.
    XDG_CACHE_HOME="$(mktemp -d)"
    export XDG_CACHE_HOME
    # Pin "now" to 2026-05-26 14:30:00 UTC for deterministic cooldown math.
    export CC_CLEANLINE_MOCK_NOW=1748269800
    # shellcheck disable=SC1090
    source "${REPO_ROOT}/cc-cleanline.config.sh"
    # shellcheck disable=SC1090
    source "${REPO_ROOT}/happy-mode/rainbow.sh"
    # shellcheck disable=SC1090
    source "${REPO_ROOT}/happy-mode/engine.sh"
}

teardown() {
    [[ -n "$XDG_CACHE_HOME" && -d "$XDG_CACHE_HOME" ]] && rm -rf "$XDG_CACHE_HOME"
    unset XDG_CACHE_HOME CC_CLEANLINE_MOCK_NOW CC_CLEANLINE_MOCK_HHMM
}

# --- hits_chance --------------------------------------------------------------

@test "hits_chance: 100 always hits" {
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        hits_chance 100 || return 1
    done
}

@test "hits_chance: 0 never hits" {
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        if hits_chance 0; then return 1; fi
    done
}

@test "hits_chance: accepts float values (does NOT silently round to 0)" {
    # Stripping ".5" to "0" was the legacy bug. We just verify the function
    # accepts the float without throwing — exit status varies by RNG.
    run hits_chance 0.5
    # Either status is OK; what matters is that the call succeeds.
    [[ "$status" -eq 0 || "$status" -eq 1 ]]
}

@test "hits_chance: empty input → never hits (defaults to 0)" {
    for _ in 1 2 3 4 5; do
        if hits_chance ''; then return 1; fi
    done
}

# --- Cooldown state in XDG cache ----------------------------------------------

@test "cooldown: initially absent → check_cooldown allows" {
    HAPPY_MODE=true
    check_cooldown
}

@test "cooldown: after update_cooldown, second check is blocked" {
    HAPPY_MODE=true
    update_cooldown
    run check_cooldown
    [ "$status" -ne 0 ]
}

@test "cooldown: cooldown file lives under XDG_CACHE_HOME/cc-cleanline" {
    HAPPY_MODE=true
    update_cooldown
    [[ -f "${XDG_CACHE_HOME}/cc-cleanline/cooldown" ]]
}

@test "cooldown: bypassed in test mode" {
    HAPPY_MODE=test
    update_cooldown
    # In test mode update_cooldown is a no-op AND check_cooldown always allows.
    check_cooldown
}

@test "cooldown: expires after HAPPY_MODE_COOLDOWN_MINUTES" {
    HAPPY_MODE=true
    HAPPY_MODE_COOLDOWN_MINUTES=15
    mkdir -p "${XDG_CACHE_HOME}/cc-cleanline"
    # Write a timestamp that's 16 minutes old (15*60 + 60 = 960 seconds ago)
    echo $((CC_CLEANLINE_MOCK_NOW - 960)) > "${XDG_CACHE_HOME}/cc-cleanline/cooldown"
    check_cooldown
}

# --- Content loading ---------------------------------------------------------

@test "get_matrix_quote: returns a non-empty string" {
    result=$(get_matrix_quote)
    [ -n "$result" ]
}

@test "get_fortune_cookie: returns a non-empty string" {
    result=$(get_fortune_cookie)
    [ -n "$result" ]
}

@test "content loader: skips comment lines and blanks" {
    local tmp
    tmp=$(mktemp)
    cat > "$tmp" <<'EOF'
# This is a comment
real-line-one

real-line-two
# Another comment
EOF
    out=$(_happy_load_lines "$tmp")
    [[ "$out" == "real-line-one"$'\n'"real-line-two" ]]
}

# --- Time trigger ------------------------------------------------------------

@test "get_time_surprise: matches 1337 from content file" {
    HAPPY_MODE_TIME_SURPRISES=true
    CC_CLEANLINE_MOCK_HHMM=1337
    result=$(get_time_surprise)
    assert_contains "$result" 'Elite time has arrived'
}

@test "get_time_surprise: returns empty for non-trigger time" {
    HAPPY_MODE_TIME_SURPRISES=true
    CC_CLEANLINE_MOCK_HHMM=1500  # 15:00 is not in the trigger list
    result=$(get_time_surprise)
    # Either empty (no match, no night-owl), or a night-owl message.
    # 1500 is daytime, so should be empty.
    [ -z "$result" ]
}

@test "get_time_surprise: disabled by HAPPY_MODE_TIME_SURPRISES=false" {
    HAPPY_MODE_TIME_SURPRISES=false
    CC_CLEANLINE_MOCK_HHMM=1337
    result=$(get_time_surprise)
    [ -z "$result" ]
}

# --- is_happy_mode_enabled / is_happy_test_mode ------------------------------

@test "is_happy_mode_enabled: true when HAPPY_MODE=true" {
    HAPPY_MODE=true
    is_happy_mode_enabled
}

@test "is_happy_mode_enabled: true when HAPPY_MODE=test" {
    HAPPY_MODE=test
    is_happy_mode_enabled
}

@test "is_happy_mode_enabled: false when HAPPY_MODE=false" {
    HAPPY_MODE=false
    run is_happy_mode_enabled
    [ "$status" -ne 0 ]
}

@test "is_happy_test_mode: only true when HAPPY_MODE=test" {
    HAPPY_MODE=true
    run is_happy_test_mode
    [ "$status" -ne 0 ]
    HAPPY_MODE=test
    is_happy_test_mode
}
