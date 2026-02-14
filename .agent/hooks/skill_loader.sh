#!/bin/bash
# 🤖 Automated Skill Loader Hook
echo "--- MANDATORY SKILL EVALUATION ---"
echo "Available Skills found in .cloud/skills/:"
ls .cloud/skills/

echo -e "\nINSTRUCTION: You MUST evaluate if any of the above skills are relevant to the user request."
echo "If YES, you MUST use the Skill() tool to activate them before proceeding."
echo "CRITICAL: Do not implement until specialized context is loaded."