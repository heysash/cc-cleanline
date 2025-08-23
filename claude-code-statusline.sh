#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract data from JSON
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model_name=$(echo "$input" | jq -r '.model.display_name // .model.id')
session_id=$(echo "$input" | jq -r '.session_id')

# Get token status from Claude Code input
exceeds_200k_tokens=$(echo "$input" | jq -r '.exceeds_200k_tokens // false')

# Colors (simplified to only forestgreen and firebrick)
FORESTGREEN='\033[38;2;34;139;34m'   # forestgreen="#228B22" for all active status
FIREBRICK='\033[38;2;178;34;34m'     # firebrick="#B22222" for all inactive status
SANDYBROWN='\033[38;2;244;164;96m'   # sandybrown="#F4A460" for Sonnet
DARKORANGE='\033[38;2;255;140;0m'    # darkorange="#FF8C00" for Opus
RESET='\033[0m'

# Use full directory path instead of just basename
dir_path="$current_dir"

# Get git branch or show "no git repository" if not in repo
if git rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then
        git_status="● git branch ${branch}"
        git_color="$FORESTGREEN"
    else
        git_status="○ no git repository"
        git_color="$FIREBRICK"
    fi
else
    git_status="○ no git repository"
    git_color="$FIREBRICK"
fi

# Check login status by testing if we have a valid session_id
if [ -n "$session_id" ] && [ "$session_id" != "null" ]; then
    is_logged_in=true
else
    is_logged_in=false
fi

# Get current cost from ccusage
get_current_cost() {
    if command -v bunx >/dev/null 2>&1; then
        local usage_json
        usage_json=$(bunx ccusage@latest blocks --json 2>/dev/null || echo "{}")
        
        if [ "$usage_json" != "{}" ] && [ -n "$usage_json" ]; then
            # Find the active block and get its cost
            local active_block
            active_block=$(echo "$usage_json" | jq '.blocks[] | select(.isActive == true)' 2>/dev/null)
            
            if [ -n "$active_block" ]; then
                local cost_usd
                cost_usd=$(echo "$active_block" | jq -r '.costUSD // 0' 2>/dev/null)
                printf "%.2f" "$cost_usd" 2>/dev/null || echo "0.00"
            else
                echo "0.00"
            fi
        else
            echo "0.00"
        fi
    else
        echo "0.00"
    fi
}

current_cost=$(get_current_cost)

# Simple token status based on exceeds_200k_tokens flag
if [ "$exceeds_200k_tokens" = "true" ]; then
    token_status="⚠ Context window exceeded! Do /compress"
    token_color="$FIREBRICK"
else
    token_status="✓ Context window ok"
    token_color="$FORESTGREEN"
fi

if [ "$is_logged_in" = true ]; then
    login_status="● Logged-In"
    login_color="$FORESTGREEN"
else
    login_status="○ Logged-Out"
    login_color="$FIREBRICK"
fi

# Get remaining time from ccusage
get_time_remaining() {
    if command -v bunx >/dev/null 2>&1; then
        local usage_json
        usage_json=$(bunx ccusage@latest blocks --json 2>/dev/null || echo "{}")
        
        if [ "$usage_json" != "{}" ] && [ -n "$usage_json" ]; then
            # Find the active block and get remaining time
            local active_block
            active_block=$(echo "$usage_json" | jq '.blocks[] | select(.isActive == true)' 2>/dev/null)
            
            if [ -n "$active_block" ]; then
                local remaining_minutes
                remaining_minutes=$(echo "$active_block" | jq -r '.projection.remainingMinutes // null' 2>/dev/null)
                
                if [ "$remaining_minutes" != "null" ] && [ "$remaining_minutes" -gt 0 ] 2>/dev/null; then
                    local hours=$((remaining_minutes / 60))
                    local minutes=$((remaining_minutes % 60))
                    echo "${hours}h ${minutes}m"
                else
                    echo "0h 0m"
                fi
            else
                echo "5h 0m"
            fi
        else
            echo "5h 0m"
        fi
    else
        echo "5h 0m"
    fi
}

time_remaining=$(get_time_remaining)

# Format time remaining
if [ "$time_remaining" != "N/A" ]; then
    time_left="⏱ Session time left ${time_remaining}"
else
    time_left="⏱ Session time left N/A"
fi

# Determine model info based on model name
if [[ "$model_name" == *"sonnet"* ]] || [[ "$model_name" == *"Sonnet"* ]]; then
    model_info="☆ LLM Sonnet 4"
    model_color="$SANDYBROWN"
elif [[ "$model_name" == *"opus"* ]] || [[ "$model_name" == *"Opus"* ]]; then
    model_info="★ LLM Opus 4.1"
    model_color="$DARKORANGE"
else
    model_info="● LLM ${model_name}"
    model_color=""
fi

# Build the status line to match the screenshot format
printf "${git_color}%s${RESET} ▶ %s\n" \
    "$git_status" "$dir_path"
printf "${login_color}%s${RESET} ${model_color}%s${RESET} %s\n" \
    "$login_status" "$model_info" "$time_left"
printf "  ${token_color}%s${RESET} ⚡API \$0 (normally \$${current_cost})\n" \
    "$token_status"