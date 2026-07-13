#!/usr/bin/env sh
set +e

echo "ai-codex doctor"
echo "---------------"
echo "USER=$(id -un)"
echo "HOME=$HOME"
echo "CODEX_HOME=${CODEX_HOME:-<unset>}"
echo

echo "codex path:"
command -v codex || true
echo

echo "user codex binary:"
ls -l "$HOME/.local/bin/codex" 2>/dev/null || true
echo

echo "codex version:"
codex --version 2>/dev/null || true
echo

echo "codex login status:"
codex login status 2>/dev/null || true
echo

echo "Codex/OpenAI environment:"
env | grep -E '^(CODEX|OPENAI)_' || true
