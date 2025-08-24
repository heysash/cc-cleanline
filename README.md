```
   ____ ____    ____ _                 _     _            
  / ___/ ___|  / ___| | ___  __ _ _ __ | |   (_)_ __   ___ 
 | |  | |     | |   | |/ _ \/ _` | '_ \| |   | | '_ \ / _ \
 | |__| |___  | |___| |  __/ (_| | | | | |___| | | | |  __/
  \____\____|  \____|_|\___|\__,_|_| |_|_____|_|_| |_|\___|
```

# CC CleanLine - Clean Claude Code Status Line

A clean, minimalist status line script for Claude Code that embodies the clean code philosophy - clear, readable, purposeful. Designed for developers who value distraction-free, professional status information.

## Philosophy

CC CleanLine follows the clean code philosophy: **every element serves a purpose, nothing is superfluous**. No decorative clutter, no visual noise - just the essential information you need, presented clearly and professionally.

This isn't just about looking good (though it does) - it's about cognitive clarity. When your status line is clean and purposeful, your mind stays focused on what matters: your code.

## Screenshot

![Project Preview](assets/img/preview.png "Claude Code Status Line - CC CleanLine")

## Features

🧹 **Clean & Minimalist** - Zero visual clutter, maximum information clarity  
⚙️ **Configurable** - Fully customizable via `cc-cleanline.config.sh`  
🔮 **Future-Proof** - Designed for extensibility and layout variations  
🧠 **Intelligent** - Smart session token monitoring and real-time cost tracking  
🎯 **Focused** - 3-line output: Git + Directory / Login + Model + Time / Session Tokens + Cost  
🌈 **Color-Coded** - Model-specific colors (Sonnet=saddlebrown, Opus=sandybrown)  
📊 **Cost Tracking** - Accurate daily totals and session costs via ccusage integration  
🔄 **Git Integration** - Branch detection with code change indicators (+lines/-lines)  
⚡ **Session Tokens** - 5h Max Tokens tracking for session management  

## Installation

1. Clone this repository:

   ```bash
   git clone https://github.com/heysash/cc-cleanline.git
   cd cc-cleanline
   ```

2. Make executable:

   ```bash
   chmod +x cc-cleanline.sh
   ```

3. Configure Claude Code (see Configuration section)

## Configuration

### Claude Code Settings

**macOS**: `~/.claude/settings.json`

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash /path/to/cc-cleanline/cc-cleanline.sh"
  }
}
```

### Customization

CC CleanLine uses `cc-cleanline.config.sh` for complete customization:

- **Colors**: Status states, model colors, UI elements
- **Icons**: Status indicators (●, ○, ⚠, ✓)  
- **Labels**: Login status, context messages, model names

**Example customization:**

```bash
# Clean, professional colors
COLOR_ACTIVE_STATUS='\033[38;5;34m'     # Green
COLOR_OPUS='\033[38;5;215m'             # Sandybrown  
COLOR_SONNET='\033[38;5;130m'           # Saddlebrown

# Custom labels
LABEL_LOGGED_IN="Connected"
LABEL_MODEL="Model"
```

## Output Examples

**Active development session:**

```text
● git branch main (+15/-3) ▶ ./project
● Logged-In ★ LLM Opus 4.1 ⏱ Next Session in 2h 43m  
  ⚡API Included - Saved Today $25.47 This Session $18.20
  ● 5h Max Tokens
```

**Outside git repo:**

```text
○ no git repository ▶ ./scratch
○ Not logged in ☆ LLM Sonnet 4 ⏱ Next Session in 1h 15m
  ⚡API $3.80 (current session)
```

### Clean Color Scheme

- **Green** (active states): git branch, logged in, session tokens
- **Red** (attention states): no git, logged out  
- **Sandybrown**: ★ Opus 4.1 model
- **Saddlebrown**: ☆ Sonnet 4 model
- **DarkSlateGray**: Directory paths, times, costs, session tokens

## Requirements

### Required

- Bash shell
- `jq` for JSON parsing  
- Claude Code CLI

### Optional

- `git` for branch detection
- `bunx`/`npx` for ccusage cost tracking

## Technical Details

- **Session Token Tracking**: Monitors 5h session token usage with smart threshold display
- **Cost Tracking**: Integrates with [ccusage](https://github.com/ryoppippi/ccusage) for accurate daily totals and current session costs
- **Time Display**: Shows remaining session time from ccusage active block or fallback calculation
- **Git Integration**: Automatic branch detection with code change indicators (+lines/-lines)
- **Configuration**: Hot-reloadable via `cc-cleanline.config.sh`
- **Output Format**: Consistent multi-line layout for reliable parsing

## Author

Created by [Sascha Rahn](https://github.com/heysash) • [heysash.com](https://heysash.com)

## License

MIT License