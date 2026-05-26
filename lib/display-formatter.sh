#!/bin/bash
# Display formatter for CC CleanLine.
# Composes the final status line — 3 core lines always, plus an adaptive
# 4th (worktree) and 5th (extras: output style / vim mode / PR) line that
# only appear when their data is present.

# Render a directory path, honouring SHOW_FULL_PATH.
format_directory_path() {
    local current_dir="$1"
    if [[ "${SHOW_FULL_PATH:-false}" == true ]]; then
        printf '%s' "$current_dir"
    else
        printf './%s' "$(basename "$current_dir")"
    fi
}

# Join a status segment with its ANSI color, falling back to a bare text
# segment when no color is provided (e.g. rainbow output supplies its own).
_render_segment() {
    local text="$1"
    local color="$2"
    if [[ -n "$color" ]]; then
        printf '%b%s%b' "$color" "$text" "$COLOR_RESET"
    else
        printf '%s' "$text"
    fi
}

# Print line 1: git status + directory.
_print_line1() {
    local git_status="$1" git_color="$2" dir_path="$3"
    printf '%b ' "$(_render_segment "$git_status" "$git_color")"
    printf '%b\n' "$(_render_segment "▶ ${dir_path}" "$COLOR_NEUTRAL_TEXT")"
}

# Print line 2: model + context + time-until-reset.
# context_display and time_until_reset are optional — segments are skipped
# when empty.
_print_line2() {
    local model_info="$1" model_color="$2"
    local context_display="$3" context_color="$4"
    local time_until_reset="$5"

    local line
    line="$(_render_segment "$model_info" "$model_color")"
    if [[ -n "$context_display" ]]; then
        line="${line} $(_render_segment "$context_display" "$context_color")"
    fi
    if [[ -n "$time_until_reset" ]]; then
        line="${line} $(_render_segment "⏱ Reset ${time_until_reset}" "$COLOR_NEUTRAL_TEXT")"
    fi
    printf '%b\n' "$line"
}

# Print line 3: rate-limit status + session cost.
# Either segment may be empty; the line is suppressed entirely if both are.
_print_line3() {
    local rate_limit_status="$1" rate_limit_color="$2"
    local session_cost="$3"

    if [[ -z "$rate_limit_status" ]] && [[ -z "$session_cost" ]]; then
        return
    fi

    local line='  '  # two-space indent matches the legacy layout
    if [[ -n "$rate_limit_status" ]]; then
        line="${line}$(_render_segment "$rate_limit_status" "$rate_limit_color")"
    fi
    if [[ -n "$rate_limit_status" ]] && [[ -n "$session_cost" ]]; then
        line="${line} $(_render_segment "·" "$COLOR_NEUTRAL_TEXT") "
    fi
    if [[ -n "$session_cost" ]]; then
        line="${line}$(_render_segment "${session_cost} session" "$COLOR_NEUTRAL_TEXT")"
    fi
    printf '%b\n' "$line"
}

# Print line 4 (optional): worktree info.
_print_line4() {
    local worktree_text="$1" worktree_color="$2"
    if [[ -n "$worktree_text" ]]; then
        printf '%b\n' "$(_render_segment "$worktree_text" "$worktree_color")"
    fi
}

# Print line 5 (optional): output style / vim / PR / version.
_print_line5() {
    local extras_text="$1" extras_color="$2"
    if [[ -n "$extras_text" ]]; then
        printf '%b\n' "$(_render_segment "$extras_text" "$extras_color")"
    fi
}

# output_status_line — argument order:
#   1  git_status            2  git_color
#   3  dir_path
#   4  model_info            5  model_color
#   6  context_display       7  context_color
#   8  time_until_reset
#   9  rate_limit_status    10  rate_limit_color
#  11  session_cost
#  12  worktree_text        13  worktree_color
#  14  extras_text          15  extras_color
output_status_line() {
    _print_line1 "$1" "$2" "$3"
    _print_line2 "$4" "$5" "$6" "$7" "$8"
    _print_line3 "$9" "${10}" "${11}"
    _print_line4 "${12}" "${13}"
    _print_line5 "${14}" "${15}"
}

export -f format_directory_path 2>/dev/null || true
export -f output_status_line 2>/dev/null || true
