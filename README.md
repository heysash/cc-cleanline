# Claude Code Status Line Script

A professional status line script for Claude Code that displays comprehensive workspace information, git status, model details, and real-time usage metrics with beautiful color-coded formatting.

## Features

- **📁 Workspace Information**: Shows full directory path
- **⎇ Git Integration**: Displays current git branch or "No git" status
- **✅/⛔️ Login Status**: Dynamic connection status to Claude services
- **＄ API Status**: Shows API availability (free/fee-based)
- **🤖/🧠 Model Information**: Model-specific icons (Robot for Sonnet, Brain for Opus)
- **🔋/🪫 Token Usage**: Real-time token tracking with ccusage integration
  - Battery icon changes to low battery when >80% usage
  - Thousands separator for better readability
- **⏱️ Session Time**: Actual remaining time in current 5-hour block

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

The script displays information in two lines:
1. **First line**: Full directory path
2. **Second line**: All status information separated by bullet points

Example output:
```
📁 /Users/john-doe/developer/project
⎇ git branch main • ✅ Logged-In • ＄ API free • 🧠 LLM Opus 4.1 • 🔋 Tokens 103,438/200,000 • ⏱️ Time left 2h 43m
```

### Color Scheme

- **SlateGray** (112,128,144): Directory path
- **CornflowerBlue** (100,149,237): Git branch
- **PaleGreen** (152,251,152): Logged-in status
- **Salmon** (250,128,114): Logged-out status  
- **DarkTurquoise** (0,206,209): API status
- **MediumOrchid** (186,85,211): Model name
- **Sienna** (160,82,45): Token usage
- **PaleTurquoise** (175,238,238): Remaining time

## Token and Time Tracking

The script integrates with [ccusage](https://github.com/ryoppippi/ccusage) to provide real-time token consumption and remaining time data:

- **Automatic detection**: Uses `bunx ccusage@latest` if available
- **5-hour block tracking**: Shows tokens used and remaining in current block
- **Smart fallbacks**: Displays default values if ccusage is unavailable
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