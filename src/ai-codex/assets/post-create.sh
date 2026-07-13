#!/usr/bin/env sh
set -eu

echo "ai-codex: installing/updating Codex for user $(id -un), HOME=$HOME"

/usr/local/share/ai-codex/install-codex-safe.sh

echo "ai-codex: done."
