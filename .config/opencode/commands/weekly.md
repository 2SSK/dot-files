# Weekly Review Command

## Trigger
`/weekly` or `ocode-weekly`

## Description
Comprehensive weekly review that combines pattern discovery, task review, and vault maintenance.

## Vault Locations
- Daily Notes: `/home/ssk/SSK-Vault/Daily Notes/`
- TODO: `/home/ssk/SSK-Vault/00-Inbox/00.01 TODO.md`
- Capture: `/home/ssk/SSK-Vault/00-Inbox/capture.md`
- MOCs: `/home/ssk/SSK-Vault/MOCs/`

## Workflow
1. **Task Review**
   - Scan past week's daily notes
   - List all completed tasks
   - List all incomplete tasks
   - Review TODO.md for pending items

2. **Capture Processing**
   - Review capture.md for the week
   - Convert captures to proper notes if needed
   - Archive processed captures

3. **Pattern Discovery** (from /patterns)
   - Find recurring topics
   - Find postponed items
   - Surface latent connections

4. **MOC Maintenance**
   - Check for new notes that need linking
   - Identify orphan notes
   - Update MOCs with new links

5. **Summary**
   - Week's accomplishments
   - Week's learnings
   - Focus for next week

## Example Usage
```
/weekly
ocode-weekly
```

## Output Format
```
# Weekly Review - Week of YYYY-MM-DD

## Accomplishments
- [ ] Completed task 1
- [ ] Completed task 2

## Pending Tasks
- [ ] Task to carry over
- [ ] Another pending task

## Capture Processing
- Processed: X captures
- Archived: Y items

## Patterns This Week
- Topic 1: mentioned X times
- Topic 2: mentioned Y times

## MOC Updates Needed
- Link X to Y
- Update Z MOC

## Focus for Next Week
1. Priority 1
2. Priority 2

## Notes
- Great to run on Monday mornings or Sunday evenings
- Keeps vault organized and links fresh
- Maintains the "thinking partner" relationship with OpenCode
