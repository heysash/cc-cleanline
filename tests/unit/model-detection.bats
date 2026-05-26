#!/usr/bin/env bats
# Unit tests for lib/model-detection.sh — pattern matching, suffix stripping,
# badge composition, legacy markers.

load '../helpers.bash'

setup() {
    source_module "lib/model-detection.sh"
    # Disable happy mode so the rainbow hook is never triggered in tests.
    HAPPY_MODE=false
}

# --- strip_model_suffixes -----------------------------------------------------

@test "strip_model_suffixes: removes [1m] suffix" {
    [ "$(strip_model_suffixes 'claude-opus-4-7[1m]')" = 'claude-opus-4-7' ]
}

@test "strip_model_suffixes: removes 8-digit date suffix" {
    [ "$(strip_model_suffixes 'claude-haiku-4-5-20251001')" = 'claude-haiku-4-5' ]
}

@test "strip_model_suffixes: removes both [1m] and date" {
    [ "$(strip_model_suffixes 'claude-opus-4-7-20260301[1m]')" = 'claude-opus-4-7' ]
}

@test "strip_model_suffixes: leaves bare ID unchanged" {
    [ "$(strip_model_suffixes 'claude-sonnet-4-6')" = 'claude-sonnet-4-6' ]
}

@test "strip_model_suffixes: does NOT strip a single trailing digit" {
    # Crucial — would otherwise eat the minor version (e.g. "opus-4-1" -> "opus-4")
    [ "$(strip_model_suffixes 'claude-opus-4-1')" = 'claude-opus-4-1' ]
}

# --- has_1m_suffix ------------------------------------------------------------

@test "has_1m_suffix: detects [1m] suffix" {
    run has_1m_suffix 'claude-opus-4-7[1m]'
    [ "$status" -eq 0 ]
}

@test "has_1m_suffix: does not detect on bare ID" {
    run has_1m_suffix 'claude-opus-4-7'
    [ "$status" -ne 0 ]
}

# --- render_effort_badge ------------------------------------------------------

@test "render_effort_badge: low → ' ☆☆☆☆' (all empty stars)" {
    [ "$(render_effort_badge low)" = ' ☆☆☆☆' ]
}

@test "render_effort_badge: medium → ' ★☆☆☆' (1 filled)" {
    [ "$(render_effort_badge medium)" = ' ★☆☆☆' ]
}

@test "render_effort_badge: high → ' ★★☆☆' (2 filled)" {
    [ "$(render_effort_badge high)" = ' ★★☆☆' ]
}

@test "render_effort_badge: xhigh → ' ★★★☆' (3 filled)" {
    [ "$(render_effort_badge xhigh)" = ' ★★★☆' ]
}

@test "render_effort_badge: max → ' ★★★★' (all filled)" {
    [ "$(render_effort_badge max)" = ' ★★★★' ]
}

@test "render_effort_badge: badge width stays constant across all levels" {
    # Same number of stars (4) regardless of fill level → constant width
    # makes the badge scannable without counting.
    local lvl
    for lvl in low medium high xhigh max; do
        local badge
        badge=$(render_effort_badge "$lvl")
        # Star runes are 3 bytes each in UTF-8 → 4 stars + leading space = 13 bytes
        [ "${#badge}" -eq 13 ]
    done
}

@test "render_effort_badge: unknown level → empty string" {
    [ "$(render_effort_badge weird)" = '' ]
}

@test "render_effort_badge: empty input → empty string" {
    [ "$(render_effort_badge '')" = '' ]
}

# --- get_model_info: current generation models --------------------------------

@test "get_model_info: Opus 4.7 → '★ Opus 4.7|<color>'" {
    result=$(get_model_info 'claude-opus-4-7')
    assert_contains "$result" '★ Opus 4.7'
    assert_not_contains "$result" 'legacy'
}

@test "get_model_info: Opus 4.7 with [1m] → adds ¹ᴹ badge" {
    result=$(get_model_info 'claude-opus-4-7[1m]')
    assert_contains "$result" '★ Opus 4.7 ¹ᴹ'
}

@test "get_model_info: Sonnet 4.6 → '☆ Sonnet 4.6'" {
    result=$(get_model_info 'claude-sonnet-4-6')
    assert_contains "$result" '☆ Sonnet 4.6'
    assert_not_contains "$result" 'legacy'
}

@test "get_model_info: Haiku 4.5 with date suffix → '✧ Haiku 4.5'" {
    result=$(get_model_info 'claude-haiku-4-5-20251001')
    assert_contains "$result" '✧ Haiku 4.5'
    assert_not_contains "$result" 'legacy'
}

# --- get_model_info: legacy models --------------------------------------------

@test "get_model_info: Opus 4.6 → legacy marker" {
    result=$(get_model_info 'claude-opus-4-6')
    assert_contains "$result" 'Opus 4.6'
    assert_contains "$result" 'legacy'
}

@test "get_model_info: Opus 4.1 with date → legacy marker" {
    result=$(get_model_info 'claude-opus-4-1-20250805')
    assert_contains "$result" 'Opus 4.1'
    assert_contains "$result" 'legacy'
}

@test "get_model_info: Sonnet 4.5 → legacy marker" {
    result=$(get_model_info 'claude-sonnet-4-5-20250929')
    assert_contains "$result" 'Sonnet 4.5'
    assert_contains "$result" 'legacy'
}

# --- get_model_info: deprecated / fallback ------------------------------------

@test "get_model_info: bare Opus 4 → deprecated" {
    result=$(get_model_info 'claude-opus-4-20250514')
    assert_contains "$result" 'Opus 4'
    assert_contains "$result" 'legacy'
}

@test "get_model_info: unknown ID → display_name fallback with neutral icon" {
    result=$(get_model_info 'claude-future-model-99' 'Future99')
    assert_contains "$result" 'Future99'
    assert_contains "$result" '●'
}

@test "get_model_info: unknown ID without display_name → uses stripped ID" {
    result=$(get_model_info 'claude-mystery-1-0')
    assert_contains "$result" 'claude-mystery-1-0'
}

# --- get_model_info: effort badges --------------------------------------------

@test "get_model_info: appends effort star meter when level given" {
    result=$(get_model_info 'claude-opus-4-7' 'Opus' 'max')
    assert_contains "$result" '★★★★'
}

@test "get_model_info: effort 'high' renders as '★★☆☆'" {
    result=$(get_model_info 'claude-opus-4-7' 'Opus' 'high')
    assert_contains "$result" 'Opus 4.7 ★★☆☆'
}

@test "get_model_info: effort badge skipped when SHOW_EFFORT_BADGE=false" {
    SHOW_EFFORT_BADGE=false
    result=$(get_model_info 'claude-opus-4-7' 'Opus' 'max')
    # The Opus icon is also '★', so check for the badge-specific 4-star run.
    assert_not_contains "$result" '★★'
}

# --- get_model_info: regression guards ----------------------------------------

@test "guard: opus-4-7 case does NOT swallow a hypothetical opus-4-70" {
    # Without the end-anchored pattern, *opus-4-7* would match opus-4-70 wrongly.
    result=$(get_model_info 'claude-opus-4-70')
    assert_not_contains "$result" 'Opus 4.7'
}

@test "guard: opus-4-1 case does NOT swallow a hypothetical opus-4-10" {
    result=$(get_model_info 'claude-opus-4-10')
    assert_not_contains "$result" 'Opus 4.1'
}
