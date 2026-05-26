#!/usr/bin/env bats
# Unit tests for lib/context-display.sh — token formatting, percentage math,
# 1M-window labelling, toggle combinations.

load '../helpers.bash'

setup() {
    source_module "lib/context-display.sh"
}

# --- format_tokens ------------------------------------------------------------

@test "format_tokens: bare number under 1000" {
    [ "$(format_tokens 42)" = '42' ]
}

@test "format_tokens: thousands → 'k' with one decimal" {
    [ "$(format_tokens 1234)" = '1.2k' ]
}

@test "format_tokens: millions → 'M' with one decimal" {
    [ "$(format_tokens 1234000)" = '1.2M' ]
}

@test "format_tokens: exactly 1000 → '1.0k'" {
    [ "$(format_tokens 1000)" = '1.0k' ]
}

@test "format_tokens: empty input → 0" {
    [ "$(format_tokens '')" = '0' ]
}

@test "format_tokens: non-numeric input → 0" {
    [ "$(format_tokens 'abc')" = '0' ]
}

# --- format_percent -----------------------------------------------------------

@test "format_percent: half of total → 50.0" {
    [ "$(format_percent 50 100)" = '50.0' ]
}

@test "format_percent: clamps over 100" {
    [ "$(format_percent 250 200)" = '100.0' ]
}

@test "format_percent: zero total → 0.0 (no division-by-zero)" {
    [ "$(format_percent 50 0)" = '0.0' ]
}

# --- get_context_display: 200k window ----------------------------------------

@test "get_context_display: 50k of 200k → '50.0k · 25.0%'" {
    result=$(get_context_display 50000 200000 '\033[38;5;215m')
    assert_contains "$result" '50.0k · 25.0%'
    assert_not_contains "$result" '(1M)'
}

@test "get_context_display: percent only when SHOW_TOKEN_ABSOLUTE=false" {
    SHOW_TOKEN_ABSOLUTE=false
    SHOW_TOKEN_PERCENT_TOTAL=true
    result=$(get_context_display 50000 200000 'X')
    assert_contains "$result" '25.0%'
    assert_not_contains "$result" '50.0k'
}

@test "get_context_display: absolute only when SHOW_TOKEN_PERCENT_TOTAL=false" {
    SHOW_TOKEN_ABSOLUTE=true
    SHOW_TOKEN_PERCENT_TOTAL=false
    result=$(get_context_display 50000 200000 'X')
    assert_contains "$result" '50.0k'
    assert_not_contains "$result" '%'
}

@test "get_context_display: empty when both toggles off" {
    SHOW_TOKEN_ABSOLUTE=false
    SHOW_TOKEN_PERCENT_TOTAL=false
    result=$(get_context_display 50000 200000 'X')
    [ -z "$result" ]
}

# --- get_context_display: 1M window ------------------------------------------

@test "get_context_display: 320k of 1M → adds (1M) marker" {
    result=$(get_context_display 320000 1000000 'X')
    assert_contains "$result" '320.0k · 32.0% (1M)'
}

# --- get_context_display: edge cases ------------------------------------------

@test "get_context_display: zero input tokens → empty string" {
    result=$(get_context_display 0 200000 'X')
    [ -z "$result" ]
}

@test "get_context_display: null input tokens → empty string" {
    result=$(get_context_display 'null' 200000 'X')
    [ -z "$result" ]
}

@test "get_context_display: missing window_size defaults to 200k" {
    result=$(get_context_display 100000 '' 'X')
    # 100000 / 200000 = 50%
    assert_contains "$result" '50.0%'
}

@test "get_context_display: color is appended after the pipe" {
    result=$(get_context_display 50000 200000 'COLOR_X')
    assert_contains "$result" '|COLOR_X'
}
