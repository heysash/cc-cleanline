#!/bin/bash
# Usage / cost tracking module for CC CleanLine.
# Pure formatters around the native Claude Code statusline fields:
#   - cost.total_cost_usd
#   - rate_limits.five_hour.used_percentage
#   - rate_limits.five_hour.resets_at  (Unix epoch seconds)
#
# No external commands (no ccusage, no bunx/npx) — everything is local.

# Current time (overridable via CC_CLEANLINE_MOCK_NOW for deterministic tests).
_usage_now() {
    if [[ -n "${CC_CLEANLINE_MOCK_NOW:-}" ]]; then
        printf '%s' "$CC_CLEANLINE_MOCK_NOW"
    else
        date +%s
    fi
}

# Format a session cost (USD float) as "$X.XX". Empty string for missing / zero.
format_session_cost() {
    local cost="$1"
    if [[ -z "$cost" ]] || [[ "$cost" = "null" ]]; then
        printf ''
        return
    fi
    # awk handles float parsing reliably across bash versions.
    awk -v c="$cost" 'BEGIN { if (c+0 <= 0) exit 1; printf "$%.2f", c }' 2>/dev/null || printf ''
}

# Format the 5h rate-limit status with severity-appropriate color.
# Input: percent used (float 0..100).
# Output: "<icon> 5h Limit: <label>|<color>"
#   < 40 %        → green,   "Low"
#   40..< 75 %    → orange,  "Medium"
#   75..< 90 %    → orange,  exact percentage
#   >= 90 %       → red,     "High XX%"
# Empty string when input missing.
format_rate_limit() {
    local pct="$1"
    if [[ -z "$pct" ]] || [[ "$pct" = "null" ]]; then
        printf ''
        return
    fi

    local pct_int
    pct_int=$(awk -v p="$pct" 'BEGIN { printf "%d", p }')

    local label color
    if [[ "$pct_int" -lt 40 ]]; then
        label="Low"
        color="$COLOR_ACTIVE_STATUS"
    elif [[ "$pct_int" -lt 75 ]]; then
        label="Medium"
        color="$COLOR_ORANGE"
    elif [[ "$pct_int" -lt 90 ]]; then
        label="${pct_int}%"
        color="$COLOR_ORANGE"
    else
        label="High ${pct_int}%"
        color="$COLOR_RED"
    fi

    printf '%s 5h Limit: %s|%s' "${ICON_ACTIVE}" "$label" "$color"
}

# Format the time-until-reset relative to now.
# Input: reset epoch seconds (Unix timestamp).
# Output: "Xh Ym" / "Xh" / "Ym" / "<1m" — or empty if input invalid / past.
format_time_until_reset() {
    local reset_at="$1"
    if [[ -z "$reset_at" ]] || [[ "$reset_at" = "null" ]] || ! [[ "$reset_at" =~ ^[0-9]+$ ]]; then
        printf ''
        return
    fi

    local now diff hours minutes
    now=$(_usage_now)
    diff=$((reset_at - now))

    if [[ "$diff" -le 0 ]]; then
        printf ''
        return
    fi

    if [[ "$diff" -lt 60 ]]; then
        printf '<1m'
        return
    fi

    hours=$((diff / 3600))
    minutes=$(( (diff % 3600) / 60 ))

    if [[ "$hours" -gt 0 ]] && [[ "$minutes" -gt 0 ]]; then
        printf '%dh %dm' "$hours" "$minutes"
    elif [[ "$hours" -gt 0 ]]; then
        printf '%dh' "$hours"
    else
        printf '%dm' "$minutes"
    fi
}

export -f format_session_cost 2>/dev/null || true
export -f format_rate_limit 2>/dev/null || true
export -f format_time_until_reset 2>/dev/null || true
