#!/usr/bin/env bats
# Unit tests for lib/usage-tracking.sh — cost formatting, rate-limit buckets,
# time-until-reset math with deterministic mocked "now".

load '../helpers.bash'

setup() {
    source_module "lib/usage-tracking.sh"
    # Pin "now" to 2026-05-26 14:30:00 UTC (= 1748269800).
    # All fixture resets_at values are anchored to this baseline.
    export CC_CLEANLINE_MOCK_NOW=1748269800
}

teardown() {
    unset CC_CLEANLINE_MOCK_NOW
}

# --- format_session_cost ------------------------------------------------------

@test "format_session_cost: 1.23 → '\$1.23'" {
    [ "$(format_session_cost 1.23)" = '$1.23' ]
}

@test "format_session_cost: integer → 2 decimals" {
    [ "$(format_session_cost 3)" = '$3.00' ]
}

@test "format_session_cost: very small float rounds correctly" {
    [ "$(format_session_cost 0.005)" = '$0.01' ]
}

@test "format_session_cost: zero → empty" {
    [ -z "$(format_session_cost 0)" ]
}

@test "format_session_cost: null → empty" {
    [ -z "$(format_session_cost 'null')" ]
}

@test "format_session_cost: empty → empty" {
    [ -z "$(format_session_cost '')" ]
}

# --- format_rate_limit --------------------------------------------------------

@test "format_rate_limit: 22% → 'Low'" {
    result=$(format_rate_limit 22.5)
    assert_contains "$result" 'Low'
}

@test "format_rate_limit: 50% → 'Medium'" {
    result=$(format_rate_limit 50)
    assert_contains "$result" 'Medium'
}

@test "format_rate_limit: 82% → exact percentage" {
    result=$(format_rate_limit 82.4)
    assert_contains "$result" '82%'
    assert_not_contains "$result" 'Medium'
}

@test "format_rate_limit: 93% → 'High 93%'" {
    result=$(format_rate_limit 93)
    assert_contains "$result" 'High 93%'
}

@test "format_rate_limit: bucket boundary at 40% → Medium" {
    result=$(format_rate_limit 40)
    assert_contains "$result" 'Medium'
}

@test "format_rate_limit: bucket boundary at 75% → exact percent" {
    result=$(format_rate_limit 75)
    assert_contains "$result" '75%'
}

@test "format_rate_limit: bucket boundary at 90% → High" {
    result=$(format_rate_limit 90)
    assert_contains "$result" 'High'
}

@test "format_rate_limit: empty input → empty output" {
    [ -z "$(format_rate_limit '')" ]
}

@test "format_rate_limit: null → empty output" {
    [ -z "$(format_rate_limit 'null')" ]
}

# --- format_time_until_reset --------------------------------------------------

@test "format_time_until_reset: 4h 30m away → '4h 30m'" {
    # MOCK_NOW + 4h 30m = 1748269800 + 16200 = 1748286000
    [ "$(format_time_until_reset 1748286000)" = '4h 30m' ]
}

@test "format_time_until_reset: exactly 1h away → '1h'" {
    # MOCK_NOW + 3600 = 1748273400
    [ "$(format_time_until_reset 1748273400)" = '1h' ]
}

@test "format_time_until_reset: 15m away → '15m'" {
    # MOCK_NOW + 900 = 1748270700
    [ "$(format_time_until_reset 1748270700)" = '15m' ]
}

@test "format_time_until_reset: 30s away → '<1m'" {
    [ "$(format_time_until_reset 1748269830)" = '<1m' ]
}

@test "format_time_until_reset: past reset → empty" {
    [ -z "$(format_time_until_reset 1748269000)" ]
}

@test "format_time_until_reset: invalid input → empty" {
    [ -z "$(format_time_until_reset 'not-a-number')" ]
}

@test "format_time_until_reset: null → empty" {
    [ -z "$(format_time_until_reset 'null')" ]
}

# --- integration via real fixture ---------------------------------------------

@test "fixture opus-4-7-basic: 22.5% rate limit produces 'Low'" {
    require_jq
    pct=$(jq -r '.rate_limits.five_hour.used_percentage' tests/fixtures/opus-4-7-basic.json)
    result=$(format_rate_limit "$pct")
    assert_contains "$result" 'Low'
}

@test "fixture high-rate-limit: 93% produces 'High'" {
    require_jq
    pct=$(jq -r '.rate_limits.five_hour.used_percentage' tests/fixtures/high-rate-limit.json)
    result=$(format_rate_limit "$pct")
    assert_contains "$result" 'High'
}

@test "fixture high-rate-limit: reset at MOCK_NOW + 15m → '15m'" {
    require_jq
    reset=$(jq -r '.rate_limits.five_hour.resets_at' tests/fixtures/high-rate-limit.json)
    [ "$(format_time_until_reset "$reset")" = '15m' ]
}
