#!/bin/sh -e

# restore-claude-code.sh
#   Safely copy history and settings, skipping the new auth files
#
cp -R ~/.claude_backup/projects ~/.claude/
cp -R ~/.claude_backup/settings.json ~/.claude/ 2>/dev/null || true
cp -R ~/.claude_backup/settings.local.json ~/.claude/ 2>/dev/null || true
cp -R ~/.claude_backup/skills ~/.claude/ 2>/dev/null || true
cp -R ~/.claude_backup/commands ~/.claude/ 2>/dev/null || true
cp -R ~/.claude_backup/rules ~/.claude/ 2>/dev/null || true
