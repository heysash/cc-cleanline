#!/bin/bash
# Cost tracking module for CC CleanLine
# Handles session costs, time calculations, and token usage tracking

# Get current session cost from ccusage
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

# Get total cost for today from ccusage
get_today_total_cost() {
    if command -v bunx >/dev/null 2>&1; then
        local usage_json
        usage_json=$(bunx ccusage@latest blocks --json 2>/dev/null || echo "{}")
        
        if [ "$usage_json" != "{}" ] && [ -n "$usage_json" ]; then
            local today_date
            today_date=$(date +"%Y-%m-%d")
            
            # Sum all blocks from today that are not gaps using jq for better precision
            local total_cost
            total_cost=$(echo "$usage_json" | jq --arg today "$today_date" '
                [.blocks[] 
                | select((.startTime | startswith($today)) or (.endTime | startswith($today))) 
                | select(.isGap == false) 
                | .costUSD] | add | . * 100 | floor / 100' 2>/dev/null)
            
            # Format to ensure exactly 2 decimal places
            if [ -n "$total_cost" ] && [ "$total_cost" != "null" ]; then
                total_cost=$(printf "%.2f" "$total_cost")
            else
                total_cost="0.00"
            fi
            
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
    local model_orange_color="$1"  # Pass model color for Medium usage
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
                        # Low usage - green color
                        echo "${ICON_ACTIVE} 5h Max Tokens Low|$COLOR_ACTIVE_STATUS"
                    elif [ "$percent_used" -lt 75 ]; then
                        # Medium usage - use model's orange color
                        echo "${ICON_ACTIVE} 5h Max Tokens Medium|$model_orange_color"
                    else
                        # High usage - red color with details
                        echo "${ICON_ACTIVE} 5h Max Tokens High: ${percent_remaining}% remain (${formatted_tokens})|$COLOR_RED"
                    fi
                    return
                fi
            fi
        fi
    fi
    
    # No data available
    echo ""
}

# Export functions for use by main script
export -f get_current_session_cost 2>/dev/null || true
export -f get_today_total_cost 2>/dev/null || true
export -f get_time_until_next_session 2>/dev/null || true
export -f get_session_token_status 2>/dev/null || true