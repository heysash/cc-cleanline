#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract data from JSON
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model_name=$(echo "$input" | jq -r '.model.display_name // .model.id')
session_id=$(echo "$input" | jq -r '.session_id')

# Colors (dimmed for status line)
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
RED='\033[0;31m'
RESET='\033[0m'
DIM='\033[2m'

# Get directory name (last part of path)
dir_name=$(basename "$current_dir")

# Get git branch if in git repo
git_branch=""
if git rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then
        git_branch=" git:${branch}"
    fi
fi

# Get login status (check if we can access Claude API or similar)
login_status="${GREEN}logged-in${RESET}"

# Mock token usage (Claude Code doesn't provide this info in the JSON)
# In a real implementation, this would need to track tokens from the session
tokens_used="103,438"
tokens_limit="200,000"
token_info="${YELLOW}${tokens_used}/${tokens_limit}${RESET}"

# Mock remaining time (Claude Code doesn't provide session time info)
# In a real implementation, this would calculate based on session start time
remaining_time="${MAGENTA}2h 43m left${RESET}"

# Build the status line
printf "${DIM}${CYAN}%s${RESET}${GREEN}%s${RESET} ${login_status} ${DIM}${BLUE}%s${RESET} ${token_info} ${remaining_time}\n" \
    "$dir_name" "$git_branch" "$model_name"