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
    # Same star count (4) regardless of fill level → constant width
    # makes the badge scannable without counting. We compare widths to each
    # other rather than to an absolute number, because `${#var}` counts
    # characters or bytes depending on the active locale (UTF-8 → chars,
    # POSIX/C → bytes), and that varies between dev machine and CI.
    local first_len="" lvl badge
    for lvl in low medium high xhigh max; do
        badge=$(render_effort_badge "$lvl")
        if [[ -z "$first_len" ]]; then
            first_len="${#badge}"
            continue
        fi
        if [ "${#badge}" -ne "$first_len" ]; then
            echo "Inconsistent badge width: '$lvl' is ${#badge}, expected $first_len" >&2
            return 1
        fi
    done
}

@test "render_effort_badge: unknown level → empty string" {
    [ "$(render_effort_badge weird)" = '' ]
}

@test "render_effort_badge: empty input → empty string" {
    [ "$(render_effort_badge '')" = '' ]
}

# --- get_model_info: current generation models --------------------------------

@test "get_model_info: Fable 5.1 → '✦ Fable 5.1' (current top tier)" {
    result=$(get_model_info 'claude-fable-5-1')
    assert_contains "$result" '✦ Fable 5.1'
    assert_not_contains "$result" 'legacy'
}

@test "get_model_info: Opus 5 → '★ Opus 5|<color>'" {
    result=$(get_model_info 'claude-opus-5')
    assert_contains "$result" '★ Opus 5'
    assert_not_contains "$result" 'legacy'
}

@test "get_model_info: Opus 5 with [1m] → adds ¹ᴹ badge" {
    result=$(get_model_info 'claude-opus-5[1m]')
    assert_contains "$result" '★ Opus 5 ¹ᴹ'
    assert_not_contains "$result" 'legacy'
}

@test "get_model_info: Sonnet 5 → '☆ Sonnet 5'" {
    result=$(get_model_info 'claude-sonnet-5')
    assert_contains "$result" '☆ Sonnet 5'
    assert_not_contains "$result" 'legacy'
}

@test "get_model_info: Haiku 4.5 with date suffix → '✧ Haiku 4.5'" {
    result=$(get_model_info 'claude-haiku-4-5-20251001')
    assert_contains "$result" '✧ Haiku 4.5'
    assert_not_contains "$result" 'legacy'
}

# --- get_model_info: legacy models --------------------------------------------

@test "get_model_info: Fable 5 → legacy marker (demoted by Fable 5.1)" {
    result=$(get_model_info 'claude-fable-5')
    assert_contains "$result" '✦ Fable 5'
    assert_contains "$result" 'legacy'
}

@test "get_model_info: Opus 4.8 → legacy marker (demoted by Opus 5)" {
    result=$(get_model_info 'claude-opus-4-8')
    assert_contains "$result" '★ Opus 4.8'
    assert_contains "$result" 'legacy'
}

@test "get_model_info: Opus 4.8 with [1m] → keeps ¹ᴹ badge alongside legacy" {
    result=$(get_model_info 'claude-opus-4-8[1m]')
    assert_contains "$result" '★ Opus 4.8 ¹ᴹ'
    assert_contains "$result" 'legacy'
}

@test "get_model_info: Opus 4.7 → legacy marker" {
    result=$(get_model_info 'claude-opus-4-7')
    assert_contains "$result" 'Opus 4.7'
    assert_contains "$result" 'legacy'
}

@test "get_model_info: Opus 4.7 with [1m] → keeps ¹ᴹ badge alongside legacy" {
    result=$(get_model_info 'claude-opus-4-7[1m]')
    assert_contains "$result" 'Opus 4.7 ¹ᴹ'
    assert_contains "$result" 'legacy'
}

@test "get_model_info: Opus 4.6 → legacy marker" {
    result=$(get_model_info 'claude-opus-4-6')
    assert_contains "$result" 'Opus 4.6'
    assert_contains "$result" 'legacy'
}

@test "get_model_info: Opus 4.5 with date → legacy marker" {
    result=$(get_model_info 'claude-opus-4-5-20251101')
    assert_contains "$result" 'Opus 4.5'
    assert_contains "$result" 'legacy'
}

@test "get_model_info: Sonnet 4.6 → legacy marker (demoted by Sonnet 5)" {
    result=$(get_model_info 'claude-sonnet-4-6')
    assert_contains "$result" 'Sonnet 4.6'
    assert_contains "$result" 'legacy'
}

@test "get_model_info: Sonnet 4.5 → legacy marker" {
    result=$(get_model_info 'claude-sonnet-4-5-20250929')
    assert_contains "$result" 'Sonnet 4.5'
    assert_contains "$result" 'legacy'
}

# --- get_model_info: retired / fallback ---------------------------------------

@test "get_model_info: retired Opus 4.1 → fallback (case entry removed)" {
    # Anthropic retired Opus 4.1 on 2026-08-05; the dedicated case entry
    # is gone, so the ID renders via the display_name fallback instead.
    result=$(get_model_info 'claude-opus-4-1-20250805' 'Opus')
    assert_contains "$result" '●'
    assert_not_contains "$result" 'Opus 4.1'
}

