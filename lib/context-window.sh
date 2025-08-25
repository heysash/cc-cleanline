#!/bin/bash
# Context window monitoring module for CC CleanLine
# Reactively parses JSONL to extract context usage data when available

# Cache variables
CONTEXT_CACHE_FILE="/tmp/cc-cleanline-context-cache"
CONTEXT_CACHE_TTL="${CONTEXT_CACHE_TTL:-30}"  # 30 seconds default for better freshness

# Get context window usage from JSONL transcript
get_context_window_usage() {
    local transcript_path="$1"
    local session_id="$2"
    
    # Return empty if no transcript path
    if [ -z "$transcript_path" ] || [ "$transcript_path" = "null" ]; then
        echo ""
        return
    fi
    
    # Check if transcript file exists
    if [ ! -f "$transcript_path" ]; then
        echo ""
        return
    fi
    
    # Check cache first - also check file modification time
    if [ -f "$CONTEXT_CACHE_FILE" ]; then
        local cache_content
        cache_content=$(cat "$CONTEXT_CACHE_FILE" 2>/dev/null)
        if [ -n "$cache_content" ]; then
            local cache_timestamp
            local cache_session
            local cache_data
            local cache_file_mtime
            
            cache_timestamp=$(echo "$cache_content" | cut -d'|' -f1)
            cache_session=$(echo "$cache_content" | cut -d'|' -f2)
            cache_data=$(echo "$cache_content" | cut -d'|' -f3)
            cache_file_mtime=$(echo "$cache_content" | cut -d'|' -f4)
            
            local current_time
            current_time=$(date +%s)
            local cache_age=$((current_time - cache_timestamp))
            
            # Get current file modification time
            local current_file_mtime
            if [ -f "$transcript_path" ]; then
                current_file_mtime=$(stat -f %m "$transcript_path" 2>/dev/null || stat -c %Y "$transcript_path" 2>/dev/null || echo "0")
            else
                current_file_mtime="0"
            fi
            
            # Return cached data only if: same session, cache is fresh, and file hasn't been modified
            if [ "$cache_session" = "$session_id" ] && [ "$cache_age" -lt "$CONTEXT_CACHE_TTL" ] && [ "$cache_file_mtime" = "$current_file_mtime" ]; then
                echo "$cache_data"
                return
            fi
        fi
    fi
    
    # Search for /context command output in JSONL (reverse order for most recent)
    local context_output
    # Use tail -r on macOS or tac on Linux
    if command -v tac >/dev/null 2>&1; then
        context_output=$(tac "$transcript_path" 2>/dev/null | \
            grep -m1 "Context Usage.*tokens" | \
            grep -oE "[0-9]+k/[0-9]+k tokens \([0-9]+%\)" | \
            head -1)
    else
        context_output=$(tail -r "$transcript_path" 2>/dev/null | \
            grep -m1 "Context Usage.*tokens" | \
            grep -oE "[0-9]+k/[0-9]+k tokens \([0-9]+%\)" | \
            head -1)
    fi
    
    # If no exact match, try alternative pattern
    if [ -z "$context_output" ]; then
        # Look for the actual context output in local-command-stdout
        if command -v tac >/dev/null 2>&1; then
            context_output=$(tac "$transcript_path" 2>/dev/null | \
                grep -A5 "command-name./context" | \
                grep -oE "[0-9]+(\.[0-9]+)?k/[0-9]+k tokens \([0-9]+%\)" | \
                head -1)
        else
            context_output=$(tail -r "$transcript_path" 2>/dev/null | \
                grep -A5 "command-name./context" | \
                grep -oE "[0-9]+(\.[0-9]+)?k/[0-9]+k tokens \([0-9]+%\)" | \
                head -1)
        fi
    fi
    
    # Cache the result if found
    if [ -n "$context_output" ]; then
        local current_time
        current_time=$(date +%s)
        local file_mtime
        if [ -f "$transcript_path" ]; then
            file_mtime=$(stat -f %m "$transcript_path" 2>/dev/null || stat -c %Y "$transcript_path" 2>/dev/null || echo "0")
        else
            file_mtime="0"
        fi
        echo "${current_time}|${session_id}|${context_output}|${file_mtime}" > "$CONTEXT_CACHE_FILE"
        echo "$context_output"
    else
        echo ""
    fi
}

# Format context display with hint if empty
format_context_display() {
    local context_data="$1"
    local show_hint="${SHOW_CONTEXT_HINT:-false}"
    local hint_icon="${CONTEXT_HINT_ICON:-}"
    
    if [ -n "$context_data" ]; then
        # Return formatted context data
        echo "$context_data"
    elif [ "$show_hint" = true ] && [ -n "$hint_icon" ]; then
        # Return hint icon for missing data
        echo "$hint_icon"
    else
        # Return empty string
        echo ""
    fi
}

# Get context window color - use model color
get_context_window_color() {
    local context_data="$1"
    local model_color="$2"
    
    # Simply return the model color
    echo "$model_color"
}

# Main function to get formatted context window status
get_context_window_status() {
    local transcript_path="$1"
    local session_id="$2"
    local model_color="$3"
    
    # Check if feature is enabled
    if [ "${SHOW_CONTEXT_WINDOW:-true}" != true ]; then
        echo ""
        return
    fi
    
    # Get context usage data
    local context_data
    context_data=$(get_context_window_usage "$transcript_path" "$session_id")
    
    # Format the display
    local formatted_display
    formatted_display=$(format_context_display "$context_data")
    
    # Get appropriate color (use model color)
    local context_color
    context_color=$(get_context_window_color "$context_data" "$model_color")
    
    # Return formatted result with pipe separator
    if [ -n "$formatted_display" ]; then
        echo "${formatted_display}|${context_color}"
    else
        echo ""
    fi
}

# Export functions for use by main script
export -f get_context_window_usage 2>/dev/null || true
export -f format_context_display 2>/dev/null || true
export -f get_context_window_color 2>/dev/null || true
export -f get_context_window_status 2>/dev/null || true