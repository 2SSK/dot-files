# Project Context Loader

## Trigger
`/project <project-name>` or `ocode-project <name>`

## Description
Loads project context from the vault, giving OpenCode instant understanding of the project without re-explaining.

## Vault Location
Project contexts: `/home/ssk/SSK-Vault/context/work/`

## Available Projects
- `amoga-agent-orchestrator` - WebSocket server project
- `pg-replica-poc` - PostgreSQL replication POC
- `pg-replica-2` - PostgreSQL replication v2
- `mcp-on-server` - MCP server project
- `observability-2` - Observability infrastructure

## Workflow
1. Look for context file at `/home/ssk/SSK-Vault/context/work/<project-name>.md`
2. Read the context file and summarize:
   - Quick summary
   - Tech stack
   - Current work
   - Vault knowledge (linked notes)
   - Key files
   - Recommended OpenCode agents
3. Show recent decisions and open questions
4. Optionally search vault for additional relevant notes

## Example Usage
```
/project amoga-agent-orchestrator
/project pg-replica-poc
ocode-project amoga
ocode-project mcp-on-server
```

## Output Format
```
# Project: <project-name>

## Quick Summary
<1-2 sentence description>

## Tech Stack
- Primary: ...
- Secondary: ...

## Current Work
- Active focus areas

## Vault Knowledge
- [[MOC - ...]]
- [[40.xx Topic]]

## Key Files
- Code: `/home/ssk/Work/<project>/`
- Config: ...

## Recommended Agents
- backend-developer
- postgres-pro
```

## Notes
- Always use this before working on a project with OpenCode
- Keeps context in one place, no need to re-explain
- Context files are markdown - easy to update
