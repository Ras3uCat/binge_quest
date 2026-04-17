#!/usr/bin/env bash
# PreToolUse hook — quality gate before Bash tool runs
# Blocks git commits containing secrets or dart analyze failures

INPUT=$(cat)

COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('command', ''))
except:
    print('')
" 2>/dev/null)

# Gate: block git commit if staged files reference legacy paths
if echo "$COMMAND" | grep -q "^git commit"; then
  STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)
  if [ -n "$STAGED_FILES" ]; then
    # Exempt docs that legitimately reference old paths for historical context
    CHECKABLE=$(echo "$STAGED_FILES" | grep -vE "^planning/features/|^planning/decisions|memory/" || true)
    if [ -n "$CHECKABLE" ]; then
      STALE_HITS=$(echo "$CHECKABLE" | xargs grep -lE \
        "\.cloud/skills/|\.agent/hooks/|/\.agent/|\"agents\.json\"" \
        2>/dev/null || true)
      if [ -n "$STALE_HITS" ]; then
        echo "{\"continue\": false, \"stopReason\": \"Legacy path reference detected in: $STALE_HITS — use .claude/ paths. Replace .cloud/skills/ → .claude/skills/, .agent/hooks/ → .claude/hooks/.\"}"
        exit 0
      fi
    fi
  fi
fi

# Gate: block git commit if staged files contain secret patterns
if echo "$COMMAND" | grep -q "^git commit"; then
  STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)
  if [ -n "$STAGED_FILES" ]; then
    SECRET_HITS=$(echo "$STAGED_FILES" | xargs grep -lE \
      "(sk_live_[a-zA-Z0-9]{20,}|sk_test_[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{36}|AKIA[0-9A-Z]{16}|-----BEGIN (RSA |EC )?PRIVATE KEY)" \
      2>/dev/null || true)
    if [ -n "$SECRET_HITS" ]; then
      echo "{\"continue\": false, \"stopReason\": \"Potential secret detected in staged files: $SECRET_HITS — remove before committing. Use .env for credentials, not source files.\"}"
      exit 0
    fi
  fi
fi

# Gate: block git commit if staged Dart files have analyze errors
if echo "$COMMAND" | grep -q "^git commit"; then
  APP_DIR="execution/frontend/flutter"
  if [ -d "$APP_DIR/lib" ]; then
    STAGED_DART=$(git diff --cached --name-only --diff-filter=ACMR | grep "^$APP_DIR/lib/.*\.dart$")
    if [ -n "$STAGED_DART" ]; then
      ANALYSIS=$(cd "$APP_DIR" && echo "$STAGED_DART" | sed "s|^$APP_DIR/||" | xargs dart analyze --fatal-infos 2>&1)
      EXIT_CODE=$?
      if [ $EXIT_CODE -ne 0 ]; then
        echo "{\"continue\": false, \"stopReason\": \"dart analyze failed on staged files — fix errors before committing:\\n$ANALYSIS\"}"
        exit 0
      fi
    fi
  fi
fi

echo '{"continue": true}'
exit 0
