#!/usr/bin/env sh
set -eu

echo "ai-claude: installing/updating Claude Code for user $(id -un), HOME=$HOME"

/usr/local/share/ai-claude/install-claude-safe.sh

echo "ai-claude: done."
