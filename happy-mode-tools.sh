#!/usr/bin/env bash

# CC CleanLine Happy Mode Tools
# Unified tool for testing, enabling, and managing Happy Mode
# What's this? 🐰

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_LOCAL="${SCRIPT_DIR}/cc-cleanline.config.local"

# Source configurations and happy mode engine
source "${SCRIPT_DIR}/cc-cleanline.config.sh"
[[ -f "$CONFIG_LOCAL" ]] && source "$CONFIG_LOCAL"
source "${SCRIPT_DIR}/happy-mode.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test function - runs all Happy Mode tests
run_tests() {
    echo -e "${CYAN}========================================"
    echo "CC CleanLine Happy Mode Complete Test"
    echo -e "========================================${NC}"
    echo ""
    
    # Override settings for testing
    HAPPY_MODE=true
    HAPPY_MODE_MATRIX_CHANCE=100
    HAPPY_MODE_FORTUNE_CHANCE=100
    HAPPY_MODE_RAINBOW_CHANCE=100
    HAPPY_MODE_TIME_SURPRISES=true
    
    echo -e "${YELLOW}1. Testing Matrix Quotes:${NC}"
    echo "-------------------------"
    for i in {1..3}; do
        echo "   $(get_matrix_quote)"
    done
    echo ""
    
    echo -e "${YELLOW}2. Testing Fortune Cookies:${NC}"
    echo "---------------------------"
    for i in {1..3}; do
        echo "   $(get_fortune_cookie)"
    done
    echo ""
    
    echo -e "${YELLOW}3. Testing Rainbow Text:${NC}"
    echo "------------------------"
    rainbow_text "This text should be in rainbow colors!"
    echo ""
    
    echo -e "${YELLOW}4. Testing Time-Based Surprises:${NC}"
    echo "--------------------------------"
    # Mock different times
    original_date=$(which date)
    date() {
        if [[ "$1" == "+%H%M" ]]; then
            echo "1337"  # Return 13:37 for testing
        elif [[ "$1" == "+%H" ]]; then
            echo "03"    # Return 3 AM for testing
        else
            $original_date "$@"
        fi
    }
    echo "   At 13:37: $(get_time_surprise)"
    # Restore original date
    unset -f date
    echo ""
    
    echo -e "${YELLOW}5. Testing Cooldown System:${NC}"
    echo "---------------------------"
    rm -f /tmp/.cc-happy-last-$(whoami) 2>/dev/null
    if check_cooldown; then
        echo -e "   ${GREEN}✓${NC} Cooldown check passed (no cooldown file)"
    fi
    update_cooldown
    if ! check_cooldown; then
        echo -e "   ${GREEN}✓${NC} Cooldown active after update"
    fi
    echo ""
    
    echo -e "${YELLOW}6. Testing Complete Trigger:${NC}"
    echo "----------------------------"
    rm -f /tmp/.cc-happy-last-$(whoami) 2>/dev/null
    HAPPY_MODE_MATRIX_CHANCE=100
    echo "   Commit context:"
    trigger_happy_mode "commit"
    echo ""
    
    echo -e "${YELLOW}7. Testing Rainbow Branch Name:${NC}"
    echo "-------------------------------"
    HAPPY_MODE_RAINBOW_CHANCE=100
    echo -n "   Branch 'main' in rainbow: "
    generate_rainbow_branch "main"
    echo ""
    
    echo -e "${CYAN}========================================"
    echo "Test Complete!"
    echo -e "========================================${NC}"
}

