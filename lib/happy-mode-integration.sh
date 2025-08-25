#!/bin/bash
# Happy Mode integration module for CC CleanLine
# Provides simplified interface for Happy Mode easter eggs

# Function to trigger Happy Mode based on context
trigger_happy_mode_context() {
    local time_remaining="$1"
    
    # Skip if Happy Mode is not enabled
    if [[ "$HAPPY_MODE" != "true" && "$HAPPY_MODE" != "test" ]]; then
        return
    fi
    
    # Skip if Happy Mode functions are not available
    if ! command -v trigger_happy_mode >/dev/null 2>&1; then
        return
    fi
    
    # Calculate session hours for long session detection
    local session_hours=0
    if [[ -n "$time_remaining" ]]; then
        # Extract hours from time_remaining (format: "Xh Ym" or "Xh")
        if [[ "$time_remaining" =~ ([0-9]+)h ]]; then
            # Session is 5 hours minus remaining time
            local remaining_hours="${BASH_REMATCH[1]}"
            session_hours=$((5 - remaining_hours))
        fi
    fi
    
    # Better commit detection: check if last command was a git commit
    local last_git_command=$(history 1 2>/dev/null | grep -o 'git commit' || echo "")
    local recent_commit=$(git log -1 --since="2 minutes ago" --oneline 2>/dev/null)
    
    # Trigger Happy Mode based on context
    if [[ -n "$last_git_command" ]] || [[ -n "$recent_commit" ]]; then
        trigger_happy_mode "commit"
    elif git rev-parse --git-dir >/dev/null 2>&1; then
        trigger_happy_mode "git"
    else
        trigger_happy_mode "status" "$session_hours"
    fi
}

# Export function for use by main script
export -f trigger_happy_mode_context 2>/dev/null || true