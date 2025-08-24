#!/usr/bin/env bash
# CC CleanLine Happy Mode Engine
# What's this? 🐰

# Matrix quotes - expanded collection
MATRIX_QUOTES=(
    "Follow the white rabbit..."
    "There is no spoon"
    "Wake up, Neo..."
    "The Matrix has you..."
    "Welcome to the real world"
    "Free your mind"
    "I know kung fu"
    "Dodge this"
    "You think that's air you're breathing now?"
    "Unfortunately, no one can be told what the Matrix is"
    "You have to see it for yourself"
    "The answer is out there, Neo"
    "It's the question that drives us"
    "What is real?"
    "There is a difference between knowing the path and walking the path"
    "Everything begins with choice"
    "The code is everywhere"
    "You're the One, Neo"
    "Choice. The problem is choice"
    "Fate, it seems, is not without a sense of irony"
    "Hope. It is the quintessential human delusion"
    "Why do my eyes hurt? You've never used them before"
)

# Fortune cookies - developer wisdom
FORTUNE_COOKIES=(
    "Your code compiles... but does it dream?"
    "That semicolon just saved humanity"
    "A missing bracket today is a production bug tomorrow"
    "The bug is not in the code, it's in the specs"
    "Today's git push will become tomorrow's git revert"
    "Your future holds many merge conflicts"
    "A clean commit message brings good karma"
    "The answer you seek is in the stack trace"
    "Beware of copy-paste, for it brings ancient curses"
    "Your rubber duck has all the answers"
    "The senior dev you seek is within yourself"
    "Coffee is the source of all refactoring"
    "This too shall pass... all tests"
    "Your code review will reveal hidden wisdom"
    "The bug you cannot find has already found you"
    "A thousand-line function awaits simplification"
    "Your variable names shall confuse future you"
    "The TODO you write today will outlive us all"
    "Legacy code is just code that works"
    "Your next npm install will succeed... eventually"
)

# Time-based messages
TIME_MESSAGES=(
    "1337:Welcome to 1337 h4x0r mode"
    "0000:Midnight coding session detected. Coffee recommended"
    "0300:3 AM? The witching hour of debugging"
    "0404:Error 404: Sleep not found"
    "1111:Make a wish at 11:11"
    "1234:1-2-3-4, the code flows in order"
    "1337:Elite time has arrived"
    "2359:One minute until tomorrow's bugs"
    "0042:The answer to everything is near"
    "0101:Binary time: 01:01"
    "2222:All the twos align"
    "1010:Binary 10:10 - perfectly balanced"
)

# Achievement messages (for future implementation)
ACHIEVEMENTS=(
    "🏆 Achievement Unlocked: First Happy Mode trigger!"
    "🎯 Achievement: 10 commits without conflicts!"
    "⚡ Achievement: Speed Coder - 1000 tokens/minute"
    "🌟 Achievement: Night Owl - Coding past midnight"
    "🔥 Achievement: On Fire - 5 hour coding streak"
)

# File paths and state
COOLDOWN_FILE="/tmp/.cc-happy-last-$(whoami)"
ACHIEVEMENT_FILE="/tmp/.cc-happy-achievements-$(whoami)"

# Helper functions
is_happy_mode_enabled() { 
    [[ "$HAPPY_MODE" == "true" || "$HAPPY_MODE" == "test" ]] 
}

# Check if in test mode
is_test_mode() {
    [[ "$HAPPY_MODE" == "test" ]]
}

# Check if chance hits (accepts float percentages)
hits_chance() { 
    local chance="${1%%.*}"
    [[ $((RANDOM % 100)) -lt ${chance:-1} ]] 
}

# Check cooldown (disabled in test mode)
check_cooldown() {
    # In test mode, always allow triggers
    if is_test_mode; then
        return 0
    fi
    
    if [[ ! -f "$COOLDOWN_FILE" ]]; then
        return 0  # No cooldown file, allow trigger
    fi
    
    local last_trigger=$(cat "$COOLDOWN_FILE" 2>/dev/null || echo "0")
    local current_time=$(date +%s)
    local cooldown_seconds=$((${HAPPY_MODE_COOLDOWN_MINUTES:-15} * 60))
    local time_diff=$((current_time - last_trigger))
    
    [[ $time_diff -gt $cooldown_seconds ]]
}

# Update cooldown
update_cooldown() {
    date +%s > "$COOLDOWN_FILE"
}

# Get random Matrix quote
get_matrix_quote() { 
    echo "${MATRIX_QUOTES[$((RANDOM % ${#MATRIX_QUOTES[@]}))]}" 
}

# Get random fortune cookie
get_fortune_cookie() { 
    echo "${FORTUNE_COOKIES[$((RANDOM % ${#FORTUNE_COOKIES[@]}))]}" 
}

