#!/bin/bash
# Rainbow text utility — isolated so non-easter-egg modules (git-status, etc.)
# can also colourise output without pulling in the whole happy-mode engine.

# rainbow_text <text>
# Outputs an ANSI-coloured rainbow rendering of <text>. Spaces are preserved
# uncoloured. The output ends with a reset sequence.
rainbow_text() {
    local text="$1"
    local result=""
    local colors=(196 208 226 46 21 93)  # Red Orange Yellow Green Blue Purple
    local i=0
    local j char
    for (( j = 0; j < ${#text}; j++ )); do
        char="${text:$j:1}"
        if [[ "$char" != ' ' ]]; then
            result+="\033[38;5;${colors[$i]}m${char}"
            i=$(( (i + 1) % ${#colors[@]} ))
        else
            result+=' '
        fi
    done
    result+='\033[0m'
    echo -e "$result"
}

export -f rainbow_text 2>/dev/null || true