# Enable Happy Mode
enable_happy_mode() {
    echo -e "${PURPLE}========================================="
    echo "  🐰 Welcome to the Rabbit Hole 🐰"
    echo -e "=========================================${NC}"
    echo ""
    echo "You've discovered Happy Mode!"
    echo "This will enable easter eggs and surprises in your status line."
    echo ""
    echo -e "${CYAN}Features include:${NC}"
    echo "  • Matrix references (\"Follow the white rabbit...\")"
    echo "  • Fortune cookies after commits"
    echo "  • Time-based surprises (like 13:37 elite mode)"
    echo "  • Very rare rainbow effects"
    echo "  • Special milestone celebrations"
    echo ""
    echo "Happy Mode is designed to be subtle and non-intrusive."
    echo "Surprises appear rarely (33% chance) with a 15-minute cooldown."
    echo ""
    
    read -p "Enable Happy Mode? (y/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Check if config.local exists
        if [[ ! -f "$CONFIG_LOCAL" ]]; then
            cp "${SCRIPT_DIR}/cc-cleanline.config.example" "$CONFIG_LOCAL"
        fi
        
        # Check if HAPPY_MODE is already set
        if grep -q "^HAPPY_MODE=true" "$CONFIG_LOCAL" 2>/dev/null; then
            echo -e "${GREEN}✓ Happy Mode is already enabled!${NC}"
        else
            # Remove any existing HAPPY_MODE settings
            sed -i.bak '/^HAPPY_MODE=/d' "$CONFIG_LOCAL" 2>/dev/null
            sed -i.bak '/^HAPPY_MODE_.*=/d' "$CONFIG_LOCAL" 2>/dev/null
            
            # Add Happy Mode settings
            echo "" >> "$CONFIG_LOCAL"
            echo "# Happy Mode - Enabled by happy-mode-tools.sh" >> "$CONFIG_LOCAL"
            echo "HAPPY_MODE=true" >> "$CONFIG_LOCAL"
            echo "HAPPY_MODE_MATRIX_CHANCE=33" >> "$CONFIG_LOCAL"
            echo "HAPPY_MODE_FORTUNE_CHANCE=33" >> "$CONFIG_LOCAL"
            echo "HAPPY_MODE_TIME_SURPRISES=true" >> "$CONFIG_LOCAL"
            echo "HAPPY_MODE_RAINBOW_CHANCE=10" >> "$CONFIG_LOCAL"
            echo "HAPPY_MODE_COOLDOWN_MINUTES=15" >> "$CONFIG_LOCAL"
            
            echo -e "${GREEN}✓ Happy Mode has been enabled!${NC}"
            echo ""
            echo -e "${PURPLE}The Matrix has you...${NC}"
        fi
    else
        echo "Perhaps another time..."
        echo "The rabbit hole will wait for you."
    fi
}

# Disable Happy Mode
disable_happy_mode() {
    echo -e "${YELLOW}Disabling Happy Mode...${NC}"
    
    if [[ ! -f "$CONFIG_LOCAL" ]]; then
        echo -e "${RED}No config.local file found. Happy Mode was not enabled.${NC}"
        return
    fi
    
    # Check if Happy Mode is enabled
    if ! grep -q "^HAPPY_MODE=true" "$CONFIG_LOCAL" 2>/dev/null; then
        echo -e "${YELLOW}Happy Mode is not currently enabled.${NC}"
        return
    fi
    
    # Set HAPPY_MODE to false instead of removing
    sed -i.bak 's/^HAPPY_MODE=true/HAPPY_MODE=false/' "$CONFIG_LOCAL"
    
    echo -e "${GREEN}✓ Happy Mode has been disabled.${NC}"
    echo "The rabbit hole remains... waiting for your return. 🐰"
}

# Show help and documentation
show_help() {
    echo -e "${CYAN}========================================"
    echo "CC CleanLine Happy Mode Tools"
    echo -e "========================================${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  ./happy-mode-tools.sh [command]"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo -e "  ${GREEN}test${NC}     - Run comprehensive Happy Mode tests"
    echo -e "  ${GREEN}enable${NC}   - Enable Happy Mode in your status line"
    echo -e "  ${GREEN}disable${NC}  - Disable Happy Mode"
    echo -e "  ${GREEN}help${NC}     - Show this help message"
    echo ""
    echo -e "${YELLOW}Test Mode:${NC}"
    echo "  Set HAPPY_MODE=test in cc-cleanline.config.local"
    echo "  to see all features with high probability (75%)"
    echo ""
    echo -e "${YELLOW}Configuration:${NC}"
    echo "  Edit cc-cleanline.config.local to customize:"
    echo "  • HAPPY_MODE_MATRIX_CHANCE (33% recommended)"
    echo "  • HAPPY_MODE_FORTUNE_CHANCE (33% recommended)"
    echo "  • HAPPY_MODE_RAINBOW_CHANCE (10% recommended)"
    echo "  • HAPPY_MODE_COOLDOWN_MINUTES (15 recommended)"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  ./happy-mode-tools.sh test    # Run all tests"
    echo "  ./happy-mode-tools.sh enable  # Enable Happy Mode"
    echo "  ./happy-mode-tools.sh disable # Disable Happy Mode"
    echo ""
    echo -e "${PURPLE}What's this? 🐰${NC}"
    echo "Some say there are hidden pathways in the configuration files..."
    echo "The rabbit hole goes deeper than you think."
}

# Main command handler
case "$1" in
    test)
        run_tests
        ;;
    enable)
        enable_happy_mode
        ;;
    disable)
        disable_happy_mode
        ;;
    help|--help|-h|"")
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo "Use './happy-mode-tools.sh help' for usage information"
        exit 1
        ;;
esac