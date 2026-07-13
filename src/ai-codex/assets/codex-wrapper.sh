#!/usr/bin/env sh
set -eu

user_codex="$HOME/.local/bin/codex"

if [ -x "$user_codex" ]; then
  exec "$user_codex" "$@"
fi

echo "Codex is not installed for this user yet: $user_codex" >&2
echo "Try running: /usr/local/share/ai-codex/install-codex-safe.sh" >&2
exit 127
