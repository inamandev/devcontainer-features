#!/bin/bash
set -e
source dev-container-features-test-lib

# post-create is what actually installs the CLI into the user's home.
# It is idempotent: the safe installer no-ops if already up to date.
check "post-create installs claude" /usr/local/share/ai-claude/post-create.sh
check "claude on PATH" command -v claude
check "user claude binary present" bash -c 'test -x "$HOME/.local/bin/claude"'
check "claude --version via wrapper" claude --version
check "ai-claude-doctor runs" ai-claude-doctor

reportResults
