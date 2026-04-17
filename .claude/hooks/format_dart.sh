#!/usr/bin/env bash
# PostToolUse hook — auto-format Dart files after Edit/Write
# Receives JSON on stdin

INPUT=$(cat)

FILE=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    path = data.get('tool_input', {}).get('file_path', '')
    print(path)
except:
    print('')
" 2>/dev/null)

if [[ "$FILE" == *.dart ]]; then
  dart format --line-length=100 "$FILE" 2>/dev/null
fi

# async hook — no JSON response needed
exit 0
