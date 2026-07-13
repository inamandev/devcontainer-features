#!/usr/bin/env sh
set -eu

echo "Installing ai-codex-trusted feature..."

feature_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

# Prep the state directory so the first mount of the named volume is usable
# by normal (non-root) devcontainer users. A fresh empty named volume inherits
# these permissions from the image directory.
install -d -m 0755 /ai-state
install -d -m 0777 /ai-state/codex

install -d -m 0755 /usr/local/share/ai-codex-trusted
cp "$feature_dir/assets/post-create.sh" /usr/local/share/ai-codex-trusted/post-create.sh
chmod 0755 /usr/local/share/ai-codex-trusted/post-create.sh

echo "ai-codex-trusted feature installation complete."
