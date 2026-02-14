#!/usr/bin/env bash
# 🎯 BingeQuest Pre-Task Synchronizer

# 1. Enforcement of STUDIO protocol
if grep -q "STUDIO" planning/current_task.md; then
  if [ ! -f STUDIO_PLAN.md ]; then
    echo "❌ ARCHITECT BLOCK: STUDIO task detected but STUDIO_PLAN.md is missing."
    echo "   Action: Ask the Planner (AntiGravity) to generate the plan first."
    exit 1
  fi
  echo "✅ STUDIO_PLAN.md verified."
fi

# 2. Skill & Context Audit
# Check if the task involves critical domains and suggest skills
if grep -qi "stripe\|payment" planning/current_task.md; then
  echo "⚖️ ARCHITECT ADVISORY: Task involves Payments. Ensure .cloud/skills/payments_dev/ is loaded."
fi

if grep -qi "flutter\|widget\|screen" planning/current_task.md; then
  echo "📱 ARCHITECT ADVISORY: UI Task. Frontend worker (Local Ollama) should lead implementation."
fi

# 3. Clean Context Signal
echo "--- 📋 MISSION START ---"
head -n 5 planning/current_task.md # Briefly show the goal