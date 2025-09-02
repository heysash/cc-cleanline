#!/bin/bash
# Context metrics module for CC CleanLine
# Calculates context length from JSONL transcript using token data

# Cache variables for performance
CONTEXT_METRICS_CACHE_FILE="/tmp/cc-cleanline-context-metrics-cache"
CONTEXT_METRICS_CACHE_TTL="${CONTEXT_METRICS_CACHE_TTL:-5}"  # 5 seconds cache

# Parse JSONL and extract context metrics
parse_jsonl_for_context() {
    local transcript_path="$1"
    local session_id="$2"
    
    # Return empty if no transcript path
    if [ -z "$transcript_path" ] || [ "$transcript_path" = "null" ] || [ ! -f "$transcript_path" ]; then
        echo "0|0|0|0"
        return
    fi
    
    # Check cache first
    if [ -f "$CONTEXT_METRICS_CACHE_FILE" ]; then
        local cache_content
        cache_content=$(cat "$CONTEXT_METRICS_CACHE_FILE" 2>/dev/null)
        if [ -n "$cache_content" ]; then
            local cache_timestamp cache_session cache_data cache_file_mtime
            cache_timestamp=$(echo "$cache_content" | cut -d'|' -f1)
            cache_session=$(echo "$cache_content" | cut -d'|' -f2)
            cache_file_mtime=$(echo "$cache_content" | cut -d'|' -f3)
            cache_data=$(echo "$cache_content" | cut -d'|' -f4-)
            
            local current_time current_file_mtime
            current_time=$(date +%s)
            local cache_age=$((current_time - cache_timestamp))
            
            # Get current file modification time
            if [ "$(uname)" = "Darwin" ]; then
                current_file_mtime=$(stat -f %m "$transcript_path" 2>/dev/null || echo "0")
            else
                current_file_mtime=$(stat -c %Y "$transcript_path" 2>/dev/null || echo "0")
            fi
            
            # Return cached data if valid
            if [ "$cache_session" = "$session_id" ] && \
               [ "$cache_age" -lt "$CONTEXT_METRICS_CACHE_TTL" ] && \
               [ "$cache_file_mtime" = "$current_file_mtime" ]; then
                echo "$cache_data"
                return
            fi
        fi
    fi
    
    # Parse JSONL with jq
    local metrics
    metrics=$(jq -rs '
        # Collect all token data
        def sum_tokens: 
            map(select(.message.usage)) 
            | map(.message.usage) 
            | {
                input: (map(.input_tokens // 0) | add),
                output: (map(.output_tokens // 0) | add),
                cached: (map((.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0)) | add)
            };
        
        # Find most recent main chain entry for context length
        def latest_main_chain:
            map(select(.message.usage and (.isSidechain != true) and .timestamp))
            | sort_by(.timestamp)
            | last
            | if . then 
                .message.usage | 
                ((.input_tokens // 0) + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0))
              else 0 end;
        
        # Combine results
        . as $all |
        ($all | sum_tokens) as $totals |
        ($all | latest_main_chain) as $context |
        "\($totals.input)|\($totals.output)|\($totals.cached)|\($context)"
    ' "$transcript_path" 2>/dev/null || echo "0|0|0|0")
    
    # Cache the result
    if [ -n "$metrics" ] && [ "$metrics" != "0|0|0|0" ]; then
        local current_time file_mtime
        current_time=$(date +%s)
        if [ "$(uname)" = "Darwin" ]; then
            file_mtime=$(stat -f %m "$transcript_path" 2>/dev/null || echo "0")
        else
            file_mtime=$(stat -c %Y "$transcript_path" 2>/dev/null || echo "0")
        fi
        echo "${current_time}|${session_id}|${file_mtime}|${metrics}" > "$CONTEXT_METRICS_CACHE_FILE"
    fi
    
    echo "$metrics"
}

# Format token count with k/M suffixes
format_tokens() {
    local count="$1"
    
    if [ "$count" -ge 1000000 ]; then
        # Use awk for decimal division
        echo "$(echo "$count" | awk '{printf "%.1fM", $1/1000000}')"
    elif [ "$count" -ge 1000 ]; then
        echo "$(echo "$count" | awk '{printf "%.1fk", $1/1000}')"
    else
        echo "$count"
    fi
}

# Format context length display
format_context_length() {
    local context_length="$1"
    local format="${CONTEXT_LENGTH_FORMAT:-short}"
    
    if [ "$context_length" -eq 0 ]; then
        echo ""
        return
    fi
    
    if [ "$format" = "full" ]; then
        echo "Ctx: $context_length"
    else
        local formatted
        formatted=$(format_tokens "$context_length")
        echo "Ctx: ${formatted}"
    fi
}

# Format context percentage (of 200k limit)
format_context_percentage() {
    local context_length="$1"
    
    if [ "$context_length" -eq 0 ]; then
        echo ""
        return
    fi
    
    local percentage
    percentage=$(echo "$context_length" | awk '{printf "%.1f", ($1/200000)*100}')
    
    # Cap at 100%
    if [ "$(echo "$percentage > 100" | bc -l 2>/dev/null || echo "0")" = "1" ]; then
        percentage="100.0"
    fi
    
    echo "Ctx: ${percentage}%"
}

# Format context percentage usable (of 160k limit before auto-compact)
format_context_percentage_usable() {
    local context_length="$1"
    
    if [ "$context_length" -eq 0 ]; then
        echo ""
        return
    fi
    
    local percentage
    percentage=$(echo "$context_length" | awk '{printf "%.1f", ($1/160000)*100}')
    
    # Cap at 100%
    if [ "$(echo "$percentage > 100" | bc -l 2>/dev/null || echo "0")" = "1" ]; then
        percentage="100.0"
    fi
    
    echo "Ctx(u): ${percentage}%"
}

# Main function to get formatted context status
get_context_metrics_status() {
    local transcript_path="$1"
    local session_id="$2"
    local model_color="$3"
    
    # Parse metrics from JSONL
    local metrics
    metrics=$(parse_jsonl_for_context "$transcript_path" "$session_id")
    
    # Extract context length (4th field)
    local context_length
    context_length=$(echo "$metrics" | cut -d'|' -f4)
    
    # Build display based on config
    local display_parts=()
    
    if [ "${SHOW_CONTEXT_LENGTH:-false}" = true ]; then
        local ctx_display
        ctx_display=$(format_context_length "$context_length")
        [ -n "$ctx_display" ] && display_parts+=("$ctx_display")
    fi
    
    if [ "${SHOW_CONTEXT_PERCENTAGE:-false}" = true ]; then
        local ctx_pct_display
        ctx_pct_display=$(format_context_percentage "$context_length")
        [ -n "$ctx_pct_display" ] && display_parts+=("$ctx_pct_display")
    fi
    
    if [ "${SHOW_CONTEXT_PERCENTAGE_USABLE:-true}" = true ]; then
        local ctx_pct_usable_display
        ctx_pct_usable_display=$(format_context_percentage_usable "$context_length")
        [ -n "$ctx_pct_usable_display" ] && display_parts+=("$ctx_pct_usable_display")
    fi
    
    # Join display parts with space
    local final_display=""
    for part in "${display_parts[@]}"; do
        if [ -z "$final_display" ]; then
            final_display="$part"
        else
            final_display="$final_display $part"
        fi
    done
    
    # Return formatted result with pipe separator for color
    if [ -n "$final_display" ]; then
        echo "${final_display}|${model_color}"
    else
        echo ""
    fi
}

# Export functions for use by main script
export -f parse_jsonl_for_context 2>/dev/null || true
export -f format_tokens 2>/dev/null || true
export -f format_context_length 2>/dev/null || true
export -f format_context_percentage 2>/dev/null || true
export -f format_context_percentage_usable 2>/dev/null || true
export -f get_context_metrics_status 2>/dev/null || true