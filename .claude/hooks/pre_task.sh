#!/usr/bin/env bash
# 🎯 BingeQuest Pre-Task Synchronizer

ACTIVE_TASK=$(ls planning/features/01_active/*.md 2>/dev/null | head -1)

if [ -z "$ACTIVE_TASK" ]; then
  echo "ℹ️  No active task in planning/features/01_active/"
  exit 0
fi

# 1. Enforcement of STUDIO protocol
if grep -q "STUDIO" "$ACTIVE_TASK"; then
  echo "✅ STUDIO task confirmed in $ACTIVE_TASK"
fi

# 2. Skill & Context Audit
if grep -qi "stripe\|payment" "$ACTIVE_TASK"; then
  echo "⚖️ ARCHITECT ADVISORY: Task involves Payments. Ensure .claude/skills/stripe-checkout-subscriptions/ is loaded."
fi

if grep -qi "flutter\|widget\|screen" "$ACTIVE_TASK"; then
  echo "📱 ARCHITECT ADVISORY: UI Task. Flutter agent should lead implementation."
fi

# 3. Clean Context Signal
echo "--- 📋 MISSION START ---"
head -n 5 "$ACTIVE_TASK"
