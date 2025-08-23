# Claude Code Status Line Script

A professional status line script for Claude Code that displays comprehensive workspace information, git status, model details, session time, and context window monitoring with beautiful color-coded formatting.

## Features

- **Directory Information**: Shows full directory path with git status
- **● Git Integration**: Active git branch or ○ no git repository status  
- **● Login Status**: Dynamic connection status (● Logged-In / ○ Logged-Out)
- **☆/★ Model Information**: Model-specific icons and colors
  - ☆ Sonnet 4 in sandybrown
  - ★ Opus 4.1 in darkorange
- **✓/⚠ Context Window**: Real-time context window monitoring
  - ✓ Context window ok (green)
  - ⚠ Context window exceeded! Do /compress (red)
- **⏱ Session Time**: Remaining time in current session block
- **⚡ API Cost**: Real-time cost tracking with ccusage integration

## Installation

1. Clone or download this repository
2. Make the script executable:
   ```bash
   chmod +x claude-code-statusline.sh
   ```
3. Configure Claude Code to use this script by adding the following to your settings file

## Configuration

### Settings File Location

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

### Color Scheme

The script uses a simplified, clean color palette:

- **ForestGreen** (#228B22): All active status indicators
  - ● git branch (when in repository)
  - ● Logged-In
  - ✓ Context window ok
- **Firebrick** (#B22222): All inactive status indicators
  - ○ no git repository
  - ○ Logged-Out  
  - ⚠ Context window exceeded
- **SandyBrown** (#F4A460): ☆ Sonnet 4 model
- **DarkOrange** (#FF8C00): ★ Opus 4.1 model
- **Default terminal color**: Directory paths, session time, API cost text

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