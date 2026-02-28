# Vault Search Command

## Trigger
`/search <query>` or `ocode-search <query>`

## Description
Searches the entire vault for notes related to the query and provides a summary of relevant knowledge.

## Vault Location
Vault root: `/home/ssk/SSK-Vault/`

## Workflow
1. Search vault for files and content matching the query
2. Check:
   - File names
   - Headings
   - Content
   - Tags
   - Wikilinks
3. Summarize findings by:
   - Direct matches (files about the topic)
   - Related notes (linked from/to the topic)
   - MOCs that might contain relevant information
4. Provide key insights and links

## Example Usage
```
/search PostgreSQL replication
/search WebSocket
/search Temporal
ocode-search postgres
ocode-search clustering
```

## Output Format
```
# Search Results: <query>

## Direct Matches
- [[40.02.03.05 Database – PostgreSQL Replication Deep Dive]]
- [[40.02.03.09 Database – High Availability and Failover]]

## Related Notes
- [[MOCs/MOC - Database]]
- [[context/work/pg-replica-poc]]

## Key Insights
<summary of what you know about this topic from your vault>

## Suggested Next Steps
- Review direct matches
- Check MOC for overview
- Link to current project if applicable
```

## Notes
- Great for research or refreshing knowledge
- Uses your vault as a "second brain" memory
- Complements project context with specific topic knowledge
