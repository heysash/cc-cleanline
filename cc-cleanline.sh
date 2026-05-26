#!/usr/bin/env bash
# ====================================================================
# CC CleanLine — modular status line for Claude Code
# ====================================================================
# Reads the Claude Code statusline JSON from stdin, delegates rendering
# to focused modules under lib/, and prints a 3- to 5-line status line.
# ====================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- Configuration --------------------------------------------------
CONFIG_FILE="${SCRIPT_DIR}/cc-cleanline.config.sh"
LOCAL_CONFIG_FILE="${SCRIPT_DIR}/cc-cleanline.config.local"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: configuration not found at $CONFIG_FILE" >&2
    exit 1
fi
# shellcheck disable=SC1090
source "$CONFIG_FILE"
if [[ -f "$LOCAL_CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$LOCAL_CONFIG_FILE"
fi

# ---- Happy Mode engine ----------------------------------------------
# Load rainbow utility first (other modules use it for branch/model fx).
for happy_module in \
    "${SCRIPT_DIR}/happy-mode/rainbow.sh" \
    "${SCRIPT_DIR}/happy-mode/engine.sh"
do
    if [[ -f "$happy_module" ]]; then
        # shellcheck disable=SC1090
        source "$happy_module"
    fi
done
unset happy_module

# ---- Modules --------------------------------------------------------
for module in "${SCRIPT_DIR}"/lib/*.sh; do
    [[ -f "$module" ]] || continue
    # shellcheck disable=SC1090
    source "$module"
done

# ---- Input ----------------------------------------------------------
input=$(cat)

# Optional debug capture — uncomment to record real-session JSON to disk.
# echo "$(date): $input" >> "${SCRIPT_DIR}/debug-input.log"

# Parse all needed fields in a single jq call.
# jq emits each value on its own line; a line-based array preserves empty
# strings — unlike `read -r` with IFS=tab, which collapses consecutive
# delimiters and silently shifts fields when one is empty.
fields=()
while IFS= read -r _line; do
    fields+=("$_line")
done < <(printf '%s' "$input" | jq -r '
    .workspace.current_dir // .cwd // "",
    .model.id // "",
    .model.display_name // "",
    .session_id // "",
    .transcript_path // "",
    .version // "",
    .cost.total_cost_usd // 0,
    .context_window.total_input_tokens // 0,
    .context_window.context_window_size // 200000,
    .exceeds_200k_tokens // false,
    .rate_limits.five_hour.used_percentage // 0,
    .rate_limits.five_hour.resets_at // 0,
    .output_style.name // "",
    .vim.mode // "",
    .worktree.name // "",
    .worktree.branch // "",
    .pr.number // "",
    .pr.review_state // "",
    .effort.level // ""
')

current_dir="${fields[0]}"
model_id="${fields[1]}"
model_display="${fields[2]}"
session_id="${fields[3]}"
transcript_path="${fields[4]}"
version="${fields[5]}"
total_cost_usd="${fields[6]}"
context_input_tokens="${fields[7]}"
context_window_size="${fields[8]}"
exceeds_200k="${fields[9]}"
rate_limit_5h_pct="${fields[10]}"
rate_limit_5h_reset="${fields[11]}"
output_style_name="${fields[12]}"
vim_mode="${fields[13]}"
worktree_name="${fields[14]}"
worktree_branch="${fields[15]}"
pr_number="${fields[16]}"
pr_review_state="${fields[17]}"
effort_level="${fields[18]}"

# Silence shellcheck for the few variables we read for future use.
: "$session_id" "$transcript_path" "$exceeds_200k"

# ---- Render module outputs (each: "text|color") ---------------------
git_result=$(get_git_status)
git_status="${git_result%|*}"
git_color="${git_result##*|}"

dir_path=$(format_directory_path "$current_dir")

model_result=$(get_model_info "$model_id" "$model_display" "$effort_level")
model_info="${model_result%|*}"
model_color="${model_result##*|}"

context_result=$(get_context_display "$context_input_tokens" "$context_window_size" "$model_color")
context_display="${context_result%|*}"
context_color="${context_result##*|}"
if [[ "$context_result" == "$context_display" ]]; then
    # No pipe → empty payload
    context_display=""
    context_color=""
fi

time_until_reset=$(format_time_until_reset "$rate_limit_5h_reset")

rate_limit_result=$(format_rate_limit "$rate_limit_5h_pct")
rate_limit_status="${rate_limit_result%|*}"
rate_limit_color="${rate_limit_result##*|}"
if [[ "$rate_limit_result" == "$rate_limit_status" ]]; then
    rate_limit_status=""
    rate_limit_color=""
fi

session_cost=$(format_session_cost "$total_cost_usd")

worktree_result=$(format_worktree_line "$worktree_name" "$worktree_branch")
worktree_text="${worktree_result%|*}"
worktree_color="${worktree_result##*|}"
if [[ "$worktree_result" == "$worktree_text" ]]; then
    worktree_text=""
    worktree_color=""
fi

extras_result=$(format_extras_line "$output_style_name" "$vim_mode" "$pr_number" "$pr_review_state" "$version")
extras_text="${extras_result%|*}"
extras_color="${extras_result##*|}"
if [[ "$extras_result" == "$extras_text" ]]; then
    extras_text=""
    extras_color=""
fi

# ---- Print ----------------------------------------------------------
output_status_line \
    "$git_status" "$git_color" \
    "$dir_path" \
    "$model_info" "$model_color" \
    "$context_display" "$context_color" \
    "$time_until_reset" \
    "$rate_limit_status" "$rate_limit_color" \
    "$session_cost" \
    "$worktree_text" "$worktree_color" \
    "$extras_text" "$extras_color"

# ---- Happy Mode trigger (legacy integration; refactored next) -------
if command -v trigger_happy_mode_context >/dev/null 2>&1; then
    trigger_happy_mode_context "$time_until_reset"
fi
