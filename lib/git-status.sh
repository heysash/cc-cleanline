#!/bin/bash
# Git status module for CC CleanLine
# Handles git branch detection, change tracking, and status formatting

# Function to get git status information
get_git_status() {
    local branch=""
    local display_branch=""
    local git_status=""
    local git_color=""
    
    # Check if in a git repository
    if git rev-parse --git-dir >/dev/null 2>&1; then
        branch=$(git branch --show-current 2>/dev/null)
        
        if [ -n "$branch" ]; then
            # Apply rainbow effect to branch name if Happy Mode is enabled
            display_branch="$branch"
            if [[ "$HAPPY_MODE" == "true" || "$HAPPY_MODE" == "test" ]] && command -v generate_rainbow_branch >/dev/null 2>&1; then
                # Higher chance in test mode, rare in normal mode
                local branch_rainbow_chance=200
                if [[ "$HAPPY_MODE" == "test" ]]; then
                    branch_rainbow_chance=10
                fi
                
                if [[ $((RANDOM % $branch_rainbow_chance)) -eq 0 ]]; then
                    display_branch=$(generate_rainbow_branch "$branch")
                fi
            fi
            
            # Check for actual git changes (staged + unstaged)
            local staged_changes=$(git diff --cached --numstat | awk 'BEGIN{add=0; rem=0} {add+=$1; rem+=$2} END{printf "+%d/-%d", add, rem}' 2>/dev/null)
            local unstaged_changes=$(git diff --numstat | awk 'BEGIN{add=0; rem=0} {add+=$1; rem+=$2} END{printf "+%d/-%d", add, rem}' 2>/dev/null)
            
            # Format git status with changes
            if [ "$staged_changes" != "+0/-0" ] || [ "$unstaged_changes" != "+0/-0" ]; then
                if [ "$staged_changes" != "+0/-0" ] && [ "$unstaged_changes" != "+0/-0" ]; then
                    git_status="${ICON_ACTIVE} git branch ${display_branch} (${staged_changes}, ${unstaged_changes})"
                elif [ "$staged_changes" != "+0/-0" ]; then
                    git_status="${ICON_ACTIVE} git branch ${display_branch} (${staged_changes})"
                else
                    git_status="${ICON_ACTIVE} git branch ${display_branch} (${unstaged_changes})"
                fi
            else
                git_status="${ICON_ACTIVE} git branch ${display_branch}"
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
    
    # Return both status and color
    echo "${git_status}|${git_color}"
}

# Export function for use by main script
export -f get_git_status 2>/dev/null || true