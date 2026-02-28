# Quick Capture Command

## Trigger
`/capture <content>` or `ocode-capture <content>`

## Description
Quickly capture ideas, notes, or tasks to the vault inbox for later processing. Appends to capture file with timestamp.

## Vault Location
Capture file: `/home/ssk/SSK-Vault/00-Inbox/capture.md`

## Workflow
1. Take the content provided
2. Append to capture.md with timestamp
3. Format: `- YYYY-MM-DD HH:MM: <content>`
4. Confirm capture to user

## Example Usage
```
/capture Think about using Redis for caching
/capture Review PostgreSQL WAL settings
ocode-capture New feature idea for agent orchestrator
ocode-capture Check connection pooling settings
```

## Output Format
```
✓ Captured: <content>
Added to: /home/ssk/SSK-Vault/00-Inbox/capture.md
```

## Notes
- Use for quick captures during work
- Review capture.md during weekly review
- Links will be created during end-of-day processing
- Alternative: Use TODO.md for actionable items
