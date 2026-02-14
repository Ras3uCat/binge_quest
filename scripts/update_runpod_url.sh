#!/bin/bash

# Check if an argument was provided
if [ -z "$1" ]; then
  echo "Usage: $0 <new_runpod_url_id>"
  echo "Example: $0 yw2lc2hxdiefjo-11434"
  echo "Or full URL: $0 https://yw2lc2hxdiefjo-11434.proxy.runpod.net/v1"
  exit 1
fi

INPUT="$1"
AGENTS_FILE=".claude/agents.json"

# Determine if the input is a full URL or just the ID
if [[ "$INPUT" == https* ]]; then
  NEW_URL="$INPUT"
else
  # Assume it's just the ID, construct the URL
  # Format: https://<ID>.proxy.runpod.net/v1
  NEW_URL="https://${INPUT}.proxy.runpod.net/v1"
fi

if [ ! -f "$AGENTS_FILE" ]; then
    echo "Error: $AGENTS_FILE not found. Run this from the project root."
    exit 1
fi

echo "Updating flutter agent endpoint to: $NEW_URL"

# Use a temporary file to store the updated JSON
TMP_FILE=$(mktemp)

# Update the JSON using jq
jq --arg url "$NEW_URL" '.agents.flutter.endpoint = $url' "$AGENTS_FILE" > "$TMP_FILE"

# Check if jq succeeded
if [ $? -eq 0 ]; then
  mv "$TMP_FILE" "$AGENTS_FILE"
  echo "Successfully updated $AGENTS_FILE"
else
  echo "Error updating JSON file."
  rm "$TMP_FILE"
  exit 1
fi
