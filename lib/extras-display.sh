#!/bin/bash
# Extras-display module for CC CleanLine.
# Produces the optional 4th and 5th status lines (worktree info + extras row
# combining output-style, vim mode, PR status, and optional Claude Code version).
# Each function returns an empty string when its corresponding fields are not set,
# so the display formatter can drop the line entirely.

# Treat a value as "empty" if it's blank, the literal "null", or "default".
_is_empty_value() {
    local v="$1"
    [[ -z "$v" || "$v" = "null" || "$v" = "default" ]]
}

# Treat a value as "empty" but NOT counting "default" as empty (PR review state etc.).
_is_blank_value() {
    local v="$1"
    [[ -z "$v" || "$v" = "null" ]]
}

# Map a PR review state to an icon hint. Returns empty for benign states.
_pr_state_icon() {
    case "$1" in
        approved)            printf '✓' ;;
        changes_requested)   printf '⚠' ;;
        commented)           printf '💬' ;;
        *)                   printf '' ;;
    esac
}

# format_worktree_line <worktree_name> <worktree_branch>
# Outputs: "🌿 worktree: NAME ▸ branch: BRANCH|<color>"
# Empty string if worktree_name is missing, or if SHOW_WORKTREE_LINE=false.
format_worktree_line() {
    local name="$1"
    local branch="$2"

    if [[ "${SHOW_WORKTREE_LINE:-true}" != true ]]; then
        printf ''
        return
    fi
    if _is_blank_value "$name"; then
        printf ''
        return
    fi

    local rendered="🌿 worktree: ${name}"
    if ! _is_blank_value "$branch"; then
        rendered="${rendered} ▸ branch: ${branch}"
    fi
    printf '%s|%s' "$rendered" "${COLOR_NEUTRAL_TEXT}"
}

# format_extras_line <output_style> <vim_mode> <pr_number> <pr_review_state> [version]
# Outputs: "⚙ style: <s> · vim: <v> · PR #<n> <icon><state>[ · v<version>]|<color>"
# Empty string if none of the fields are populated.
# SHOW_EXTRAS_LINE=false disables the line entirely.
# SHOW_VERSION=true appends "· v<version>" when version is given.
format_extras_line() {
    local output_style="$1"
    local vim_mode="$2"
    local pr_number="$3"
    local pr_review_state="$4"
    local version="${5:-}"

    if [[ "${SHOW_EXTRAS_LINE:-true}" != true ]]; then
        printf ''
        return
    fi

    local parts=()

    if ! _is_empty_value "$output_style"; then
        parts+=("⚙ style: ${output_style}")
    fi
    if ! _is_blank_value "$vim_mode"; then
        parts+=("vim: ${vim_mode}")
    fi
    if ! _is_blank_value "$pr_number"; then
        local pr_text="PR #${pr_number}"
        local icon
        icon=$(_pr_state_icon "$pr_review_state")
        if [[ -n "$icon" ]]; then
            pr_text="${pr_text} ${icon} ${pr_review_state}"
        fi
        parts+=("$pr_text")
    fi
    if [[ "${SHOW_VERSION:-false}" == true ]] && ! _is_blank_value "$version"; then
        parts+=("v${version}")
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

    printf '%s|%s' "$joined" "${COLOR_NEUTRAL_TEXT}"
}

export -f format_worktree_line 2>/dev/null || true
export -f format_extras_line 2>/dev/null || true
