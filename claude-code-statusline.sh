#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract data from JSON
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model_name=$(echo "$input" | jq -r '.model.display_name // .model.id')
session_id=$(echo "$input" | jq -r '.session_id')
# Try to get context tokens from Claude Code input
context_tokens_used=$(echo "$input" | jq -r '.tokens_used // 0')
context_tokens_limit=$(echo "$input" | jq -r '.tokens_limit // 200000')

# Colors with RGB values as specified
SLATE_GRAY='\033[38;2;112;128;144m'     # Ordner: SlateGray
CORNFLOWER_BLUE='\033[38;2;100;149;237m' # Git Branch: CornflowerBlue
PALE_GREEN='\033[38;2;152;251;152m'      # Login Status (eingeloggt): PaleGreen
SALMON='\033[38;2;250;128;114m'          # Login Status (ausgeloggt): Salmon
MEDIUM_ORCHID='\033[38;2;186;85;211m'    # Model: MediumOrchid
SIENNA='\033[38;2;160;82;45m'            # Tokens: Sienna
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

if [ "$is_logged_in" = true ]; then
    login_status="✅ Logged-In"
    api_status="＄ API free"
    login_color="$PALE_GREEN"
    api_color="$DARK_TURQUOISE"
else
    login_status="⛔️ Logged-Out"
    api_status="＄ API fee-based"
    login_color="$SALMON"
    api_color="$DARK_TURQUOISE"
fi

# Get real token and time data
get_usage_data() {
    # First check if we have context tokens from Claude Code input
    # Skip this for now as Claude Code doesn't provide these yet
    if false; then
        # Use context tokens from Claude Code for session tracking
        tokens_used=$context_tokens_used
        tokens_limit=$context_tokens_limit
        
        # Calculate remaining tokens
        local remaining_tokens=$((tokens_limit - tokens_used))
        
        # Estimate time based on remaining tokens (rough estimate: 100 tokens/minute)
        local estimated_minutes=$((remaining_tokens / 100))
        if [ "$estimated_minutes" -gt 0 ]; then
            local hours=$((estimated_minutes / 60))
            local minutes=$((estimated_minutes % 60))
            time_remaining="${hours}h ${minutes}m"
        else
            time_remaining="0h 0m"
        fi
    elif command -v bunx >/dev/null 2>&1; then
        # Fallback to ccusage for 5-hour block tracking
        local usage_json
        # Remove timeout as it may not be available on all systems
        usage_json=$(bunx ccusage@latest blocks --json 2>/dev/null || echo "{}")
        
        if [ "$usage_json" != "{}" ] && [ -n "$usage_json" ]; then
            # Find the active block and parse its data
            local active_block
            active_block=$(echo "$usage_json" | jq '.blocks[] | select(.isActive == true)' 2>/dev/null)
            
            if [ -n "$active_block" ]; then
                # Parse active block data
                tokens_used=$(echo "$active_block" | jq -r '.totalTokens // 0' 2>/dev/null)
                tokens_limit=$(echo "$active_block" | jq -r '.projection.totalTokens // 200000' 2>/dev/null)
                
                # Get remaining minutes and convert to "Xh Ym" format
                local remaining_minutes
                remaining_minutes=$(echo "$active_block" | jq -r '.projection.remainingMinutes // null' 2>/dev/null)
                
                if [ "$remaining_minutes" != "null" ] && [ "$remaining_minutes" -gt 0 ] 2>/dev/null; then
                    local hours=$((remaining_minutes / 60))
                    local minutes=$((remaining_minutes % 60))
                    time_remaining="${hours}h ${minutes}m"
                else
                    time_remaining="0h 0m"
                fi
            else
                # No active block found
                tokens_used=0
                tokens_limit=200000
                time_remaining="5h 0m"
            fi
        else
            # ccusage failed
            tokens_used=0
            tokens_limit=200000
            time_remaining="5h 0m"
        fi
    else
        # bunx not available
        tokens_used=0
        tokens_limit=200000
        time_remaining="5h 0m"
    fi
}

# Call function to get usage data
get_usage_data

# Calculate token percentage for icon selection
if [ "$tokens_used" -gt 0 ] && [ "$tokens_limit" -gt 0 ]; then
    token_percentage=$((tokens_used * 100 / tokens_limit))
else
    token_percentage=0
fi

if [ $token_percentage -gt 80 ]; then
    token_icon="🪫"
else
    token_icon="🔋"
fi

# Format token counter with thousand separators
tokens_used_formatted=$(printf "%'d" "$tokens_used" 2>/dev/null || echo "$tokens_used")
tokens_limit_formatted=$(printf "%'d" "$tokens_limit" 2>/dev/null || echo "$tokens_limit")
token_info="${token_icon} Tokens ${tokens_used_formatted}/${tokens_limit_formatted}"

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
# Line 2: All other elements separated by bullet points
printf "${SLATE_GRAY}📁 %s${RESET}\n" "$dir_path"
printf "${CORNFLOWER_BLUE}%s${RESET} • ${login_color}%s${RESET} • ${api_color}%s${RESET} • ${MEDIUM_ORCHID}%s${RESET} • ${SIENNA}%s${RESET} • ${PALE_TURQUOISE}%s${RESET}\n" \
    "$git_status" "$login_status" "$api_status" "$model_info" "$token_info" "$time_left"