@test "get_model_info: retired Opus 4 → fallback (case entry removed)" {
    # Retired 2026-06-15 together with Sonnet 4.
    result=$(get_model_info 'claude-opus-4-20250514' 'Opus')
    assert_contains "$result" '●'
    assert_not_contains "$result" '★'
}

@test "get_model_info: retired Sonnet 4 → fallback (case entry removed)" {
    result=$(get_model_info 'claude-sonnet-4-20250514' 'Sonnet')
    assert_contains "$result" '●'
    assert_not_contains "$result" '☆'
}

@test "get_model_info: retired Haiku 3.5 → fallback (case entry removed)" {
    # Anthropic retired Haiku 3.5 on 2026-02-19; the dedicated case entry
    # is gone, so the ID renders via the display_name fallback instead.
    result=$(get_model_info 'claude-haiku-3-5' 'Haiku 3.5')
    assert_contains "$result" '●'
    assert_not_contains "$result" '✧'
}

@test "get_model_info: Mythos 5.1 → fallback (out of scope, never mapped)" {
    # Mythos is a Project-Glasswing-only model and deliberately has no case
    # entry. This guard keeps it from ever being folded into the Fable tier.
    result=$(get_model_info 'claude-mythos-5-1' 'Mythos')
    assert_contains "$result" '●'
    assert_not_contains "$result" '✦'
    assert_not_contains "$result" 'Fable'
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
    result=$(get_model_info 'claude-opus-5' 'Opus' 'max')
    assert_contains "$result" '★★★★'
}

@test "get_model_info: effort 'high' renders as '★★☆☆'" {
    result=$(get_model_info 'claude-opus-5' 'Opus' 'high')
    assert_contains "$result" 'Opus 5 ★★☆☆'
}

@test "get_model_info: effort badge skipped when SHOW_EFFORT_BADGE=false" {
    SHOW_EFFORT_BADGE=false
    result=$(get_model_info 'claude-opus-5' 'Opus' 'max')
    # The Opus icon is also '★', so check for the badge-specific 4-star run.
    assert_not_contains "$result" '★★'
}

# --- get_model_info: regression guards ----------------------------------------

@test "guard: opus-4-7 case does NOT swallow a hypothetical opus-4-70" {
    # Without the end-anchored pattern, *opus-4-7* would match opus-4-70 wrongly.
    result=$(get_model_info 'claude-opus-4-70')
    assert_not_contains "$result" 'Opus 4.7'
}

@test "guard: a hypothetical opus-4-10 never renders as Opus 4.1" {
    # *opus-4-1 was removed when Anthropic retired Opus 4.1 (2026-08-05).
    # The guard stays so the expectation is pinned should the pattern return.
    result=$(get_model_info 'claude-opus-4-10')
    assert_not_contains "$result" 'Opus 4.1'
}

@test "guard: opus-4-8 case does NOT swallow a hypothetical opus-4-80" {
    result=$(get_model_info 'claude-opus-4-80')
    assert_not_contains "$result" 'Opus 4.8'
}

@test "guard: opus-5 case does NOT swallow a hypothetical opus-5-5" {
    # *opus-5 is a major-only pattern; a future opus-5-5 minor must get its
    # own entry instead of collapsing into the major.
    result=$(get_model_info 'claude-opus-5-5')
    assert_not_contains "$result" 'Opus 5'
}

@test "guard: opus-5 case does NOT swallow a hypothetical opus-50" {
    result=$(get_model_info 'claude-opus-50')
    assert_not_contains "$result" 'Opus 5'
}

@test "guard: opus-4-5 stays Opus 4.5 and never collapses into Opus 5" {
    # Minor entries must win over the *opus-5 major-only pattern.
    result=$(get_model_info 'claude-opus-4-5')
    assert_contains "$result" 'Opus 4.5'
    assert_not_contains "$result" 'Opus 5'
}

@test "guard: sonnet-5 case does NOT swallow a hypothetical sonnet-5-5" {
    # *sonnet-5 is a major-only pattern; a future sonnet-5-5 minor must
    # get its own entry instead of collapsing into the major.
    result=$(get_model_info 'claude-sonnet-5-5')
    assert_not_contains "$result" 'Sonnet 5'
}

@test "guard: sonnet-5 case does NOT swallow a hypothetical sonnet-50" {
    result=$(get_model_info 'claude-sonnet-50')
    assert_not_contains "$result" 'Sonnet 5'
}

@test "guard: fable-5-1 case does NOT swallow a hypothetical fable-5-10" {
    result=$(get_model_info 'claude-fable-5-10')
    assert_not_contains "$result" 'Fable 5.1'
}

@test "guard: fable-5-1 is current and never picks up the Fable 5 legacy flag" {
    # The reverse direction of the *fable-5-1 / *fable-5 pair.
    result=$(get_model_info 'claude-fable-5-1')
    assert_contains "$result" 'Fable 5.1'
    assert_not_contains "$result" 'legacy'
}

@test "guard: fable-5 case does NOT swallow a hypothetical fable-50" {
    result=$(get_model_info 'claude-fable-50')
    assert_not_contains "$result" 'Fable 5'
}
