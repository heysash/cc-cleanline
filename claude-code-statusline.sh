#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract data from JSON
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model_name=$(echo "$input" | jq -r '.model.display_name // .model.id')
session_id=$(echo "$input" | jq -r '.session_id')

# Get token status from Claude Code input
exceeds_200k_tokens=$(echo "$input" | jq -r '.exceeds_200k_tokens // false')

# Colors with RGB values as specified
SLATE_GRAY='\033[38;2;112;128;144m'     # Ordner: SlateGray
CORNFLOWER_BLUE='\033[38;2;100;149;237m' # Git Branch: CornflowerBlue
PALE_GREEN='\033[38;2;152;251;152m'      # Login Status (eingeloggt): PaleGreen
SALMON='\033[38;2;250;128;114m'          # Login Status (ausgeloggt): Salmon
MEDIUM_ORCHID='\033[38;2;186;85;211m'    # Model: MediumOrchid
SIENNA='\033[38;2;160;82;45m'            # Tokens: Sienna
CRIMSON='\033[38;2;220;20;60m'            # Token status (exceeded): Crimson
PALE_TURQUOISE='\033[38;2;175;238;238m'  # Zeit: PaleTurquoise
DARK_TURQUOISE='\033[38;2;0;206;209m'    # API Status: DarkTurquoise
RESET='\033[0m'
DIM='\033[2m'

# Use full directory path instead of just basename
dir_path="$current_dir"

# Get git branch or show "No git" if not in repo
if git rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then
        git_status="⎇ git branch ${branch}"
    else
        git_status="⎇ No git"
    fi
else
    git_status="⎇ No git"
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
    token_status="❌ Context window exceeded! Do /compress"
    token_color="$CRIMSON"
else
    token_status="✅ Context window ok"
    token_color="$PALE_GREEN"
fi

if [ "$is_logged_in" = true ]; then
    login_status="🟢 Logged-In"
    api_status="⚡API \$0 (normally \$$current_cost)"
    login_color="$PALE_GREEN"
    api_color="$DARK_TURQUOISE"
else
    login_status="🔴 Logged-Out"
    api_status="⚡API \$$current_cost (today costs)"
    login_color="$SALMON"
    api_color="$DARK_TURQUOISE"
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
    time_left="⏱️ Time left ${time_remaining}"
else
    time_left="⏱️ Time left N/A"
fi

# Determine model icon based on model name
if [[ "$model_name" == *"sonnet"* ]] || [[ "$model_name" == *"Sonnet"* ]]; then
    model_icon="🤖"
elif [[ "$model_name" == *"opus"* ]] || [[ "$model_name" == *"Opus"* ]]; then
    model_icon="🧠"
else
    model_icon="🤖"  # Default to robot for unknown models
fi

model_info="${model_icon} LLM ${model_name}"

# Build the status line with two lines:
# Line 1: Directory only
# Line 2: All other elements separated by bullet points (without token info)
printf "${SLATE_GRAY}📁 %s${RESET}\n" "$dir_path"
printf "${CORNFLOWER_BLUE}%s${RESET} • ${login_color}%s${RESET} • ${token_color}%s${RESET} • ${api_color}%s${RESET} • ${MEDIUM_ORCHID}%s${RESET} • ${PALE_TURQUOISE}%s${RESET}\n" \
    "$git_status" "$login_status" "$token_status" "$api_status" "$model_info" "$time_left"