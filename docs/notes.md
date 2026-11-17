# Notes and to-dos

Two rofi menus over plain Markdown files, the same on sway and i3, after JustAGuyLinux's
ButterNotes and ButterTodo. The files are fine to edit by hand, sync or grep.

## To-dos: `desktop todo` (`$mod+Shift+t`)

`~/.local/share/desktop/todo.md`:

```markdown
- [ ] Review the config *(added: 2026-11-16, due: 2026-11-17 17:00, priority: high)*
- [ ] Rip the CDs *(added: 2026-11-15, remind: 2026-11-21 10:00)*
- [x] ~~Install woomer~~ *(added: 2026-11-14, done: 2026-11-17)*
```

The menu lists open tasks first (high priority, then the soonest due), done ones after, struck
through. Overdue ones show ⚠ in red; a reminder shows 🔔.

- Type a task and press Enter to add it. `@friday`, `@tomorrow 9am` or `@2026-12-01` at the end
  sets its due date (anything GNU `date -d` reads); `!` at the start makes it high priority.
- Enter on a task opens its actions: mark done, set a due date, set a reminder, edit, priority
  (medium → high → low), delete. A date can be cleared with `clear`.
- Alt+x marks a task done (or not), Alt+d deletes it, Alt+a adds what's typed even when it matches
  a task.
- From a terminal: `desktop todo add <text>`, `desktop todo list`, `desktop todo done <n>`.

`desktop-todo-check.timer` runs `desktop todo check` every 5 minutes: a reminder or due time that
has come notifies once (a day without a time, at 09:00).

## Notes: `desktop notes` (`$mod+Shift+n`)

`~/.local/share/desktop/notes/`:

```
inbox.md              quick notes, newest last: [2026-11-17 09:30] a thought
<name>.md             a note
<project>/<name>.md   a project's notes
```

The menu shows the inbox, a search through every note, your notes (latest first) and the projects.

- Enter opens a note in nvim, in a floating kitty; type a new name and Enter to start one.
- Alt+q puts what's typed in the inbox; Alt+v puts the clipboard there (as a block).
- Alt+m moves a note into a project (pick one or type a new name); Alt+d deletes (after asking).
- The inbox: Enter copies an entry, Alt+m files it into a project's note, Alt+d drops it, Alt+e
  opens the inbox itself.
- The search lists every line of every note; Enter opens that note at that line.
- From a terminal: `desktop notes quick <text>`, `desktop notes clip [text]`. The shell's clipboard
  panel on sway has "Keep in the notes' inbox".

## From the old shell pages

The first time each menu opens it moves the shell's old data across: `todo.json` (priorities kept)
and `notes/notes.json` (each note a file: a checklist as `- [ ]` lines, a code note fenced). The
JSON is kept beside them as `.bak`. Colour tags and pins have no place in plain files and are
dropped.
