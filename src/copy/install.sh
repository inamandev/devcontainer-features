#!/usr/bin/env sh
set -eu

echo "Installing copy feature..."

feature_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

cp "$feature_dir/assets/copy" /usr/local/bin/copy
chmod 0755 /usr/local/bin/copy

echo "copy feature installation complete."
