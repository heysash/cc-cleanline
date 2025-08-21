# Claude Code Status Line Script

A customizable status line script for Claude Code that displays workspace information, git status, model information, and session metrics in a clean, colored format.

## Features

- **Workspace Information**: Shows current directory name
- **Git Integration**: Displays current git branch (if in a git repository)
- **Login Status**: Shows connection status to Claude services
- **Model Information**: Displays the currently active model
- **Token Usage**: Tracks token consumption and limits *(currently placeholder)*
- **Session Time**: Shows remaining session time *(currently placeholder)*

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

## Usage

The script reads JSON input from stdin containing workspace and session information from Claude Code. It outputs a formatted status line with color-coded information:

```
project-name git:main logged-in Model-Name 103,438/200,000 2h 43m left
```

### Color Scheme

- **Cyan (dim)**: Directory name
- **Green**: Git branch, login status
- **Blue (dim)**: Model name
- **Yellow**: Token usage
- **Magenta**: Remaining time

## Limitations

- Token usage counter is currently a placeholder value
- Remaining session time is currently a placeholder value
- These metrics will be implemented when Claude Code provides the necessary API endpoints

## Requirements

- Bash shell
- `jq` for JSON parsing
- `git` (optional, for git branch detection)
- Claude Code CLI

## Author

Created by [Sascha Rahn](https://github.com/heysash)

## License

MIT License - feel free to modify and distribute as needed.