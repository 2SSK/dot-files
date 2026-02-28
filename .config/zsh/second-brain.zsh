# ==============================
# Second Brain - OpenCode Wrappers
# ==============================
# These functions integrate your Obsidian vault with OpenCode
# for the second brain workflow described in the podcast.

export VAULT_DIR="$HOME/SSK-Vault"

alias v="cd $VAULT_DIR"
alias vnow='ls "$VAULT_DIR/Daily Notes/" 2>/dev/null | tail -3'
alias vtodo="cat $VAULT_DIR/00-Inbox/00.01 TODO.md 2>/dev/null"
alias vmoc="ls $VAULT_DIR/MOCs/ 2>/dev/null"
alias vcapture="cat $VAULT_DIR/00-Inbox/capture.md 2>/dev/null"

ocode-morning() {
    opencode --prompt "Execute the /morning workflow from ~/.config/opencode/commands/obsidian/morning.md"
}

ocode-daily() {
    local DATE=${1:-$(date +%Y-%m-%d)}
    opencode --prompt "Execute the /daily workflow. Today's date is $DATE. Create or open the daily note at $VAULT_DIR/Daily Notes/${DATE}.md using the template at $VAULT_DIR/Templates/Daily Note.md"
}

ocode-project() {
    if [[ -z "$1" ]]; then
        echo "Usage: ocode-project <project-name>"
        echo
        echo "Available work projects:"
        ls "$VAULT_DIR/context/work/ 2>/dev/null"
        echo
        echo "Available personal projects:"
        ls "$VAULT_DIR/context/personal/ 2>/dev/null"
        echo
        echo "Examples:"
        echo "  ocode-project amoga-agent-orchestrator"
        echo "  ocode-project pg-replica-poc"
        echo "  ocode-project homelab"
        return 1
    fi
    if [[ -f "$VAULT_DIR/context/work/$1.md" ]]; then
        opencode --context-file "$VAULT_DIR/context/work/$1.md"
    elif [[ -f "$VAULT_DIR/context/personal/$1.md" ]]; then
        opencode --context-file "$VAULT_DIR/context/personal/$1.md"
    else
        echo "Project not found: $1"
        echo "Available projects:"
        ls "$VAULT_DIR/context/work/ 2>/dev/null"
        ls "$VAULT_DIR/context/personal/ 2>/dev/null"
    fi
}

ocode-capture() {
    if [[ -z "$1" ]]; then
        echo "Usage: ocode-capture <note>"
        echo "Example: ocode-capture 'Remember to check WAL settings'"
        return 1
    fi
    echo "- $(date +%Y-%m-%d\ %H:%M): $1" >> "$VAULT_DIR/00-Inbox/capture.md"
    echo "✓ Captured: $1"
}

ocode-search() {
    if [[ -z "$1" ]]; then
        echo "Usage: ocode-search <query>"
        echo "Example: ocode-search PostgreSQL"
        return 1
    fi
    opencode --prompt "Execute the /search workflow from ~/.config/opencode/commands/obsidian/search.md. Search for '$1' in the vault at $VAULT_DIR"
}

ocode-patterns() {
    opencode --prompt "Execute the /patterns workflow from ~/.config/opencode/commands/obsidian/patterns.md. Scan the vault at $VAULT_DIR"
}

ocode-weekly() {
    opencode --prompt "Execute the /weekly workflow from ~/.config/opencode/commands/obsidian/weekly.md. Review the vault at $VAULT_DIR"
}

ocode-link() {
    if [[ -z "$1" ]]; then
        echo "Usage: ocode-link <topic>"
        echo "Example: ocode-link Temporal"
        return 1
    fi
    opencode --prompt "Execute the /link workflow from ~/.config/opencode/commands/obsidian/link.md. Find connections for '$1' in the vault at $VAULT_DIR"
}

ocode-todo() {
    if [[ -f "$VAULT_DIR/00-Inbox/00.01 TODO.md" ]]; then
        cat "$VAULT_DIR/00-Inbox/00.01 TODO.md"
    else
        echo "No TODO file found"
    fi
}

ocode-vault() {
    echo "Vault: $VAULT_DIR"
    echo
    echo "Quick commands:"
    echo "  v           - Go to vault"
    echo "  vnow        - Show recent daily notes"
    echo "  vtodo       - Show TODO"
    echo "  vmoc        - List MOCs"
    echo "  vcapture    - Show captures"
    echo
    echo "OpenCode commands:"
    echo "  ocode-morning    - Morning briefing"
    echo "  ocode-daily      - Daily note"
    echo "  ocode-project    - Load project context"
    echo "  ocode-capture    - Quick capture"
    echo "  ocode-search     - Search vault"
    echo "  ocode-patterns   - Find patterns"
    echo "  ocode-weekly     - Weekly review"
    echo "  ocode-link       - Find connections"
    echo "  ocode-todo       - Show TODO"
}
