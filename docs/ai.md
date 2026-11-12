# Claude Code and opencode

Both are installed by the `cli` layer (Arch: AUR `claude-code`, `opencode-bin`; elsewhere the
pinned npm releases in `~/.local`), with `uv` for the Grafana MCP server. They share skills,
MCP servers and secrets.

| Path | Purpose |
| --- | --- |
| `~/.claude/CLAUDE.md` | Global instructions for Claude Code |
| `~/.claude/skills/` | Skills, read by Claude Code **and** opencode |
| `~/.claude/agents/`, `~/.claude/commands/` | Claude Code subagents and slash commands |
| `~/.config/mcp/claude.json` | Claude Code's MCP servers: the list to register (`claude mcp add-json`) |
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
| temporal (Temporal workflows, task queues, history) | ✓ | ✓ | `temporal-mcp` (`dev` layer), `~/.config/temporal-mcp/config.yaml` (see below) |
| adb (Android devices, emulators, Waydroid) | ✓ | ✓ | `adb` (android-tools), `adb-mcp` (both in the `dev` layer) |
| postgres, docker | | off | `POSTGRES_DATABASE_URI` |

Claude Code keeps its servers in `~/.claude.json`, which isn't in the repo; `claude.json` is the
list of them. Register a new one in user scope with its entry, placeholders and all (so
`~/.claude.json` never holds a key): `claude mcp add-json --scope user <name> '<its JSON>'`
(`claude mcp remove --scope user <name>` first to change one). `claude mcp list` checks them and
names any variable missing from `secrets.env`. opencode reads `opencode.json` directly (stowed).

### Temporal

`temporal-mcp` (Temporal's own, pre-release) reads `~/.config/temporal-mcp/config.yaml`, which stays on
this machine: it names the servers. Start from the example beside it:
`cp ~/.config/temporal-mcp/config.yaml.example ~/.config/temporal-mcp/config.yaml`, fill in the
staging address, restart the agent and ask it to check its connection to `staging`.

Each target is one namespace on one server; agents name the target in every call, so several
namespaces and servers (staging, production) sit in one file. It's for reading and investigating
only. Every tool reads except `start_workflow`, and the servers take no credentials, so temporal-mcp
can't refuse it itself: both clients block it instead. opencode turns it off in `opencode.json`
(`tools.temporal_start_workflow: false`), and Claude Code denies it in `~/.claude/settings.json`
(`permissions.deny: ["mcp__temporal__start_workflow"]`; that file isn't in the repo, so add the rule
on a new machine).

## Mentors

`mentor` (recreational programming) and `devops-sre-mentor` teach through hints instead of writing
the code. Both need a live conversation, so they run as the main session rather than as subagents:
`claude --agent mentor`, or Tab to it in opencode.

Each has the same prompt in both tools (`tests/ai.bats` checks this). They can't edit files with
the normal tools. For a repair, say "rescue" or "fix it": the mentor uses `sed` and asks for
approval first. opencode enforces this per command. Claude Code can't limit Bash to `sed` here, so
there it rests on the prompt and on approving each command, which also means Bash isn't confined
in a mode that skips approvals. Project notes go in a `LEARNING.md` that the learner writes and the
mentor only reads.

`.config/opencode` is stowed like the rest (its own `node_modules`, lock files and `.env` of keys
aren't linked), so opencode sees changes at once. `.claude` isn't stowed yet: copy changed agents
to `~/.claude/agents/` by hand.

## New machine

1. `setup.sh` (the `cli` layer) installs both tools, `uv` and node.
2. `cp ~/.config/secrets.env.example ~/.config/secrets.env && chmod 600 ~/.config/secrets.env`,
   then fill it in.
3. Register Claude's servers: for each entry of `~/.config/mcp/claude.json`,
   `claude mcp add-json --scope user <name> '<its JSON>'`. Then log in: `claude` (`/login`) and
   `opencode auth login`.

The repo's tests fail if a token-shaped string or a literal credential ever lands in a tracked
file (`tests/ai.bats`).
