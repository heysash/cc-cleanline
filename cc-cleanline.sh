#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/cc-cleanline.config.sh"

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Configuration file not found at $CONFIG_FILE" >&2
    exit 1
fi

# Source the configuration
source "$CONFIG_FILE"

# Read JSON input from stdin
input=$(cat)

# Debug logging (uncomment to capture real Claude Code JSON)
# echo "$(date): $input" >> "${SCRIPT_DIR}/debug-input.log"

# Extract data from JSON
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model_name=$(echo "$input" | jq -r '.model.display_name // .model.id')
session_id=$(echo "$input" | jq -r '.session_id')


# Get cost and code changes from Claude Code JSON
total_cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

# Format directory path based on configuration
if [ "$SHOW_FULL_PATH" = true ]; then
    dir_path="$current_dir"
else
    # Show only the current directory name with ./
    dir_path="./$(basename "$current_dir")"
fi

# Get git branch with code changes or show "no git repository" if not in repo
if git rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then
        # Add code changes if available (show only if non-zero)
        if [ "$lines_added" -gt 0 ] || [ "$lines_removed" -gt 0 ]; then
            git_status="${ICON_ACTIVE} git branch ${branch} (+${lines_added}/-${lines_removed})"
        else
            git_status="${ICON_ACTIVE} git branch ${branch}"
        fi
        git_color="$COLOR_ACTIVE_STATUS"
    else
        git_status="${ICON_INACTIVE} no git repository"
        git_color="$COLOR_INACTIVE_STATUS"
    fi
else
    git_status="${ICON_INACTIVE} no git repository"
    git_color="$COLOR_INACTIVE_STATUS"
fi

# Check login status by testing if we have a valid session_id
if [ -n "$session_id" ] && [ "$session_id" != "null" ]; then
    is_logged_in=true
else
    is_logged_in=false
fi