# Get time-based surprise
get_time_surprise() {
    if [[ "$HAPPY_MODE_TIME_SURPRISES" != "true" ]]; then
        return
    fi
    
    local current_time=$(date +%H%M)
    
    for time_msg in "${TIME_MESSAGES[@]}"; do
        local trigger_time="${time_msg%%:*}"
        local message="${time_msg#*:}"
        
        if [[ "$current_time" == "$trigger_time" ]]; then
            echo "⏰ $message"
            return
        fi
    done
    
    # Special late night messages
    local hour=$(date +%H)
    if [[ $hour -ge 2 && $hour -le 5 ]]; then
        if hits_chance 10; then
            echo "🦉 Night owl detected. Code responsibly!"
        fi
    fi
}

# Generate rainbow text (ANSI escape sequences)
rainbow_text() {
    local text="$1"
    local result=""
    local colors=(196 208 226 46 21 93)  # Red Orange Yellow Green Blue Purple
    local i=0
    
    for (( j=0; j<${#text}; j++ )); do
        local char="${text:$j:1}"
        if [[ "$char" != " " ]]; then
            result+="\033[38;5;${colors[$i]}m$char"
            i=$(( (i + 1) % ${#colors[@]} ))
        else
            result+=" "
        fi
    done
    result+="\033[0m"
    
    echo -e "$result"
}

# Check for special conditions
check_special_conditions() {
    local condition="$1"
    
    # Check for long session
    if [[ "$condition" == "long_session" ]]; then
        local session_hours="${2:-0}"
        if [[ $session_hours -ge 4 ]]; then
            if hits_chance 20; then
                echo "⚡ Wow, ${session_hours}h session! The code must flow!"
                return 0
            fi
        fi
    fi
    
    # Check for git milestone
    if [[ "$condition" == "git_milestone" ]]; then
        local commit_count=$(git rev-list --count HEAD 2>/dev/null || echo "0")
        if [[ $((commit_count % 100)) -eq 0 && $commit_count -gt 0 ]]; then
            echo "🎉 Milestone: Commit #$commit_count!"
            return 0
        fi
    fi
    
    return 1
}

# Main trigger function
trigger_happy_mode() {
    local context="$1"
    local extra_param="$2"
    
    # Check if enabled and cooldown
    if ! is_happy_mode_enabled; then 
        return
    fi
    
    if ! check_cooldown; then
        return
    fi
    
    local triggered=false
    
    # In test mode, set high chances and show multiple features
    local matrix_chance="${HAPPY_MODE_MATRIX_CHANCE:-33}"
    local fortune_chance="${HAPPY_MODE_FORTUNE_CHANCE:-33}"
    local rainbow_chance="${HAPPY_MODE_RAINBOW_CHANCE:-10}"
    
    if is_test_mode; then
        matrix_chance=75
        fortune_chance=75
        rainbow_chance=50
        echo "🧪 Happy Mode Test Active - Showing multiple features:"
    fi
    
    # Matrix quotes (always possible)
    if hits_chance "$matrix_chance"; then
        echo "🐰 $(get_matrix_quote)"
        triggered=true
    fi
    
    # Context-specific triggers
    case "$context" in
        "commit")
            if hits_chance "$fortune_chance"; then
                echo "🥠 $(get_fortune_cookie)"
                triggered=true
            fi
            ;;
        
        "status")
            # Time-based surprises
            local time_msg=$(get_time_surprise)
            if [[ -n "$time_msg" ]]; then
                echo "$time_msg"
                triggered=true
            fi
            
            # In test mode, force show time surprises
            if is_test_mode && [[ -z "$time_msg" ]]; then
                echo "⏰ Test time surprise: The clock strikes development time!"
                triggered=true
            fi
            
            # Special condition checks
            check_special_conditions "long_session" "$extra_param"
            ;;
        
        "git")
            check_special_conditions "git_milestone"
            ;;
    esac
    
    # Rainbow effect (very rare)
    if hits_chance "$rainbow_chance"; then
        echo "$(rainbow_text '🌈 You found the rainbow mode! 🌈')"
        triggered=true
    fi
    
    # Update cooldown only if something was triggered (except in test mode)
    if [[ "$triggered" == "true" ]] && ! is_test_mode; then
        update_cooldown
    fi
}

# Generate rainbow branch name (for external use)
generate_rainbow_branch() {
    local branch="$1"
    local chance="${HAPPY_MODE_RAINBOW_CHANCE:-10}"
    
    # In test mode, use higher chance
    if is_test_mode; then
        chance=30
    fi
    
    if is_happy_mode_enabled && hits_chance "$chance"; then
        rainbow_text "$branch"
    else
        echo "$branch"
    fi
}

# Test mode for development
if [[ "$1" == "test" ]]; then
    HAPPY_MODE=true
    HAPPY_MODE_MATRIX_CHANCE=80
    HAPPY_MODE_FORTUNE_CHANCE=80
    HAPPY_MODE_RAINBOW_CHANCE=50
    HAPPY_MODE_TIME_SURPRISES=true
    echo "=== Happy Mode Test ==="
    trigger_happy_mode "test"
    echo "Rainbow test: $(rainbow_text 'Hello World!')"
    echo "Time surprise: $(get_time_surprise)"
fi