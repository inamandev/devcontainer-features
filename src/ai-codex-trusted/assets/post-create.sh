#!/usr/bin/env sh
set -eu

# CODEX_HOME is provided by this feature's containerEnv (/ai-state/codex, a named volume).
codex_home="${CODEX_HOME:-/ai-state/codex}"

mkdir -p "$codex_home"

config="$codex_home/config.toml"
[ -e "$config" ] || : > "$config"

# Store login credentials on disk (so they persist on the volume), without
# overwriting existing configuration. Only add the key if it is absent.
if ! grep -q '^[[:space:]]*cli_auth_credentials_store[[:space:]]*=' "$config"; then
  printf 'cli_auth_credentials_store = "file"\n' >> "$config"
fi

echo "ai-codex-trusted: CODEX_HOME=$codex_home ready. Log in once with: codex login --device-auth"
