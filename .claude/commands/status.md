Report current project workflow state. Facts only — no analysis, no implementation.

1. **Active Feature**
   - Read: `planning/features/01_active/*.md`
   - Report: ID, title, mode (FLOW/STUDIO), status, and count of unchecked acceptance criteria items

2. **Backlog**
   - Count files in `planning/features/00_backlog/`
   - List the top 3 by filename (lowest NNN first) with title only

3. **Recent QA Reports**
   - List files in `qa/reports/` sorted by date, newest 3 only
   - For each: filename and first STATUS line (if exists)
   - Report NO_REPORTS if directory empty or missing

4. **Recent Decisions**
   - Read last 2 ADR entries from `planning/decisions.md`
   - Report ADR ID and decision title only
   - Report EMPTY if no decisions logged yet

5. **Git State**
   - Run: `git status --short`
   - Run: `git log --oneline -5`

Output a concise summary. One section per item above.
