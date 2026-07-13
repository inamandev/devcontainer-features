#!/usr/bin/env sh
set -eu

# Stage the installer's downloads under the user's home instead of /tmp. Some base
# images ship /tmp without the standard 1777 permissions, which breaks mktemp for
# non-root users; $HOME is always writable by the user.
TMPDIR="$HOME/.cache/ai-codex"; export TMPDIR
mkdir -p "$TMPDIR"

echo "ai-codex: installing/updating Codex for user $(id -un), HOME=$HOME"

/usr/local/share/ai-codex/install-codex-safe.sh

echo "ai-codex: done."
