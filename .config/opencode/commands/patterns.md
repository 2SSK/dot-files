# Pattern Discovery Command

## Trigger
`/patterns` or `ocode-patterns`

## Description
Scans recent daily notes to find recurring themes, connections between topics, and ideas you may have forgotten. This is the "magic" from the transcript - AI surfacing patterns in your thinking.

## Vault Location
Daily Notes: `/home/ssk/SSK-Vault/Daily Notes/`
MOCs: `/home/ssk/SSK-Vault/MOCs/`

## Workflow
1. Scan past 7 days of Daily Notes
2. Find:
   - Recurring topics/keywords
   - Tasks that keep getting postponed
   - Ideas mentioned multiple times
   - Connections between different areas
3. Find notes that should be linked but aren't
4. Surface "latent ideas" - topics discussed across different domains
5. Suggest MOC updates

## Example Usage
```
/patterns
ocode-patterns
```

## Output Format
```
# Pattern Discovery - Past 7 Days

## Recurring Topics
- PostgreSQL: mentioned in 4 notes
- WebSocket: mentioned in 3 notes
- Temporal: mentioned in 2 notes

## Postponed Tasks
- Task 1: mentioned 3 times
- Task 2: mentioned 2 times

## Latent Connections
- You've written about PostgreSQL + Docker + Temporal together
- Consider linking: [[40.01 Temporal Observability]] → [[40.02.03 PostgreSQL]]

## Suggested MOC Updates
- Add [[pg-replica-poc]] to [[MOCs/MOC - Database]]
- Add [[observability-2]] to [[MOCs/MOC - Temporal Observability]]

## Forgotten Ideas
- <idea mentioned once but worth revisiting>
```

## Notes
- Run weekly for best results
- Helps notice things you've been thinking about but not consciously tracking
- Creates connections between work and learning
- The magic of combining Obsidian + OpenCode
