#!/usr/bin/env sh
set -eu

# Stage the installer's downloads under the user's home instead of /tmp. Some base
# images ship /tmp without the standard 1777 permissions, which breaks mktemp for
# non-root users; $HOME is always writable by the user.
TMPDIR="$HOME/.cache/ai-claude"; export TMPDIR
mkdir -p "$TMPDIR"

echo "ai-claude: installing/updating Claude Code for user $(id -un), HOME=$HOME"

/usr/local/share/ai-claude/install-claude-safe.sh

echo "ai-claude: done."
