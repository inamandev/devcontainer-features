#!/usr/bin/env sh
set -eu

# CLAUDE_CONFIG_DIR is provided by this feature's containerEnv (/ai-state/claude, a named volume).
claude_config_dir="${CLAUDE_CONFIG_DIR:-/ai-state/claude}"

# Ensure the directory exists; never overwrite existing Claude config/auth.
mkdir -p "$claude_config_dir"

echo "ai-claude-trusted: CLAUDE_CONFIG_DIR=$claude_config_dir ready. Log in once by running: claude (then /login)."
