# Morning Briefing Command

## Trigger
`/morning` or `ocode-morning`

## Description
Morning routine that reviews yesterday's work and prepares for today. Extracts tasks, shows pending items, and provides focus suggestions based on your vault patterns.

## Vault Locations
- Daily Notes: `/home/ssk/SSK-Vault/Daily Notes/`
- TODO: `/home/ssk/SSK-Vault/00-Inbox/00.01 TODO.md`
- Context: `/home/ssk/SSK-Vault/context/work/`

## Workflow
1. Read yesterday's daily note (YYYY-MM-DD)
2. Extract incomplete tasks marked with `- [ ]`
3. Show pending items from TODO.md
4. Check for any captured ideas from yesterday
5. Suggest today's focus based on:
   - Incomplete tasks from yesterday
   - Project contexts in vault
   - Recurring patterns in recent notes

6. Create today's daily note if it doesn't exist using template

## Example Usage
```
/morning
ocode-morning
```

## Output Format
```
# Morning Briefing - YYYY-MM-DD

## Yesterday's Incomplete Tasks
- [ ] Task 1
- [ ] Task 2

## Pending TODO Items
- TODO item 1
- TODO item 2

## Today's Focus
- Primary focus area
- Secondary priorities

## Quick Links
- [[Daily Notes/YYYY-MM-DD]] - Yesterday
- [[context/work/overview]] - Work projects
```

## Notes
- Run this at the start of each workday
- Helps maintain continuity between days
- Captures context so you don't have to re-explain to OpenCode
