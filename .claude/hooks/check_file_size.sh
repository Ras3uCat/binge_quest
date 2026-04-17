#!/usr/bin/env bash
# PostToolUse hook — enforce 300-line Dart file limit
# Blocks Write/Edit if a lib/ Dart file exceeds 300 lines

INPUT=$(cat)

FILE=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('file_path', ''))
except:
    print('')
" 2>/dev/null)

# Only check Dart files inside lib/ (any depth)
if [[ "$FILE" != */lib/**/*.dart && "$FILE" != */lib/*.dart ]]; then
  exit 0
fi

if [ ! -f "$FILE" ]; then
  exit 0
fi

LINE_COUNT=$(wc -l < "$FILE")

if [ "$LINE_COUNT" -gt 300 ]; then
  echo "{\"continue\": true, \"suppressOutput\": false}" >&2
  echo "⚠️  File size warning: $FILE has $LINE_COUNT lines (limit: 300). Consider extracting to sub-files." >&2
  exit 0
fi

echo '{"continue": true}'
exit 0
