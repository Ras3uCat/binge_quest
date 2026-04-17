Fix the following issue: $ARGUMENTS

Follow this protocol:

1. **Understand before touching anything**
   - Read the file(s) mentioned in the issue
   - Identify the root cause (not the symptom)
   - If investigation requires reading >3 files, spawn a subagent

2. **Classify the fix**
   - FLOW: Small, contained fix (single file, no schema change) — implement directly
   - STUDIO: Multi-file, schema change, or payment logic — create a feature file in `00_backlog/` first, get Architect sign-off, then implement

3. **Implement**
   - Make the minimal change that fixes the root cause
   - Do NOT refactor surrounding code unless it caused the bug
   - Do NOT add features or "while I'm here" improvements

4. **Verify**
   - Run `dart analyze` — zero new warnings
   - Run relevant tests — all passing
   - If the bug was in a repository/service, add a regression test

5. **Log**
   - If the fix reveals an architectural lesson, add an entry to `planning/decisions.md`

Constraints:
- Never skip `dart analyze` check
- Never fix a symptom — fix the root cause
- Never use `// ignore:` annotations as a fix
