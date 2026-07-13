#!/bin/bash
set -e
source dev-container-features-test-lib

# post-create is what actually installs the CLI into the user's home.
# It is idempotent: the safe installer no-ops if already up to date.
check "post-create installs codex" /usr/local/share/ai-codex/post-create.sh
check "codex on PATH" command -v codex
check "user codex binary present" bash -c 'test -x "$HOME/.local/bin/codex"'
check "codex --version via wrapper" codex --version
check "ai-codex-doctor runs" ai-codex-doctor

reportResults
