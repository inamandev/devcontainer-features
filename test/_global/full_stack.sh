#!/bin/bash
set -e
source dev-container-features-test-lib

# --- install-only features work ---
check "codex --version" bash -c 'codex --version'
check "claude --version" bash -c 'claude --version'

# --- trusted: env points at the named volume ---
check "CODEX_HOME=/ai-state/codex" bash -c '[ "$CODEX_HOME" = "/ai-state/codex" ]'
check "CLAUDE_CONFIG_DIR=/ai-state/claude" bash -c '[ "$CLAUDE_CONFIG_DIR" = "/ai-state/claude" ]'

# --- trusted: state dirs exist and are writable by the (non-root) user ---
check "codex state writable" bash -c 'touch /ai-state/codex/.w && rm -f /ai-state/codex/.w'
check "claude state writable" bash -c 'touch /ai-state/claude/.w && rm -f /ai-state/claude/.w'

# --- trusted: codex config seeded, idempotently (no overwrite / no dup) ---
check "codex config.toml exists" test -f /ai-state/codex/config.toml
check "codex config has file cred store" bash -c 'grep -q "cli_auth_credentials_store = \"file\"" /ai-state/codex/config.toml'
check "codex post-create idempotent" bash -c '/usr/local/share/ai-codex-trusted/post-create.sh; test "$(grep -c cli_auth_credentials_store /ai-state/codex/config.toml)" -eq 1'

# --- ai-agents doctor aggregates everything ---
check "ai-agents-doctor runs" ai-agents-doctor
check "doctor shows CODEX_HOME" bash -c 'ai-agents-doctor | grep -q "CODEX_HOME=/ai-state/codex"'
check "doctor shows CLAUDE_CONFIG_DIR" bash -c 'ai-agents-doctor | grep -q "CLAUDE_CONFIG_DIR=/ai-state/claude"'
check "doctor reports codex dir exists" bash -c 'ai-agents-doctor | grep -q "/ai-state/codex exists: yes"'
check "doctor reports claude dir exists" bash -c 'ai-agents-doctor | grep -q "/ai-state/claude exists: yes"'

reportResults
