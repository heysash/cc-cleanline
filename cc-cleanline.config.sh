#!/usr/bin/env bash

# ====================================================================
# CC CleanLine — default configuration
# ====================================================================
# All settings live here. To override anything, copy
# cc-cleanline.config.example to cc-cleanline.config.local and edit
# the .local file. The .local file is git-ignored.
# ====================================================================

# --------------------------------------------------------------------
# COLOR DEFINITIONS  (256-colour ANSI codes)
# --------------------------------------------------------------------

# Severity colours
COLOR_ACTIVE_STATUS='\033[92m'          # Bright green   — Low / OK
COLOR_INACTIVE_STATUS='\033[38;5;196m'  # Red            — Inactive (e.g. no git repo)
COLOR_CRITICAL_STATUS='\033[38;5;196m'  # Red            — Critical state
COLOR_ORANGE='\033[38;5;208m'           # Orange         — Medium usage
COLOR_RED='\033[38;5;196m'              # Red            — High usage

# Model colours
COLOR_OPUS='\033[38;5;215m'             # Sandybrown     — Opus (current)
COLOR_OPUS_LEGACY='\033[38;5;180m'      # Dimmed         — Opus (legacy)
COLOR_SONNET='\033[38;5;130m'           # Saddlebrown    — Sonnet (current)
COLOR_SONNET_LEGACY='\033[38;5;101m'    # Dimmed         — Sonnet (legacy)
COLOR_HAIKU='\033[38;5;117m'            # Sky-blue       — Haiku (current)
COLOR_HAIKU_LEGACY='\033[38;5;110m'     # Dimmed         — Haiku (legacy)
COLOR_DEPRECATED='\033[38;5;240m'       # Dark grey      — Deprecated models
COLOR_DEFAULT_MODEL='\033[38;5;248m'    # Light grey     — Unknown model

# UI element colours
COLOR_NEUTRAL_TEXT='\033[90m'           # Terminal grey  — Neutral text
COLOR_RESET='\033[0m'                   # Reset

# --------------------------------------------------------------------
# ICON DEFINITIONS
# --------------------------------------------------------------------
ICON_ACTIVE="●"
ICON_INACTIVE="○"
ICON_WARNING="⚠"
ICON_CHECK="✓"

# --------------------------------------------------------------------
# DISPLAY SETTINGS
# --------------------------------------------------------------------

# Path rendering
SHOW_FULL_PATH=false                    # false → "./dirname"; true → absolute path

# Token display
SHOW_TOKEN_ABSOLUTE=true                # "59.0k" in the context segment
SHOW_TOKEN_PERCENT_TOTAL=true           # "29.5%" in the context segment

# Model-name decorations
SHOW_EFFORT_BADGE=true                  # 4-star effort meter (☆☆☆☆ … ★★★★) next to model
SHOW_1M_BADGE=true                      # ¹ᴹ next to Opus 4.7 etc. when [1m]
SHOW_LEGACY_MARKER=true                 # ⚠legacy hint for old model IDs

# Adaptive optional lines
SHOW_WORKTREE_LINE=true                 # Line 4 when worktree.name is set
SHOW_EXTRAS_LINE=true                   # Line 5 (style / vim / PR)
SHOW_VERSION=false                      # Append "v2.1.150" to line 5

# --------------------------------------------------------------------
# HAPPY MODE  (easter eggs — opt-in)
# --------------------------------------------------------------------
# All values use ${VAR:-default} so existing environment variables win
# (handy for CI, tests, and one-shot debugging).
HAPPY_MODE="${HAPPY_MODE:-false}"                                # true | false | test
HAPPY_MODE_MATRIX_CHANCE="${HAPPY_MODE_MATRIX_CHANCE:-33}"       # %, accepts floats
HAPPY_MODE_FORTUNE_CHANCE="${HAPPY_MODE_FORTUNE_CHANCE:-33}"     # %, after recent commit
HAPPY_MODE_TIME_SURPRISES="${HAPPY_MODE_TIME_SURPRISES:-true}"   # enable time-based pings
HAPPY_MODE_RAINBOW_CHANCE="${HAPPY_MODE_RAINBOW_CHANCE:-10}"     # %, rare rainbow effect
HAPPY_MODE_COOLDOWN_MINUTES="${HAPPY_MODE_COOLDOWN_MINUTES:-15}" # minutes between surprises
