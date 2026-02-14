#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: $0 <runpod_url> [additional_args...]"
    exit 1
fi

URL="$1"
shift

# Sanitize URL: remove trailing slashes
URL=$(echo "$URL" | sed 's:/*$::')

# Ensure URL has NO path for OLLAMA_HOST (it expects base URL, often without /v1 for the binary, but depends on version)
# However, for the agents.json openai config, we usually need /v1 if using openai compatible endpoint.
# The user's RunPod likely exposes Ollama APIs at root and OpenAI at /v1.

# For agents.json (OpenAI provider via Claude CLI)
if [[ "$URL" == */v1 ]]; then
    JSON_ENDPOINT="$URL"
    # Strip /v1 for OLLAMA_HOST
    OLLAMA_HOST_URL="${URL%/v1}"
else
    JSON_ENDPOINT="${URL}/v1"
    OLLAMA_HOST_URL="$URL"
fi

CONFIG=".claude/agents.json"
BACKUP=".claude/agents.json.bak"

# Backup config
cp "$CONFIG" "$BACKUP"

echo "Success: Configuring Flutter Agent on RunPod..."
echo "Pod URL: $OLLAMA_HOST_URL"

# 1. Restore Architect to Anthropic (Claude Pro)
# 2. Set Flutter Agent to RunPod (OpenAI type)
# 3. Set Default Routing to Flutter
jq --arg url "$JSON_ENDPOINT" '
  .agents.architect.type = "anthropic" |
  .agents.architect.model = "claude-3.5-sonnet" |
  .agents.architect.role = "Architect" |
  .agents.architect.description = "System design authority, reviews STUDIO plans, approves architectural changes." |
  del(.agents.architect.endpoint) |
  del(.agents.architect.apiKey) |
  
  .agents.flutter.endpoint = $url |
  .agents.flutter.type = "openai" |
  .agents.flutter.apiKey = "ollama" |
  .agents.flutter.model = "qwen2.5-coder:7b" |
  .routing.default = "flutter"
' "$CONFIG" > "${CONFIG}.tmp" && mv "${CONFIG}.tmp" "$CONFIG"

echo "Exporting OLLAMA_HOST=$OLLAMA_HOST_URL"
export OLLAMA_HOST="$OLLAMA_HOST_URL"

echo "Launching Claude via Ollama bridge..."
# Launch via ollama as requested by user
ollama launch claude "$@"
