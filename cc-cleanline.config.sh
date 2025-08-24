#!/usr/bin/env bash

# ====================================================================
# Claude Code Status Line Configuration
# ====================================================================
# This file contains all customizable settings for the status line
# including colors, labels, icons and display preferences.
# ====================================================================

# --------------------------------------------------------------------
# COLOR DEFINITIONS
# --------------------------------------------------------------------
# Terminal color codes for different status states and UI elements

# Status Colors
COLOR_ACTIVE_STATUS='\033[92m'          # Light green - Active/connected state (consistent bright green)
COLOR_INACTIVE_STATUS='\033[38;5;196m'  # Red - Inactive/disconnected state
COLOR_CRITICAL_STATUS='\033[38;5;196m'  # Red - Critical state
COLOR_ORANGE='\033[38;5;208m'           # Orange - Medium usage
COLOR_RED='\033[38;5;196m'              # Red - High usage

# Model Colors
COLOR_OPUS='\033[38;5;215m'             # Sandybrown #F4A460 - Opus model
COLOR_SONNET='\033[38;5;130m'           # Saddlebrown #8B4513 - Sonnet model  
COLOR_DEFAULT_MODEL='\033[38;5;248m'    # Darkgray #A9A9A9 - Unknown model

# UI Element Colors
COLOR_NEUTRAL_TEXT='\033[90m'             # Standard terminal gray - Neutral text  
COLOR_RESET='\033[0m'                     # Reset to default

# --------------------------------------------------------------------
# ICON DEFINITIONS
# --------------------------------------------------------------------
# Unicode icons for different status indicators

# Status Icons
ICON_ACTIVE="●"                         # Active/connected indicator
ICON_INACTIVE="○"                       # Inactive/disconnected indicator
ICON_WARNING="⚠"                        # Warning indicator
ICON_CHECK="✓"                          # Success/okay indicator

# --------------------------------------------------------------------
# LABEL DEFINITIONS
# --------------------------------------------------------------------
# Text labels for different status line elements

# Active Status Labels
LABEL_LOGGED_IN="Logged-In"             # User is logged in

# Inactive Status Labels  
LABEL_NOT_LOGGED_IN="Not logged in"     # User not logged in

# Field Labels
LABEL_MODEL="LLM"                       # Model field label

# --------------------------------------------------------------------
# DISPLAY SETTINGS (TODO)
# --------------------------------------------------------------------
# Configure what information to show and how

# Feature Toggles
# SHOW_USER_STATUS=true                   # Show user login status
# SHOW_CONTEXT_STATUS=true                # Show context window status
# SHOW_MODEL_INFO=true                    # Show current model
# SHOW_TOKEN_COUNT=true                   # Show token usage
# SHOW_COST_INFO=true                     # Show estimated cost

# Formatting Options
SHOW_FULL_PATH=false                      # Show full directory path vs. short name
# USE_ICONS=true                          # Use icons in display
# USE_COLORS=true                         # Use colored output
# SHOW_SEPARATORS=true                    # Show separators between sections

# Cost Display Options
SHOW_API_COSTS_WHEN_INCLUDED=false        # When logged in: hides "- Saved Today $X.XX This Session $X.XX", only shows "⚡API Costs Included"
SHOW_API_COSTS=true                       # When not logged in: shows actual API costs "$X.XX"

# Update Settings
# UPDATE_INTERVAL=30                      # Update interval in seconds
