# Daily Note Command

## Trigger
`/daily` or `ocode-daily`

## Description
Creates or opens today's daily note in the Obsidian vault. If it's a new day, extracts tasks from yesterday's note and prepares today's template.

## Vault Locations
- Daily Notes: `/home/ssk/SSK-Vault/Daily Notes/`
- Template: `/home/ssk/SSK-Vault/Templates/Daily Note.md`
- Inbox: `/home/ssk/SSK-Vault/00-Inbox/00.01 TODO.md`
- Capture: `/home/ssk/SSK-Vault/00-Inbox/capture.md`

## Workflow
1. Check if today's note exists at `/home/ssk/SSK-Vault/Daily Notes/YYYY-MM-DD.md`
2. If not, create from template
3. Read yesterday's note to extract pending tasks
4. Show any items in TODO.md
5. Display today's note content

## Example Usage
```
/daily
ocode-daily
ocode-daily 2026-02-28
```

## Notes
- Daily notes follow format: `YYYY-MM-DD.md`
- Tags include the month: `[daily, 2026-02]`
- Use this command at the start and end of each day
