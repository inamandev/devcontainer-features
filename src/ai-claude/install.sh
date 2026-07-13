#!/usr/bin/env sh
set -eu

echo "Installing ai-claude feature..."

feature_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

install_prereqs() {
  missing=""

  for cmd in bash curl sha256sum sed grep tr cut head mktemp mkdir chmod mv rm; do
    if ! command_exists "$cmd"; then
      missing="$missing $cmd"
    fi
  done

  if [ -z "$missing" ]; then
    return 0
  fi

  echo "Missing commands:$missing"
  echo "Installing prerequisite packages..."

  if command_exists apt-get; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates bash curl coreutils sed grep
    rm -rf /var/lib/apt/lists/*
  elif command_exists apk; then
    apk add --no-cache ca-certificates bash curl coreutils sed grep
  elif command_exists dnf; then
    dnf install -y ca-certificates bash curl coreutils sed grep
  elif command_exists microdnf; then
    microdnf install -y ca-certificates bash curl coreutils sed grep
    microdnf clean all
  elif command_exists pacman; then
    pacman -Sy --noconfirm --needed ca-certificates bash curl coreutils sed grep
  else
    echo "Unsupported base image: missing required commands and no known package manager was found." >&2
    exit 1
  fi
}

install_prereqs

install -d -m 0755 /usr/local/share/ai-claude

cp "$feature_dir/assets/install-claude-safe.sh" /usr/local/share/ai-claude/install-claude-safe.sh
cp "$feature_dir/assets/post-create.sh"         /usr/local/share/ai-claude/post-create.sh
cp "$feature_dir/assets/claude-wrapper.sh"      /usr/local/bin/claude
cp "$feature_dir/assets/ai-claude-doctor.sh"    /usr/local/bin/ai-claude-doctor

chmod 0755 \
  /usr/local/share/ai-claude/install-claude-safe.sh \
  /usr/local/share/ai-claude/post-create.sh \
  /usr/local/bin/claude \
  /usr/local/bin/ai-claude-doctor

echo "ai-claude feature installation complete."
