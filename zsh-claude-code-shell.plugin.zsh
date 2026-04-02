# zsh-claude-code-shell - Generate shell commands from natural language using Claude Code
# Usage: Type "# <description>" and press Enter to generate a command

# Configuration
: ${ZSH_CLAUDE_SHELL_DISABLED:=0}
: ${ZSH_CLAUDE_SHELL_MODEL:=}
: ${ZSH_CLAUDE_SHELL_DEBUG:=0}
: ${ZSH_CLAUDE_SHELL_FANCY_LOADING:=1}  # Set to 0 to use simple loading message

# Spinner character detection (platform/terminal-aware, matching Claude Code)
_zsh_claude_spinner_chars() {
    if [[ "$OSTYPE" == darwin* ]]; then
        if [[ -n "$GHOSTTY_RESOURCES_DIR" ]]; then
            echo '· ✢ ✳ ✶ ✻ *'
        else
            echo '· ✢ ✳ ✶ ✻ ✽'
        fi
    else
        echo '· ✢ * ✶ ✻ ✽'
    fi
}

# Thinking verbs (from Claude Code)
_ZSH_CLAUDE_THINKING_VERBS=(
    "Accomplishing" "Actioning" "Actualizing" "Architecting" "Baking"
    "Beaming" "Beboppin'" "Befuddling" "Billowing" "Blanching"
    "Bloviating" "Boogieing" "Boondoggling" "Booping" "Bootstrapping"
    "Brewing" "Bunning" "Burrowing" "Calculating" "Canoodling"
    "Caramelizing" "Cascading" "Catapulting" "Cerebrating" "Channeling"
    "Channelling" "Choreographing" "Churning" "Clauding" "Coalescing"
    "Cogitating" "Combobulating" "Composing" "Computing" "Concocting"
    "Considering" "Contemplating" "Cooking" "Crafting" "Creating"
    "Crunching" "Crystallizing" "Cultivating" "Deciphering" "Deliberating"
    "Determining" "Dilly-dallying" "Discombobulating" "Doing" "Doodling"
    "Drizzling" "Ebbing" "Effecting" "Elucidating" "Embellishing"
    "Enchanting" "Envisioning" "Evaporating" "Fermenting" "Fiddle-faddling"
    "Finagling" "Flambéing" "Flibbertigibbeting" "Flowing" "Flummoxing"
    "Fluttering" "Forging" "Forming" "Frolicking" "Frosting"
    "Gallivanting" "Galloping" "Garnishing" "Generating" "Gesticulating"
    "Germinating" "Gitifying" "Grooving" "Gusting" "Harmonizing"
    "Hashing" "Hatching" "Herding" "Honking" "Hullaballooing"
    "Hyperspacing" "Ideating" "Imagining" "Improvising" "Incubating"
    "Inferring" "Infusing" "Ionizing" "Jitterbugging" "Julienning"
    "Kneading" "Leavening" "Levitating" "Lollygagging" "Manifesting"
    "Marinating" "Meandering" "Metamorphosing" "Misting" "Moonwalking"
    "Moseying" "Mulling" "Mustering" "Musing" "Nebulizing"
    "Nesting" "Newspapering" "Noodling" "Nucleating" "Orbiting"
    "Orchestrating" "Osmosing" "Perambulating" "Percolating" "Perusing"
    "Philosophising" "Photosynthesizing" "Pollinating" "Pondering" "Pontificating"
    "Pouncing" "Precipitating" "Prestidigitating" "Processing" "Proofing"
    "Propagating" "Puttering" "Puzzling" "Quantumizing" "Razzle-dazzling"
    "Razzmatazzing" "Recombobulating" "Reticulating" "Roosting" "Ruminating"
    "Sautéing" "Scampering" "Schlepping" "Scurrying" "Seasoning"
    "Shenaniganing" "Shimmying" "Simmering" "Skedaddling" "Sketching"
    "Slithering" "Smooshing" "Sock-hopping" "Spelunking" "Spinning"
    "Sprouting" "Stewing" "Sublimating" "Swirling" "Swooping"
    "Symbioting" "Synthesizing" "Tempering" "Thinking" "Thundering"
    "Tinkering" "Tomfoolering" "Topsy-turvying" "Transfiguring" "Transmuting"
    "Twisting" "Undulating" "Unfurling" "Unravelling" "Vibing"
    "Waddling" "Wandering" "Warping" "Whatchamacalliting" "Whirlpooling"
    "Whirring" "Whisking" "Wibbling" "Working" "Wrangling"
    "Zesting" "Zigzagging"
)

