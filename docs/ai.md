# Claude Code and opencode

Both are installed by the `cli` layer (Arch: AUR `claude-code`, `opencode-bin`; elsewhere the
pinned npm releases in `~/.local`), with `uv` for the Grafana MCP server. They share skills,
MCP servers and secrets.

| Path | Purpose |
| --- | --- |
| `~/.claude/CLAUDE.md` | Global instructions for Claude Code |
| `~/.claude/skills/` | Skills, read by Claude Code **and** opencode |
| `~/.claude/agents/`, `~/.claude/commands/` | Claude Code subagents and slash commands |
| `~/.config/mcp/claude.json` | Claude Code's MCP servers, registered by `mcp-sync` |
| `~/.config/opencode/opencode.json` | opencode: MCP servers and the `git` command |
| `~/.config/opencode/AGENTS.md`, `agent/`, `commands/`, `context/`, `plugins/` | opencode instructions, agents, commands, workmux status plugin |
| `~/.config/opencode/tui.json` | opencode TUI: the `desktop` theme, `Ctrl+d`/`Ctrl+u` paging |
| `~/.local/state/desktop/theme/opencode/` | opencode's `desktop` theme, rendered by `theme` (`OPENCODE_CONFIG_DIR`) |
| `~/.config/secrets.env` | API keys and internal URLs (untracked, `chmod 600`) |

Not tracked, per machine: `~/.claude/settings.json` (model, permissions, auto-mode environment),
`~/.claude.json` (Claude's state, logins, registered MCP servers), `~/.config/github-copilot/`.

## Secrets

`~/.config/secrets.env` holds every key and internal host the MCP servers need; the variables
are listed in `~/.config/secrets.env.example`. The configs only contain placeholders: `${VAR}`
for Claude Code, `{env:VAR}` for opencode.

The `claude` and `opencode` shell functions load the file just for that command, so the MCP
servers they start get the values and nothing else run from the shell does. Anything that
starts the binary directly (`timeout claude`, a script) bypasses the function: wrap it as
`with_secrets timeout 60 claude …`.

## MCP servers

| Server | Claude Code | opencode | Needs |
| --- | --- | --- | --- |
| filesystem (`$HOME`) | ✓ | ✓ | |
| context7 (library docs) | ✓ | ✓ | `CONTEXT7_API_KEY` |
| playwright (browser) | ✓ | ✓ | |
| prometheus | ✓ | ✓ | `PROMETHEUS_URL` |
| grafana | ✓ | ✓ | `GRAFANA_URL`, `GRAFANA_SERVICE_ACCOUNT_TOKEN`, `uvx` |
| superset | ✓ | ✓ | `SUPERSET_MCP_URL`, `SUPERSET_API_KEY` |
| supabase | | ✓ | `SUPABASE_MCP_URL` |
| postgres, docker | | off | `POSTGRES_DATABASE_URI` |

After editing `~/.config/mcp/claude.json`, run `mcp-sync`: it re-registers those servers in
user scope (placeholders only, so `~/.claude.json` never holds a key). `claude mcp list` checks
them and names any variable missing from `secrets.env`. opencode reads `opencode.json` directly.

## New machine

1. `setup.sh` (the `cli` layer) installs both tools, `uv` and node.
2. `cp ~/.config/secrets.env.example ~/.config/secrets.env && chmod 600 ~/.config/secrets.env`,
   then fill it in.
3. `mcp-sync`, then log in: `claude` (`/login`) and `opencode auth login`.

The repo's tests fail if a token-shaped string or a literal credential ever lands in a tracked
file (`tests/ai.bats`).
