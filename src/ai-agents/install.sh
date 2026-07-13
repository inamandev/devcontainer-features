#!/usr/bin/env sh
set -eu

echo "Installing ai-agents feature..."

feature_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

cp "$feature_dir/assets/ai-agents-doctor.sh" /usr/local/bin/ai-agents-doctor
chmod 0755 /usr/local/bin/ai-agents-doctor

echo "ai-agents feature installation complete."
