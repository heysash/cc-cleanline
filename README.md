# Claude Code Status Line Script

A professional status line script for Claude Code that displays comprehensive workspace information, git status, model details, session time, and context window monitoring with beautiful color-coded formatting.

## Features

- **Directory Information**: Shows full directory path with git status
- **● Git Integration**: Active git branch or ○ no git repository status  
- **● Login Status**: Dynamic connection status (● Logged-In / ○ Logged-Out)
- **☆/★ Model Information**: Model-specific icons and colors
  - ☆ Sonnet 4 in saddlebrown
  - ★ Opus 4.1 in sandybrown
- **✓/⚠ Context Window**: Real-time context window monitoring
  - ✓ Context window ok (green)
  - ⚠ Context window exceeded! Do /compress (red)
- **⏱ Session Time**: Remaining time in current session block
- **⚡ API Cost**: Real-time cost tracking with ccusage integration
- **🎨 Customizable Configuration**: Full customization via configuration file

## Installation

1. Clone or download this repository
2. Make the script executable:
   ```bash
   chmod +x claude-code-statusline.sh
   ```
3. The script will automatically use the default configuration. For custom settings, see the **Configuration** section below.
4. Configure Claude Code to use this script by adding the following to your settings file

## Configuration

### Claude Code Settings

Add the following configuration to your Claude Code settings file:

**macOS**: `~/.claude/settings.json`

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash /[PATH-TO-SCRIPT]/claude-code-statusline.sh"
  }
}
```

Replace `[PATH-TO-SCRIPT]` with the actual path to where you saved the script.

### Customization via Configuration File

The script includes a comprehensive configuration system via `statusline.config.sh`. This file allows you to customize:

#### Colors
- **Status Colors**: Active/inactive/critical states
- **Model Colors**: Different colors for Opus and Sonnet models  
- **UI Colors**: Text colors and theme elements

#### Icons
- Status indicators (●, ○, ⚠, ✓)
- Custom icons for different states

#### Labels
- Text labels for login status
- Context window messages
- Model display names

#### Example Configuration
```bash
# Custom colors (using 256-color codes)
COLOR_ACTIVE_STATUS='\033[38;5;34m'     # Green
COLOR_OPUS='\033[38;5;215m'             # Sandybrown
COLOR_SONNET='\033[38;5;130m'           # Saddlebrown

# Custom labels  
LABEL_LOGGED_IN="Connected"
LABEL_MODEL="Model"
```

The configuration file (`statusline.config.sh`) must be in the same directory as the main script. The script will automatically detect and load it.

### Auto-Detection Features

The script automatically detects:
- Current working directory
- Git repository status and branch
- Model information from Claude Code

## Output Format

The script displays information in three lines:
1. **First line**: Git status and full directory path
2. **Second line**: Login status, model information, and session time
3. **Third line**: Context window status and API cost information

Example output:
```
● git branch main ▶ /Users/john-doe/developer/project
● Logged-In ☆ LLM Sonnet 4 ⏱ Session time left 2h 43m
✓ Context window ok ⚡ API $0 (normally $2.50)
```

**Alternative states:**
```
○ no git repository ▶ /tmp/test-folder
○ Logged-Out ★ LLM Opus 4.1 ⏱ Session time left 1h 15m
⚠ Context window exceeded! Do /compress ⚡ API $0 (normally $3.80)
```

### Default Color Scheme

The script uses a clean, modern color palette:

- **Green** (256-color 34): All active status indicators
  - ● git branch (when in repository)
  - ● Logged-In
  - ✓ Context window ok
- **Red** (256-color 196): All inactive/critical status indicators
  - ○ no git repository
  - ○ Not logged in  
  - ⚠ Context window exceeded
- **Sandybrown** (256-color 215): ★ Opus 4.1 model
- **Saddlebrown** (256-color 130): ☆ Sonnet 4 model
- **DarkSlateGray** (#2F4F4F): Directory paths, session time, API cost text

All colors can be customized via the `statusline.config.sh` configuration file.

## Context Window & Session Tracking

The script provides real-time monitoring of your Claude Code session:

### Context Window Monitoring
- **Built-in detection**: Uses Claude Code's `exceeds_200k_tokens` flag
- **Visual indicators**: ✓ for OK, ⚠ for exceeded with compress recommendation
- **Color coding**: Green for safe, red for exceeded

### Session Time & Cost Tracking
- **ccusage integration**: Uses [ccusage](https://github.com/ryoppippi/ccusage) for real-time data
- **Automatic detection**: Uses `bunx ccusage@latest` if available
- **Session time**: Shows remaining time in current session block
- **Cost tracking**: Displays current session cost vs. normal pricing
- **Smart fallbacks**: Shows default values if ccusage is unavailable
- **No installation required**: Runs ccusage on-demand via bunx

## Requirements

### Required
- Bash shell
- `jq` for JSON parsing
- Claude Code CLI

### Optional
- `git` for branch detection
- `bunx` (or `npx`) for real-time token/time tracking via ccusage

## Author

Created by [Sascha Rahn](https://github.com/heysash)

## License

MIT License - feel free to modify and distribute as needed.