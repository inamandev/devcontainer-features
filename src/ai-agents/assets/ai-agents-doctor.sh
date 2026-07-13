#!/usr/bin/env sh
set +e

echo "ai-agents doctor"
echo "================"
echo
echo "CODEX_HOME=${CODEX_HOME:-<unset>}"
echo "CLAUDE_CONFIG_DIR=${CLAUDE_CONFIG_DIR:-<unset>}"
echo
if [ -d /ai-state/codex ]; then echo "/ai-state/codex exists: yes"; else echo "/ai-state/codex exists: no"; fi
if [ -d /ai-state/claude ]; then echo "/ai-state/claude exists: yes"; else echo "/ai-state/claude exists: no"; fi
echo

echo "===== ai-codex-doctor ====="
if command -v ai-codex-doctor >/dev/null 2>&1; then
  ai-codex-doctor
else
  echo "ai-codex-doctor not found (is the ai-codex feature installed?)"
fi
echo

echo "===== ai-claude-doctor ====="
if command -v ai-claude-doctor >/dev/null 2>&1; then
  ai-claude-doctor
else
  echo "ai-claude-doctor not found (is the ai-claude feature installed?)"
fi
