#!/usr/bin/env bash
# CC CleanLine — Happy Mode management.
# Subcommands: enable | disable | test | help

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_LOCAL="${SCRIPT_DIR}/cc-cleanline.config.local"

# Colors for output (script-internal — independent of cc-cleanline.config.sh).
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

run_tests() {
    if ! command -v bats >/dev/null 2>&1; then
        echo -e "${RED}bats-core is not installed.${NC}"
        echo "Install it: brew install bats-core   (or: apt-get install bats)"
        exit 1
    fi
    if [[ ! -d "${SCRIPT_DIR}/tests/happy-mode" ]]; then
        echo -e "${RED}tests/happy-mode/ directory not found.${NC}"
        exit 1
    fi
    echo -e "${CYAN}Running Happy Mode test suite (bats)...${NC}"
    bats "${SCRIPT_DIR}/tests/happy-mode/"
}

enable_happy_mode() {
    echo -e "${PURPLE}========================================="
    echo "  🐰 Welcome to the Rabbit Hole 🐰"
    echo -e "=========================================${NC}"
    echo ""
    echo "Happy Mode adds subtle easter eggs to your statusline:"
    echo "  • Matrix references"
    echo "  • Fortune cookies after recent commits"
    echo "  • Time-based surprises (e.g. 13:37)"
    echo "  • Rare rainbow effects"
    echo "  • Achievement nudges (1M context, max effort, etc.)"
    echo ""
    echo "Defaults stay quiet: ~33% chance per trigger, 15-min cooldown."
    echo ""

    read -p "Enable Happy Mode? (y/n): " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Perhaps another time... the rabbit hole will wait. 🐰"
        return
    fi

    [[ -f "$CONFIG_LOCAL" ]] || cp "${SCRIPT_DIR}/cc-cleanline.config.example" "$CONFIG_LOCAL"

    if grep -q '^HAPPY_MODE="true"' "$CONFIG_LOCAL" 2>/dev/null \
       || grep -q '^HAPPY_MODE=true' "$CONFIG_LOCAL" 2>/dev/null; then
        echo -e "${GREEN}✓ Happy Mode is already enabled.${NC}"
        return
    fi

    sed -i.bak '/^HAPPY_MODE=/d' "$CONFIG_LOCAL" 2>/dev/null || true
    sed -i.bak '/^HAPPY_MODE_.*=/d' "$CONFIG_LOCAL" 2>/dev/null || true

    {
        echo ""
        echo "# Happy Mode — enabled by happy-mode-tools.sh"
        echo 'HAPPY_MODE="true"'
        echo 'HAPPY_MODE_MATRIX_CHANCE="33"'
        echo 'HAPPY_MODE_FORTUNE_CHANCE="33"'
        echo 'HAPPY_MODE_TIME_SURPRISES="true"'
        echo 'HAPPY_MODE_RAINBOW_CHANCE="10"'
        echo 'HAPPY_MODE_COOLDOWN_MINUTES="15"'
    } >> "$CONFIG_LOCAL"

    echo -e "${GREEN}✓ Happy Mode enabled.${NC}"
    echo -e "${PURPLE}The Matrix has you...${NC}"
}

disable_happy_mode() {
    if [[ ! -f "$CONFIG_LOCAL" ]]; then
        echo -e "${YELLOW}No config.local file. Happy Mode was never enabled.${NC}"
        return
    fi
    if ! grep -qE '^HAPPY_MODE="?true' "$CONFIG_LOCAL" 2>/dev/null; then
        echo -e "${YELLOW}Happy Mode is not currently enabled.${NC}"
        return
    fi
    sed -i.bak 's/^HAPPY_MODE="?true"?/HAPPY_MODE="false"/' "$CONFIG_LOCAL"
    echo -e "${GREEN}✓ Happy Mode disabled.${NC}"
    echo "The rabbit hole remains... waiting for your return. 🐰"
}

show_help() {
    echo -e "${CYAN}CC CleanLine — Happy Mode Tools${NC}"
    echo ""
    echo "Usage: ./happy-mode-tools.sh [command]"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo -e "  ${GREEN}test${NC}     Run the bats test suite under tests/happy-mode/"
    echo -e "  ${GREEN}enable${NC}   Set HAPPY_MODE=true in cc-cleanline.config.local"
    echo -e "  ${GREEN}disable${NC}  Set HAPPY_MODE=false in cc-cleanline.config.local"
    echo -e "  ${GREEN}help${NC}     Show this message"
    echo ""
    echo -e "${YELLOW}Quick check (no install):${NC}"
    echo "  HAPPY_MODE=test ./cc-cleanline.sh < tests/fixtures/opus-4-7-basic.json"
    echo ""
    echo -e "${YELLOW}Custom content:${NC}"
    echo "  Drop additional quotes / time triggers / achievements into:"
    echo "    happy-mode/content/matrix.txt"
    echo "    happy-mode/content/fortunes.txt"
    echo "    happy-mode/content/time-triggers.txt"
    echo "    happy-mode/content/achievements.txt"
    echo "  Comments (# ...) and blank lines are ignored."
}

case "${1:-help}" in
    test)            run_tests ;;
    enable)          enable_happy_mode ;;
    disable)         disable_happy_mode ;;
    help|--help|-h)  show_help ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo "Use './happy-mode-tools.sh help' for usage."
        exit 1
        ;;
esac
