#!/usr/bin/env bash
# PostToolUseFailure hook — auto-diagnose Flutter/Dart build failures
# Receives hook JSON on stdin

INPUT=$(cat)

COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('command', ''))
except:
    print('')
" 2>/dev/null)

# Only trigger for Flutter/Dart build and test commands
if ! echo "$COMMAND" | grep -qE "^flutter (build|run|test)|^dart (compile|test|run)"; then
  exit 0
fi

ERROR=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    out = data.get('tool_output', '')
    if isinstance(out, str):
        print(out)
    elif isinstance(out, dict):
        print(out.get('output') or out.get('stderr') or out.get('stdout') or '')
except:
    print('')
" 2>/dev/null)

if [ -z "$ERROR" ]; then
  exit 0
fi

if ! command -v claude >/dev/null 2>&1; then
  exit 0
fi

DIAGNOSIS=$(echo "$ERROR" | claude --print \
  -p "Flutter/Dart build failure. Respond in exactly this format:
ROOT_CAUSE: <one sentence>
FIX: <file_path:line_number if available> — <exact change needed>
WATCH_FOR: <one secondary risk, or 'none'>
No other text." 2>/dev/null)

echo ""
echo "━━━ Build Failure Analysis ━━━━━━━━━━━━━━━━━━━━━━━"
echo "$DIAGNOSIS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
