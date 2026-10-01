#!/bin/bash
# Model detection module for CC CleanLine.
# Pattern-matches Anthropic model IDs (current + legacy + deprecated) and produces
# the formatted display string with icon, colour, 1M-context badge, effort badge,
# and optional legacy marker.

# Strip [1m] suffix and the trailing date suffix from a model ID — either
# first-party -YYYYMMDD or Vertex AI @YYYYMMDD (claude-haiku-4-5@20251001).
# Returns the normalised ID on stdout.
strip_model_suffixes() {
    local id="$1"
    id="${id%\[1m\]}"
    if [[ "$id" =~ ^(.*)[-@][0-9]{8}$ ]]; then
        id="${BASH_REMATCH[1]}"
    fi
    printf '%s' "$id"
}

# Detect whether a raw model ID carries the [1m] context-window suffix.
has_1m_suffix() {
    [[ "$1" == *\[1m\] ]]
}

# Render the effort-level badge as a 4-star meter.
# Filled stars = effort level; empty stars fill the rest so the width
# stays constant and the level is scannable at a glance.
#   low    →  ☆☆☆☆
#   medium →  ★☆☆☆
#   high   →  ★★☆☆
#   xhigh  →  ★★★☆
#   max    →  ★★★★
render_effort_badge() {
    local level="$1"
    case "$level" in
        low)    printf ' ☆☆☆☆' ;;
        medium) printf ' ★☆☆☆' ;;
        high)   printf ' ★★☆☆' ;;
        xhigh)  printf ' ★★★☆' ;;
        max)    printf ' ★★★★' ;;
        *)      printf '' ;;
    esac
}

# Main: get_model_info <raw_model_id> [display_name] [effort_level]
# Outputs: "<icon> <display>|<color_code>" — the format display-formatter expects.
get_model_info() {
    local raw_id="$1"
    local display_name="${2:-}"
    local effort_level="${3:-}"

    local is_1m=false
    if has_1m_suffix "$raw_id"; then
        is_1m=true
    fi

    local stripped_id
    stripped_id=$(strip_model_suffixes "$raw_id")

    local display icon color
    local is_legacy=false

    # Patterns are end-anchored (*opus-5, not *opus-5*), so a major-only
    # entry never matches a minor release such as opus-5-5 or fable-5-1;
    # current entries are listed first in each family for readability only.
    # Deprecated sonnet-4-5 renders in COLOR_DEPRECATED until it retires on
    # 2026-11-30 — remove its entry then. haiku-4-5 stays current (no
    # deprecation announced, no retirement before 2026-10-15).
    # Retired models (haiku-3-5 retired 2026-02-19, opus-4 / sonnet-4
    # retired 2026-06-15, opus-4-1 retired 2026-08-05) are removed
    # entirely and fall through to the display_name fallback.
    case "$stripped_id" in
        *fable-5-1)  display="Fable 5.1";  icon="✦"; color="$COLOR_FABLE" ;;
        *fable-5)    display="Fable 5";    icon="✦"; color="$COLOR_FABLE_LEGACY";  is_legacy=true ;;
        *opus-5-5)   display="Opus 5.5";   icon="★"; color="$COLOR_OPUS" ;;
        *opus-5)     display="Opus 5";     icon="★"; color="$COLOR_OPUS_LEGACY";  is_legacy=true ;;
        *opus-4-8)   display="Opus 4.8";   icon="★"; color="$COLOR_OPUS_LEGACY";  is_legacy=true ;;
        *opus-4-7)   display="Opus 4.7";   icon="★"; color="$COLOR_OPUS_LEGACY";  is_legacy=true ;;
        *opus-4-6)   display="Opus 4.6";   icon="★"; color="$COLOR_OPUS_LEGACY";  is_legacy=true ;;
        *opus-4-5)   display="Opus 4.5";   icon="★"; color="$COLOR_OPUS_LEGACY";  is_legacy=true ;;
        *sonnet-5-5) display="Sonnet 5.5"; icon="☆"; color="$COLOR_SONNET" ;;
        *sonnet-5)   display="Sonnet 5";   icon="☆"; color="$COLOR_SONNET_LEGACY"; is_legacy=true ;;
        *sonnet-4-6) display="Sonnet 4.6"; icon="☆"; color="$COLOR_SONNET_LEGACY"; is_legacy=true ;;
        *sonnet-4-5) display="Sonnet 4.5"; icon="☆"; color="$COLOR_DEPRECATED";    is_legacy=true ;;
        *haiku-4-5)  display="Haiku 4.5";  icon="✧"; color="$COLOR_HAIKU" ;;
        *)
            display="${display_name:-${stripped_id}}"
            icon="●"
            color="$COLOR_DEFAULT_MODEL"
            ;;
    esac

    if [[ "$is_1m" == true ]] && [[ "${SHOW_1M_BADGE:-true}" == true ]]; then
        display="${display} ¹ᴹ"
    fi

    if [[ "${SHOW_EFFORT_BADGE:-true}" == true ]] && [[ -n "$effort_level" ]] && [[ "$effort_level" != "null" ]]; then
        display="${display}$(render_effort_badge "$effort_level")"
    fi

    if [[ "$is_legacy" == true ]] && [[ "${SHOW_LEGACY_MARKER:-true}" == true ]]; then
        display="${display} ⚠legacy"
    fi

    # Optional happy-mode rainbow effect (very rare).
    if [[ "${HAPPY_MODE:-false}" == "true" || "${HAPPY_MODE:-false}" == "test" ]] && command -v rainbow_text >/dev/null 2>&1; then
        local rainbow_chance=500
        if [[ "${HAPPY_MODE}" == "test" ]]; then
            rainbow_chance=5
        fi
        if (( RANDOM % rainbow_chance == 0 )); then
            display=$(rainbow_text "$display")
            color=""
        fi
    fi

    printf '%s %s|%s\n' "$icon" "$display" "$color"
}

export -f strip_model_suffixes 2>/dev/null || true
export -f has_1m_suffix 2>/dev/null || true
export -f render_effort_badge 2>/dev/null || true
export -f get_model_info 2>/dev/null || true
