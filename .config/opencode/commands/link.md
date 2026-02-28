# Link Ideas Command

## Trigger
`/link <topic>` or `ocode-link <topic>`

## Description
Finds connections between a topic and other notes in the vault. Helps discover relationships you may not have consciously made.

## Vault Location
Vault root: `/home/ssk/SSK-Vault/`

## Workflow
1. Take the topic as input
2. Search for notes that link to this topic
3. Find notes that mention this topic but aren't linked
4. Look for connections across different domains:
   - Work → Learning connections
   - Personal → Work connections
   - Infrastructure → Backend connections
5. Suggest specific link additions

## Example Usage
```
/link Temporal
/link PostgreSQL
/link Docker
ocode-link WebSocket
```

## Output Format
```
# Connections: <topic>

## Directly Linked
- [[Note that links to this topic]]

## Mentioned But Not Linked
- [[Note that mentions but doesn't wikilink]]

## Cross-Domain Connections
- Work: [[context/work/project]] - mentions <topic>
- Learning: [[50.01 Learning/roadmap]] - references <topic>
- Infra: [[30.01 Docker]] - related to <topic>

## Suggested Links
- Add [[wikilink]] to [[destination note]]
- Consider linking <topic> → [[MOC - X]]

## Summary
You have X notes about <topic>, spanning Y different vault areas.
```

## Notes
- Use before starting new project work
- Great for finding unexpected connections
- Part of the "second brain" benefit
