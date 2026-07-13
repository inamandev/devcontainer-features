#!/usr/bin/env sh
set -eu

user_claude="$HOME/.local/bin/claude"

if [ -x "$user_claude" ]; then
  exec "$user_claude" "$@"
fi

echo "Claude Code is not installed for this user yet: $user_claude" >&2
echo "Try running: /usr/local/share/ai-claude/install-claude-safe.sh" >&2
exit 127
