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
🎯 **Focused** - 3-line output: Git + Directory / Login + Model + Time / Tokens + API Costs  
🌈 **Color-Coded** - Model-specific colors (Sonnet=saddlebrown, Opus=sandybrown)  
📊 **Cost Tracking** - Accurate daily totals and session costs via ccusage integration  
🔄 **Git Integration** - Branch detection with real uncommitted changes (+lines/-lines)  
⚡ **Session Tokens** - 5h Max Tokens tracking with Low/Medium/High thresholds  
📈 **Context Metrics** - Real-time token usage with flexible display options calculated from JSONL transcript  

## Architecture

CC CleanLine follows a **modular architecture** designed for maintainability and LLM compatibility. The main script (`cc-cleanline.sh`) acts as an orchestrator that loads and coordinates specialized modules:

### Core Modules

- **`lib/git-status.sh`** (61 lines) - Git repository detection and branch analysis
- **`lib/cost-tracking.sh`** (179 lines) - Token usage and API cost calculation via ccusage integration  
- **`lib/model-detection.sh`** (52 lines) - Claude model identification and color mapping
- **`lib/context-metrics.sh`** (308 lines) - Real-time token metrics calculated from JSONL transcript with flexible display
- **`lib/display-formatter.sh`** (119 lines) - Status line output formatting and color application
- **`lib/happy-mode-integration.sh`** (44 lines) - Easter egg system integration

### Design Philosophy

Each module has a **single responsibility** and is designed for optimal LLM processing. Most modules stay under 180 lines, with larger modules like context-metrics justified by their comprehensive token calculation functionality. The modular design enables:

- **Isolated testing** of individual components
- **Easier maintenance** with clear boundaries
- **Flexible customization** without affecting core functionality
- **Hot-swappable modules** for future extensions

The main script loads all modules at startup and coordinates their execution based on the JSON input from Claude Code.

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

3. **Important**: Ensure the `lib/` directory stays intact with all module files - the script requires all modules for proper functionality.

4. Configure Claude Code (see Configuration section)

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

CC CleanLine uses a two-tier configuration system for flexible customization:

#### Default Configuration
The base configuration is in `cc-cleanline.config.sh` which contains all default settings and gets updated when you pull new versions.

#### Personal Overrides  
Create `cc-cleanline.config.local` to override specific settings without affecting the base configuration. This file:
- Is automatically ignored by git (stays local)
- Only needs the variables you want to change
- Takes precedence over default values

**Setup your personal config:**

1. Copy the example file:
   ```bash
   cp cc-cleanline.config.example cc-cleanline.config.local
   ```

2. Edit `cc-cleanline.config.local` and uncomment/modify any values:
   ```bash
   # Example personal overrides
   COLOR_ACTIVE_STATUS='\033[94m'        # Blue instead of green
   SHOW_FULL_PATH=true                   # Show full directory paths
   ICON_ACTIVE="►"                       # Different active icon
   LABEL_MODEL="Model"                   # Custom model label
   ```

#### Available Settings

- **Colors**: Status states, model colors, UI elements
- **Icons**: Status indicators (●, ○, ⚠, ✓)  
- **Labels**: Login status, context messages, model names
- **Display**: Path format, cost visibility, feature toggles
- **Context Metrics**: Flexible display system with configurable token and percentage display
- **Performance**: Cache settings and update intervals

The local config only needs variables you want to change - all others use the defaults.

#### Context Metrics System
CC CleanLine features a sophisticated context metrics system that calculates token usage directly from Claude Code's JSONL transcript file. This provides accurate, real-time token tracking with intelligent caching and comprehensive display options.

**Key Features:**

- **Real-time JSONL Parsing**: Extracts token counts directly from Claude Code's transcript data
- **Intelligent Caching**: 5-second cache with file modification time detection for performance
- **Token Aggregation**: Sums input, output, and cached tokens across the entire conversation
- **Context Window Tracking**: Monitors the current context length from the most recent main chain entry
- **Flexible Display Options**: Two display modes with extensive configuration

**Display Systems:**

*Primary: Flexible Model + Token Display*

The default system combines model information with token metrics in a clean, configurable format:

- `SHOW_MODEL_NAME=true` → Display model name ("Sonnet 4", "Opus 4.1")
- `SHOW_TOKEN_ABSOLUTE=true` → Show current context tokens ("59.0k" or "59.0k/200k")
- `SHOW_TOKEN_PERCENT_TOTAL=true` → Show percentage of 200k limit ("29.5% 200k")
- `SHOW_TOKEN_PERCENT_USABLE=true` → Show percentage of 160k compression trigger ("36.9% 160k")