# Get current session cost from ccusage (for active session block)
get_current_session_cost() {
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

current_session_cost=$(get_current_session_cost)

# Get total cost for today from ccusage
get_today_total_cost() {
    if command -v bunx >/dev/null 2>&1; then
        local usage_json
        usage_json=$(bunx ccusage@latest blocks --json 2>/dev/null || echo "{}")
        
        if [ "$usage_json" != "{}" ] && [ -n "$usage_json" ]; then
            local today_date
            today_date=$(date +"%Y-%m-%d")
            
            # Sum all blocks from today that are not gaps
            local total_cost
            total_cost=$(echo "$usage_json" | jq --arg today "$today_date" '
                .blocks[] 
                | select(.startTime | startswith($today)) 
                | select(.isGap == false) 
                | .costUSD' 2>/dev/null | awk '{sum += $1} END {printf "%.2f", sum}')
            
            if [ -n "$total_cost" ] && [ "$total_cost" != "0.00" ]; then
                echo "$total_cost"
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

today_total_cost=$(get_today_total_cost)



if [ "$is_logged_in" = true ]; then
    login_status="${ICON_ACTIVE} ${LABEL_LOGGED_IN}"
    login_color="$COLOR_ACTIVE_STATUS"
else
    login_status="${ICON_INACTIVE} ${LABEL_NOT_LOGGED_IN}"
    login_color="$COLOR_INACTIVE_STATUS"
fi

# Calculate time until next session - checks ccusage for active session first
get_time_until_next_session() {
    # First try to get time from ccusage if available
    if command -v bunx >/dev/null 2>&1; then
        local usage_json
        usage_json=$(bunx ccusage@latest blocks --json 2>/dev/null || echo "{}")
        
        if [ "$usage_json" != "{}" ] && [ -n "$usage_json" ]; then
            # Check if there's an active block
            local active_block
            active_block=$(echo "$usage_json" | jq '.blocks[] | select(.isActive == true)' 2>/dev/null)
            
            if [ -n "$active_block" ]; then
                # Get remaining time from active block
                local remaining_minutes
                remaining_minutes=$(echo "$active_block" | jq -r '.projection.remainingMinutes // 0' 2>/dev/null)
                
                if [ "$remaining_minutes" -gt 0 ]; then
                    # Convert minutes to hours and minutes
                    local hours=$((remaining_minutes / 60))
                    local minutes=$((remaining_minutes % 60))
                    
                    # Format output
                    if [ "$minutes" -eq 0 ]; then
                        echo "${hours}h"
                    else
                        echo "${hours}h ${minutes}m"
                    fi
                    return
                fi
            fi
        fi
    fi
    
    # Fallback to Anthropic Hour Boundary logic if no active session in ccusage
    local current_hour=$(date +"%H")
    local current_minute=$(date +"%M")
    
    # Session duration is 5 hours minus the minutes already elapsed in current hour
    local session_duration_minutes=$((5 * 60 - current_minute))
    
    # If we're at exactly the hour boundary, session is full 5 hours
    if [ "$current_minute" -eq 0 ]; then
        session_duration_minutes=$((5 * 60))
    fi
    
    # Convert back to hours and minutes
    local hours=$((session_duration_minutes / 60))
    local minutes=$((session_duration_minutes % 60))
    
    # Format output
    if [ "$minutes" -eq 0 ]; then
        echo "${hours}h"
    else
        echo "${hours}h ${minutes}m"
    fi
}

# Get session token usage status (5h window)
get_session_token_status() {
    if command -v bunx >/dev/null 2>&1; then
        local usage_json
        usage_json=$(bunx ccusage@latest blocks --json 2>/dev/null || echo "{}")
        
        if [ "$usage_json" != "{}" ] && [ -n "$usage_json" ]; then
            local active_block
            active_block=$(echo "$usage_json" | jq '.blocks[] | select(.isActive == true)' 2>/dev/null)
            
            if [ -n "$active_block" ]; then
                # Token limit for 5h session (from ccusage observations)
                local token_limit=77679587
                
                # Get current token usage
                local total_tokens
                total_tokens=$(echo "$active_block" | jq -r '.totalTokens // 0' 2>/dev/null)
                
                if [ "$total_tokens" -gt 0 ]; then
                    # Calculate percentages
                    local percent_used=$(( (total_tokens * 100) / token_limit ))
                    local percent_remaining=$((100 - percent_used))
                    local tokens_remaining=$((token_limit - total_tokens))
                    
                    # Format remaining tokens with comma separators
                    local formatted_tokens=$(printf "%'d" $tokens_remaining 2>/dev/null || echo "$tokens_remaining")
                    
                    # Determine status based on usage percentage
                    if [ "$percent_used" -lt 40 ]; then
                        # Low usage
                        echo "${ICON_ACTIVE} 5h Max Tokens|$COLOR_NEUTRAL_TEXT"
                    elif [ "$percent_used" -lt 75 ]; then
                        # Medium usage
                        echo "${ICON_ACTIVE} 5h Max Tokens|$COLOR_NEUTRAL_TEXT"
                    else
                        # High usage - show percentage and count
                        echo "${ICON_ACTIVE} 5h Max Tokens: ${percent_remaining}% remain (${formatted_tokens})|$COLOR_NEUTRAL_TEXT"
                    fi
                    return
                fi
            fi
        fi
    fi
    
    # No data available
    echo ""
}

time_remaining=$(get_time_until_next_session)

# Format time until next session
time_left="⏱ Next Session in ${time_remaining}"

# Determine model info based on model name
if [[ "$model_name" == *"sonnet"* ]] || [[ "$model_name" == *"Sonnet"* ]]; then
    model_info="☆ ${LABEL_MODEL} Sonnet 4"
    model_color="$COLOR_SONNET"
elif [[ "$model_name" == *"opus"* ]] || [[ "$model_name" == *"Opus"* ]]; then
    model_info="★ ${LABEL_MODEL} Opus 4.1"
    model_color="$COLOR_OPUS"
else
    model_info="${ICON_ACTIVE} ${LABEL_MODEL} ${model_name}"
    model_color="$COLOR_DEFAULT_MODEL"
fi

# Determine cost display using ccusage data
if [ "$is_logged_in" = true ]; then
    cost_display="⚡API Included - Saved Today \$$today_total_cost This Session \$$current_session_cost"
else
    cost_display="⚡API \$$(printf "%.2f" "$total_cost_usd") (current session)"
fi

# Get session token status
session_token_result=$(get_session_token_status)
if [ -n "$session_token_result" ]; then
    session_token_status=$(echo "$session_token_result" | cut -d'|' -f1)
    session_token_color=$(echo "$session_token_result" | cut -d'|' -f2)
fi

# Build the status line
printf "${git_color}%s${COLOR_RESET} ${COLOR_NEUTRAL_TEXT}▶ %s${COLOR_RESET}\n" \
    "$git_status" "$dir_path"
printf "${login_color}%s${COLOR_RESET} ${model_color}%s${COLOR_RESET} ${COLOR_NEUTRAL_TEXT}%s${COLOR_RESET}\n" \
    "$login_status" "$model_info" "$time_left"
printf "  ${COLOR_NEUTRAL_TEXT}%s${COLOR_RESET}\n" "$cost_display"

# Add session token status if available
if [ -n "$session_token_status" ]; then
    printf "  ${session_token_color}%s${COLOR_RESET}\n" "$session_token_status"
fi