# Spinner animation (runs in background, writes to /dev/tty)
_zsh_claude_spinner() {
    # Build ping-pong frame sequence from platform-appropriate characters
    local -a base_chars=(${(s: :)$(_zsh_claude_spinner_chars)})
    local -a frames=("${base_chars[@]}")
    local k
    for ((k=${#base_chars[@]}; k>=1; k--)); do
        frames+=("${base_chars[$k]}")
    done
    local frame_count=${#frames[@]}

    # Colors (Claude Code theme: salmon/orange)
    local base_color='\033[38;5;174m'
    local shimmer_color='\033[38;5;216m'
    local reset_color='\033[0m'

    # State
    local words_len=${#_ZSH_CLAUDE_THINKING_VERBS[@]}
    local frame_idx=1
    local w=$(( RANDOM % words_len + 1 ))
    local tick=0
    local word="${_ZSH_CLAUDE_THINKING_VERBS[$w]}"
    local full_text="${word}…"
    local text_len=${#full_text}
    local shimmer_pos=$text_len

    # Hide cursor
    printf '\033[?25l' > /dev/tty

    while true; do
        local spinner_char="${frames[$frame_idx]}"

        # Build output with per-character shimmer sweep
        local output="${base_color}${spinner_char} "
        local j
        for ((j=1; j<=text_len; j++)); do
            if (( j >= shimmer_pos - 1 && j <= shimmer_pos + 1 )); then
                output+="${shimmer_color}${full_text[$j]}"
            else
                output+="${base_color}${full_text[$j]}"
            fi
        done
        output+="${reset_color}"

        printf '\r\033[K%b' "$output" > /dev/tty

        # Advance frame (ping-pong)
        frame_idx=$(( frame_idx % frame_count + 1 ))
        tick=$(( tick + 1 ))

        # Advance shimmer every 2 ticks (~240ms, approximating 200ms)
        if (( tick % 2 == 0 )); then
            shimmer_pos=$(( shimmer_pos - 1 ))
            if (( shimmer_pos < 0 )); then
                shimmer_pos=$text_len
            fi
        fi

        # Change verb every 20 ticks (~2.4 seconds)
        if (( tick % 20 == 0 )); then
            w=$(( RANDOM % words_len + 1 ))
            word="${_ZSH_CLAUDE_THINKING_VERBS[$w]}"
            full_text="${word}…"
            text_len=${#full_text}
            shimmer_pos=$text_len
        fi

        sleep 0.12
    done
}

# Stop spinner and cleanup
_zsh_claude_stop_spinner() {
    local pid=$1
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null
        # Small delay to let the process terminate
        sleep 0.05
    fi
    # Show cursor, clear spinner line, move up one line, clear that line too
    # This returns cursor to the original query line position
    printf '\033[?25h\r\033[K\033[A\r\033[K' > /dev/tty
}

# Check if claude CLI is available (lazy check - deferred until first use)
_zsh_claude_check_cli() {
    if ! command -v claude &> /dev/null; then
        echo "zsh-claude-code-shell: 'claude' command not found. Please install Claude Code CLI."
        return 1
    fi
    return 0
}

# Sanitize output - remove markdown code blocks and trim whitespace
_zsh_claude_sanitize() {
    local input="$1"

    # Remove markdown code block markers (```bash, ```, etc.)
    input="${input#\`\`\`*$'\n'}"  # Remove opening ```lang\n
    input="${input%\`\`\`}"         # Remove closing ```
    input="${input#\`\`\`}"         # Remove opening ``` without newline

    # Remove single backticks wrapping the whole command
    if [[ "$input" == \`*\` ]]; then
        input="${input#\`}"
        input="${input%\`}"
    fi

    # Trim leading/trailing whitespace
    input="${input#"${input%%[![:space:]]*}"}"
    input="${input%"${input##*[![:space:]]}"}"

    echo "$input"
}

# Main widget that intercepts Enter key
_zsh_claude_accept_line() {
    # Pass through if disabled
    if [[ "$ZSH_CLAUDE_SHELL_DISABLED" == "1" ]]; then
        zle .accept-line
        return
    fi

    # Pass through if buffer doesn't start with "# "
    if [[ ! "$BUFFER" =~ ^'# ' ]]; then
        zle .accept-line
        return
    fi

    # Pass through multi-line buffers
    if [[ "$BUFFER" == *$'\n'* ]]; then
        zle .accept-line
        return
    fi

    # Extract query (remove "# " prefix)
    local query="${BUFFER:2}"

    # Skip empty queries
    if [[ -z "${query// }" ]]; then
        zle .accept-line
        return
    fi

    # Check if claude CLI is available
    if ! _zsh_claude_check_cli; then
        zle reset-prompt
        return 1
    fi

    # Disable job notifications for all background processes in this function.
    # Using local_options so settings are restored on function exit, but by then
    # all jobs are already waited-on or disowned — nothing left to notify about.
    setopt local_options no_notify no_monitor

    # Start spinner or show simple message
    local spinner_pid=""
    if [[ "$ZSH_CLAUDE_SHELL_FANCY_LOADING" == "1" ]]; then
        # Print newline so spinner appears below the query line
        print > /dev/tty
        _zsh_claude_spinner &!  # &! = background + auto-disown (zsh built-in)
        spinner_pid=$!
    else
        zle -R "Generating command with Claude..."
    fi

    # Build claude command - restrict tools and use focused system prompt
    local claude_args=("-p" "--output-format" "text")
    claude_args+=("--tools" "WebSearch,WebFetch")
    claude_args+=("--system-prompt" "You are a shell command generator running on ${OSTYPE} ($(uname -s) $(uname -m)). Shell: zsh. Your ONLY job is to output a single shell command that accomplishes the user's request. Use commands and flags compatible with this operating system. Output ONLY the raw shell command - no markdown, no code blocks, no explanations, no comments, no backticks. Just the executable command itself on a single line. If you need to look up command syntax, you may use web search.")

    if [[ -n "$ZSH_CLAUDE_SHELL_MODEL" ]]; then
        claude_args+=("--model" "$ZSH_CLAUDE_SHELL_MODEL")
    fi

    # Call Claude Code CLI with output to temp file so we can use wait
    local tmpfile="${TMPDIR:-/tmp}/zsh-claude-$$"
    local claude_pid
    local exit_code
    local cmd

    if [[ "$ZSH_CLAUDE_SHELL_DEBUG" == "1" ]]; then
        claude "${claude_args[@]}" "$query" > "$tmpfile" 2>&1 &
    else
        claude "${claude_args[@]}" "$query" > "$tmpfile" 2>/dev/null &
    fi
    claude_pid=$!

    # Set up trap to clean up on interrupt (Ctrl+C)
    trap '
        kill $claude_pid 2>/dev/null
        [[ -n "$spinner_pid" ]] && _zsh_claude_stop_spinner "$spinner_pid"
        rm -f "$tmpfile"
        trap - INT
        zle reset-prompt
        return 130
    ' INT

    # Wait for claude to finish, then disown to remove from job table
    wait $claude_pid
    exit_code=$?
    disown $claude_pid 2>/dev/null

    # Reset trap and stop spinner
    trap - INT
    [[ -n "$spinner_pid" ]] && _zsh_claude_stop_spinner "$spinner_pid"

    # Read output from temp file
    cmd=$(<"$tmpfile")
    rm -f "$tmpfile"

    # Handle interrupt (Ctrl+C) - exit code 130 = 128 + SIGINT(2)
    if [[ $exit_code -eq 130 ]] || [[ $exit_code -eq 143 ]]; then
        zle reset-prompt
        return 130
    fi

    # Handle errors
    if [[ $exit_code -ne 0 ]] || [[ -z "$cmd" ]]; then
        zle -M "Error: Failed to generate command (exit code: $exit_code)"
        zle reset-prompt
        return 1
    fi

    # Sanitize the output
    cmd=$(_zsh_claude_sanitize "$cmd")

    # Replace buffer with generated command
    BUFFER="$cmd"
    CURSOR=${#BUFFER}

    zle reset-prompt
}

# Initialize the plugin
_zsh_claude_init() {
    zle -N accept-line _zsh_claude_accept_line
}

_zsh_claude_init