**Understanding the 160k Compression Trigger:**
This represents Claude Code's automatic context compression point. When the context window reaches approximately 160k tokens, Claude Code compresses the chat history to create space for continued conversation within the 200k total limit.

**Display Format Examples:**

```bash
# Full flexible display (all components):
"Sonnet 4 | 59.0k | 29.5% 200k | 36.9% 160k"

# Extended format (no percentages enabled):
"Sonnet 4 | 59.0k/200k"

# Percentage-only display:
"Sonnet 4 | 29.5% 200k | 36.9% 160k"

```

**Performance & Caching:**

- 5-second intelligent cache with file modification detection
- Efficient jq-based JSONL parsing with token aggregation
- Automatic fallback when transcript data is unavailable

## Output Examples

**Active development session (flexible display system):**

```text
● git branch main (+15/-3) ▶ ./project
● Logged-In ★ Opus 4.1 | 59.0k | 29.5% 200k | 36.9% 160k ⏱ Next Session 2h 43m  
  ● 5h Max Tokens Low ⚡API Costs Included
```

**Active development session (extended token format):**

```text
● git branch main (+15/-3) ▶ ./project
● Logged-In ★ Opus 4.1 | 59.0k/200k ⏱ Next Session 2h 43m  
  ● 5h Max Tokens Low ⚡API Costs Included
```

**Active development session (without context data):**

```text
● git branch main (+15/-3) ▶ ./project
● Logged-In ★ Opus 4.1 ⏱ Next Session 2h 43m  
  ● 5h Max Tokens Low ⚡API Costs Included
```

**Outside git repo:**

```text
○ no git repository ▶ ./scratch
○ Not logged in ☆ Sonnet 4 ⏱ Next Session 1h 15m
  ⚡API $3.80 (current session)
```

### Clean Color Scheme

- **Bright Green** (active states): git branch, logged in, Low token usage
- **Orange** (Medium token usage): matches current model color for consistency
- **Red** (attention states): no git, logged out, High token usage  
- **Sandybrown**: ★ Opus 4.1 model
- **Saddlebrown**: ☆ Sonnet 4 model
- **Standard Gray**: Directory paths, times, costs, neutral text

## Requirements

### Required

- Bash shell
- `jq` for JSON parsing  
- Claude Code CLI

### Optional

- `git` for branch detection
- `bunx`/`npx` for ccusage cost tracking

## Technical Details

### Modular Architecture
- **Main Script**: `cc-cleanline.sh` (128 lines) orchestrates module loading and execution
- **Module Loading**: Automatic discovery and sourcing of all `lib/*.sh` files at startup
- **Configuration**: Two-tier system with base config and local overrides, loaded before modules
- **Error Handling**: Graceful fallbacks when optional modules or dependencies are missing

### Core Functionality

- **Context Metrics**: `lib/context-metrics.sh` calculates real-time token usage from JSONL transcript with intelligent caching, file modification tracking, and flexible display system
- **Session Token Tracking**: `lib/cost-tracking.sh` monitors 5h session usage with model-matched color thresholds  
- **Cost Integration**: Seamless [ccusage](https://github.com/ryoppippi/ccusage) integration with precision jq calculations
- **Git Analysis**: `lib/git-status.sh` provides intelligent branch detection with real change tracking (+/-lines)
- **Model Detection**: `lib/model-detection.sh` identifies Claude models with automatic color mapping
- **Display Coordination**: `lib/display-formatter.sh` ensures consistent 3-line output format

### Happy Mode System

- **Modular Integration**: `lib/happy-mode-integration.sh` cleanly separates easter egg functionality
- **Standalone Tools**: `happy-mode.sh` and `happy-mode-tools.sh` provide complete easter egg experience
- **Configuration Hooks**: Seamlessly activated via configuration without main script modification

## Experimental Features 🐰

*"Curiouser and curiouser..." - Alice*

Some say there are hidden pathways in the configuration files, waiting for the truly curious developer to discover them. What secrets lie behind innocent-looking settings? What happens when boredom meets code?

> *Follow the white rabbit...*  
> *The rabbit hole goes deeper than you think.*

For those who dare to explore beyond the clean facade, remember: not all features are documented, and not all documentation tells the whole truth. Sometimes the most delightful discoveries come from reading between the lines... or perhaps from a simple boolean that asks "What's this?"

*The Matrix has CC CleanLine, and CC CleanLine has you.*

---

**Hint for the sleepless coders:** The configuration holds more than colors and labels. Those who work past midnight might find unexpected companions in their status line. Easter eggs are not just for Sunday.

## License

MIT License
