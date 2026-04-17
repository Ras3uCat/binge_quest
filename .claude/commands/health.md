Run a quick environment health check for this project.

Check the following and report status for each:

1. **Supabase Local Stack**
   - Run: `supabase status`
   - Expected: DB running on port 54321, Studio on 54323
   - Report: RUNNING / STOPPED / ERROR

2. **Flutter SDK**
   - Run: `flutter --version`
   - Report: version string or NOT_FOUND

3. **Dart Analyzer**
   - Run: `dart analyze execution/frontend/flutter/lib/ --no-fatal-infos 2>&1 | tail -3`
   - Report: error count or CLEAN or NO_LIB_DIR

4. **Stripe CLI**
   - Run: `stripe --version`
   - Report: version string or NOT_FOUND

5. **Active Feature**
   - Check: `planning/features/01_active/` for .md files
   - Report: filename and mode (FLOW/STUDIO) if present, or NO_ACTIVE_FEATURE

6. **MCP Servers**
   - Check `.claude/settings.local.json` for configured mcpServers
   - Report which servers are configured and whether credentials look like placeholders (contain "YOUR_" prefix)

Output a single status table:

| Component | Status | Notes |
|-----------|--------|-------|
| Supabase  | ...    | ...   |
| Flutter   | ...    | ...   |
| Dart      | ...    | ...   |
| Stripe    | ...    | ...   |
| Feature   | ...    | ...   |
| MCP       | ...    | ...   |

For any STOPPED or NOT_FOUND component, show the fix command on the next line.
No analysis beyond the table unless a critical component is broken.
