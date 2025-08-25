# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

CC CleanLine is a modular shell script system that provides a clean, minimalist status line for Claude Code. It follows clean code philosophy with focused, single-responsibility modules under 180 lines each for optimal LLM processing.

## Commands

### Main Operations

- `./cc-cleanline.sh` - Run the main status line script (requires JSON input from Claude Code)
- `chmod +x cc-cleanline.sh` - Make script executable after cloning

### Testing and Development

- `./happy-mode-tools.sh test` - Run comprehensive Happy Mode easter egg tests
- `./happy-mode-tools.sh enable` - Enable Happy Mode features  
- `./happy-mode-tools.sh disable` - Disable Happy Mode features

### Configuration

- `cp cc-cleanline.config.example cc-cleanline.config.local` - Create local config overrides
- Edit `cc-cleanline.config.local` for personal customization (git-ignored)

## Architecture

### Core Design

- **Modular Architecture**: Main script (`cc-cleanline.sh`) orchestrates specialized modules
- **Configuration System**: Two-tier system with base config (`cc-cleanline.config.sh`) and local overrides (`cc-cleanline.config.local`)
- **Module Loading**: Automatic discovery and sourcing of all `lib/*.sh` files at startup
- **JSON Processing**: Processes Claude Code JSON input via stdin using `jq`

### Module Responsibilities

- **`lib/git-status.sh`** (61 lines) - Git repository detection and branch analysis with change tracking (+/-lines)
- **`lib/cost-tracking.sh`** (179 lines) - Token usage and API cost calculation via ccusage integration  
- **`lib/model-detection.sh`** (52 lines) - Claude model identification and color mapping (Sonnet=saddlebrown, Opus=sandybrown)
- **`lib/display-formatter.sh`** (112 lines) - Status line output formatting and color application (3-line output)
- **`lib/happy-mode-integration.sh`** (44 lines) - Easter egg system integration for experimental features

### Happy Mode System

- **Easter Egg Framework**: Complete system in `happy-mode.sh` and `happy-mode-tools.sh`
- **Configuration Hooks**: Activated via `HAPPY_MODE=true` in config without main script modification
- **Test Framework**: Built-in testing with `happy-mode-tools.sh test`
- **Features**: Matrix references, fortune cookies, time-based messages, rainbow effects with configurable chances and cooldowns

### Dependencies

- **Required**: `bash`, `jq` (JSON parsing), Claude Code CLI
- **Optional**: `git` (branch detection), `bunx`/`npx` (ccusage cost tracking)

## Key Configuration Patterns

### Local Configuration Override

Always use `cc-cleanline.config.local` for customizations:

```bash
# Only include variables you want to change
COLOR_ACTIVE_STATUS='\033[94m'    # Blue instead of green
SHOW_FULL_PATH=true               # Show full directory paths  
HAPPY_MODE=true                   # Enable easter eggs
```

### Model Color Mapping

- **Opus 4.1**: Sandybrown (`COLOR_OPUS='\033[38;5;215m'`)
- **Sonnet 4**: Saddlebrown (`COLOR_SONNET='\033[38;5;130m'`)
- **Unknown**: Darkgray (`COLOR_DEFAULT_MODEL='\033[38;5;248m'`)

### Status Output Format

Fixed 3-line output structure:

1. Git status + directory path
2. Login status + model info + session time
3. Token usage + API costs

## File Structure Notes

- **Module Integrity**: All `lib/*.sh` modules must remain intact for proper functionality
- **Configuration Precedence**: Local config overrides default config, loaded before modules
- **Git Ignore**: `cc-cleanline.config.local` is automatically git-ignored for personal settings
- **Error Handling**: Graceful fallbacks when optional dependencies are missing
