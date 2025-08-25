#!/bin/bash
# Model detection module for CC CleanLine
# Handles model name detection, formatting, and color assignment

# Function to get model information
get_model_info() {
    local model_name="$1"
    local model_display=""
    local model_info=""
    local model_color=""
    
    # Determine model info based on model name
    if [[ "$model_name" == *"sonnet"* ]] || [[ "$model_name" == *"Sonnet"* ]]; then
        model_display="Sonnet 4"
        model_info="☆ ${LABEL_MODEL} ${model_display}"
        model_color="$COLOR_SONNET"
    elif [[ "$model_name" == *"opus"* ]] || [[ "$model_name" == *"Opus"* ]]; then
        model_display="Opus 4.1"
        model_info="★ ${LABEL_MODEL} ${model_display}"
        model_color="$COLOR_OPUS"
    else
        model_display="${model_name}"
        model_info="${ICON_ACTIVE} ${LABEL_MODEL} ${model_display}"
        model_color="$COLOR_DEFAULT_MODEL"
    fi
    
    # Apply rainbow effect to model name rarely in Happy Mode
    if [[ "$HAPPY_MODE" == "true" || "$HAPPY_MODE" == "test" ]] && command -v rainbow_text >/dev/null 2>&1; then
        # Higher chance in test mode
        local model_rainbow_chance=500
        if [[ "$HAPPY_MODE" == "test" ]]; then
            model_rainbow_chance=5
        fi
        
        if [[ $((RANDOM % $model_rainbow_chance)) -eq 0 ]]; then
            model_display=$(rainbow_text "$model_display")
            if [[ "$model_name" == *"sonnet"* ]] || [[ "$model_name" == *"Sonnet"* ]]; then
                model_info="☆ ${LABEL_MODEL} ${model_display}"
            elif [[ "$model_name" == *"opus"* ]] || [[ "$model_name" == *"Opus"* ]]; then
                model_info="★ ${LABEL_MODEL} ${model_display}"
            else
                model_info="${ICON_ACTIVE} ${LABEL_MODEL} ${model_display}"
            fi
            model_color=""  # No color needed, rainbow has its own
        fi
    fi
    
    # Return model info and color
    echo "${model_info}|${model_color}"
}

# Export function for use by main script
export -f get_model_info 2>/dev/null || true