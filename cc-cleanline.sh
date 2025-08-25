#!/bin/bash

# ====================================================================
# CC CleanLine - Modular Status Line for Claude Code
# ====================================================================
# Main orchestration script that coordinates all modules
# ====================================================================

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/cc-cleanline.config.sh"
LOCAL_CONFIG_FILE="${SCRIPT_DIR}/cc-cleanline.config.local"

# Check if default config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Configuration file not found at $CONFIG_FILE" >&2
    exit 1
fi

# Source the default configuration
source "$CONFIG_FILE"

# Source local configuration overrides if they exist
if [[ -f "$LOCAL_CONFIG_FILE" ]]; then
    source "$LOCAL_CONFIG_FILE"
fi

# Load Happy Mode Engine if it exists
HAPPY_MODE_FILE="${SCRIPT_DIR}/happy-mode.sh"
if [[ -f "$HAPPY_MODE_FILE" ]]; then
    source "$HAPPY_MODE_FILE"
fi

# Load all modules
for module in "${SCRIPT_DIR}"/lib/*.sh; do
    if [[ -f "$module" ]]; then
        source "$module"
    fi
done

# Read JSON input from stdin
input=$(cat)

# Debug logging (uncomment to capture real Claude Code JSON)
# echo "$(date): $input" >> "${SCRIPT_DIR}/debug-input.log"

# Extract data from JSON
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model_name=$(echo "$input" | jq -r '.model.display_name // .model.id')
session_id=$(echo "$input" | jq -r '.session_id')
transcript_path=$(echo "$input" | jq -r '.transcript_path // ""')
total_cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# Check login status
if [ -n "$session_id" ] && [ "$session_id" != "null" ]; then
    is_logged_in=true
else
    is_logged_in=false
fi

# Get git status information
git_result=$(get_git_status)
git_status=$(echo "$git_result" | cut -d'|' -f1)
git_color=$(echo "$git_result" | cut -d'|' -f2)

# Format directory path
dir_path=$(format_directory_path "$current_dir")

# Get login status
login_result=$(format_login_status "$is_logged_in")
login_status=$(echo "$login_result" | cut -d'|' -f1)
login_color=$(echo "$login_result" | cut -d'|' -f2)

# Get model information
model_result=$(get_model_info "$model_name")
model_info=$(echo "$model_result" | cut -d'|' -f1)
model_color=$(echo "$model_result" | cut -d'|' -f2)

# Get cost tracking information
current_session_cost=$(get_current_session_cost)
today_total_cost=$(get_today_total_cost)
time_remaining=$(get_time_until_next_session)

# Format time until next session
time_left="⏱ Next Session ${time_remaining}"

# Get session token status (pass model color for Medium usage)
session_token_result=$(get_session_token_status "$model_color")
if [ -n "$session_token_result" ]; then
    session_token_status=$(echo "$session_token_result" | cut -d'|' -f1)
    session_token_color=$(echo "$session_token_result" | cut -d'|' -f2)
fi

# Get context window status (pass model color)
context_window_result=$(get_context_window_status "$transcript_path" "$session_id" "$model_color")
if [ -n "$context_window_result" ]; then
    context_window_status=$(echo "$context_window_result" | cut -d'|' -f1)
    context_window_color=$(echo "$context_window_result" | cut -d'|' -f2)
else
    context_window_status=""
    context_window_color=""
fi

# Format cost display
cost_display=$(format_cost_display "$is_logged_in" "$today_total_cost" "$current_session_cost" "$total_cost_usd" "$session_token_status")

# Output the formatted status line
output_status_line "$git_status" "$git_color" "$dir_path" \
    "$login_status" "$login_color" "$model_info" "$model_color" \
    "$context_window_status" "$context_window_color" \
    "$time_left" "$cost_display" "$session_token_status" "$session_token_color"

# Trigger Happy Mode easter eggs if enabled
trigger_happy_mode_context "$time_remaining"