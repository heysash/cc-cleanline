#!/bin/bash
# Display formatter module for CC CleanLine
# Handles final status line formatting and output

# Format directory path
format_directory_path() {
    local current_dir="$1"
    local dir_path=""
    
    if [ "$SHOW_FULL_PATH" = true ]; then
        dir_path="$current_dir"
    else
        # Show only the current directory name with ./
        dir_path="./$(basename "$current_dir")"
    fi
    
    echo "$dir_path"
}

# Format login status
format_login_status() {
    local is_logged_in="$1"
    local login_status=""
    local login_color=""
    
    if [ "$is_logged_in" = true ]; then
        login_status="${ICON_ACTIVE} ${LABEL_LOGGED_IN}"
        login_color="$COLOR_ACTIVE_STATUS"
    else
        login_status="${ICON_INACTIVE} ${LABEL_NOT_LOGGED_IN}"
        login_color="$COLOR_INACTIVE_STATUS"
    fi
    
    echo "${login_status}|${login_color}"
}

# Format cost display
format_cost_display() {
    local is_logged_in="$1"
    local today_total_cost="$2"
    local current_session_cost="$3"
    local total_cost_usd="$4"
    local session_token_status="$5"
    local cost_display=""
    
    if [ "$is_logged_in" = true ]; then
        # When logged in
        if [ "$SHOW_API_COSTS_WHEN_INCLUDED" = true ]; then
            api_part="⚡API Costs Included - Saved Today \$$today_total_cost This Session \$$current_session_cost"
        else
            api_part="⚡API Costs Included"
        fi
        
        if [ -n "$session_token_status" ]; then
            cost_display="${session_token_status} ${api_part}"
        else
            cost_display="${api_part}"
        fi
    else
        # When not logged in
        if [ "$SHOW_API_COSTS" = true ]; then
            api_part="⚡API \$$(printf "%.2f" "$total_cost_usd") (current session)"
        else
            api_part="⚡API"
        fi
        
        if [ -n "$session_token_status" ]; then
            cost_display="${session_token_status} ${api_part}"
        else
            cost_display="${api_part}"
        fi
    fi
    
    echo "$cost_display"
}

# Output the formatted status line
output_status_line() {
    local git_status="$1"
    local git_color="$2"
    local dir_path="$3"
    local login_status="$4"
    local login_color="$5"
    local model_info="$6"
    local model_color="$7"
    local context_window_status="$8"
    local context_window_color="$9"
    local time_left="${10}"
    local cost_display="${11}"
    local session_token_status="${12}"
    local session_token_color="${13}"
    
    # Output first line: git status and directory
    printf "${git_color}%s${COLOR_RESET} ${COLOR_NEUTRAL_TEXT}▶ %s${COLOR_RESET}\n" \
        "$git_status" "$dir_path"
    
    # Output second line: login status, model info, context window (if available), and time
    if [ -n "$context_window_status" ]; then
        # Include context window status
        printf "${login_color}%s${COLOR_RESET} ${model_color}%s${COLOR_RESET} ${context_window_color}%s${COLOR_RESET} ${COLOR_NEUTRAL_TEXT}%s${COLOR_RESET}\n" \
            "$login_status" "$model_info" "$context_window_status" "$time_left"
    else
        # No context window status
        printf "${login_color}%s${COLOR_RESET} ${model_color}%s${COLOR_RESET} ${COLOR_NEUTRAL_TEXT}%s${COLOR_RESET}\n" \
            "$login_status" "$model_info" "$time_left"
    fi
    
    # Output third line: cost display with token status
    if [ -n "$session_token_status" ] && [ -n "$session_token_color" ]; then
        # Token status is now at the beginning, extract API part
        api_part="${cost_display#${session_token_status} }"
        printf "  ${session_token_color}%s${COLOR_RESET} ${COLOR_NEUTRAL_TEXT}%s${COLOR_RESET}\n" "$session_token_status" "$api_part"
    else
        printf "  ${COLOR_NEUTRAL_TEXT}%s${COLOR_RESET}\n" "$cost_display"
    fi
}

# Export functions for use by main script
export -f format_directory_path 2>/dev/null || true
export -f format_login_status 2>/dev/null || true
export -f format_cost_display 2>/dev/null || true
export -f output_status_line 2>/dev/null || true