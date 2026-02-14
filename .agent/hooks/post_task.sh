#!/usr/bin/env bash
# 📱 BingeQuest KDE Connect Notifier

DEVICE_ID="dde92f39ac8040a08b80b8f6e6e964f8" # Replace with your ID from kdeconnect-cli -l
STATUS=$?

if [ $STATUS -eq 0 ]; then
  # SUCCESS: Just a standard notification
  TITLE="✅ Task Done"
  MESSAGE="Sub-task finished successfully. Ready for review."
  
  kdeconnect-cli -d $DEVICE_ID --ping-msg "$TITLE: $MESSAGE"
  echo "📱 Success notification sent to phone."
else
  # FAILURE: Send notification AND ring the phone
  TITLE="🚨 Task Failed"
  MESSAGE="The subagent is stuck or a build error occurred. Intervention required!"
  
  # 1. Send the text alert
  kdeconnect-cli -d $DEVICE_ID --ping-msg "$TITLE: $MESSAGE"
  
  # 2. TRIGGER EMERGENCY RING
  # This will make your phone ring until you find it and stop it.
  kdeconnect-cli -d $DEVICE_ID --ring
  
  echo "🚨 FAILURE DETECTED. Phone is ringing!"
fi