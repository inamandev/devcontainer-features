#!/usr/bin/env sh
set +e

echo "ai-claude doctor"
echo "----------------"
echo "USER=$(id -un)"
echo "HOME=$HOME"
echo "CLAUDE_CONFIG_DIR=${CLAUDE_CONFIG_DIR:-<unset>}"
echo

echo "claude path:"
command -v claude || true
echo

echo "user claude binary:"
ls -l "$HOME/.local/bin/claude" 2>/dev/null || true
echo

echo "claude version:"
claude --version 2>/dev/null || true
echo

echo "Claude/Anthropic environment:"
env | grep -E '^(CLAUDE|ANTHROPIC)_' || true
