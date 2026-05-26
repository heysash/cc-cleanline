#!/bin/bash
# Context-window display module for CC CleanLine.
# Consumes native fields from the Claude Code statusline JSON
# (context_window.total_input_tokens, context_window.context_window_size)
# and renders a compact "<tokens> · <percent>[ (1M)]" string.
#
# Replaces the legacy JSONL-transcript parser — no file IO, no caching needed.

# Format a token count with k / M suffixes.
# 0..999       → "123"
# 1000..999999 → "12.3k"
# >= 1_000_000 → "1.2M"
format_tokens() {
    local count="$1"
    if [[ -z "$count" ]] || ! [[ "$count" =~ ^[0-9]+$ ]]; then
        printf '0'
        return
    fi
    if [[ "$count" -ge 1000000 ]]; then
        awk -v n="$count" 'BEGIN { printf "%.1fM", n / 1000000 }'
    elif [[ "$count" -ge 1000 ]]; then
        awk -v n="$count" 'BEGIN { printf "%.1fk", n / 1000 }'
    else
        printf '%s' "$count"
    fi
}

# Format percentage with one decimal place, clamped to [0, 100].
format_percent() {
    local used="$1"
    local total="$2"
    if [[ -z "$total" ]] || [[ "$total" -le 0 ]]; then
        printf '0.0'
        return
    fi
    awk -v u="$used" -v t="$total" 'BEGIN {
        p = (u / t) * 100
        if (p > 100) p = 100
        if (p < 0) p = 0
        printf "%.1f", p
    }'
}

# get_context_display <input_tokens> <context_window_size> <model_color>
# Outputs: "<formatted>|<color>" where <formatted> is e.g.
#   "59.0k · 29.5%"          (200k window)
#   "320.0k · 32.0% (1M)"    (1M window)
# Empty string (and no color) when input is missing / unparseable.
get_context_display() {
    local input_tokens="${1:-0}"
    local window_size="${2:-200000}"
    local model_color="${3:-}"

    # Default to 200k if window_size missing / null.
    if [[ -z "$window_size" ]] || [[ "$window_size" = "null" ]] || [[ "$window_size" -le 0 ]]; then
        window_size=200000
    fi

    # No data → no output.
    if [[ -z "$input_tokens" ]] || [[ "$input_tokens" = "null" ]] || [[ "$input_tokens" -le 0 ]]; then
        printf ''
        return
    fi

    local parts=()
    if [[ "${SHOW_TOKEN_ABSOLUTE:-true}" == true ]]; then
        parts+=("$(format_tokens "$input_tokens")")
    fi
    if [[ "${SHOW_TOKEN_PERCENT_TOTAL:-true}" == true ]]; then
        local pct
        pct=$(format_percent "$input_tokens" "$window_size")
        if [[ "$window_size" -ge 1000000 ]]; then
            parts+=("${pct}% (1M)")
        else
            parts+=("${pct}%")
        fi
    fi

    if [[ ${#parts[@]} -eq 0 ]]; then
        printf ''
        return
    fi

    local joined="${parts[0]}"
    local i
    for (( i = 1; i < ${#parts[@]}; i++ )); do
        joined="${joined} · ${parts[$i]}"
    done

    printf '%s|%s' "$joined" "$model_color"
}

export -f format_tokens 2>/dev/null || true
export -f format_percent 2>/dev/null || true
export -f get_context_display 2>/dev/null || true
