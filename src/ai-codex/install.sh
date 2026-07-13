#!/usr/bin/env sh
set -eu

echo "Installing ai-codex feature..."

feature_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

install_prereqs() {
  missing=""

  for cmd in curl tar sha256sum jq awk sed head mktemp mkdir chmod mv rm ln uname; do
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
      ca-certificates curl tar coreutils mawk sed findutils jq
    rm -rf /var/lib/apt/lists/*
  elif command_exists apk; then
    apk add --no-cache ca-certificates curl tar coreutils awk sed findutils jq
  elif command_exists dnf; then
    dnf install -y ca-certificates curl tar coreutils gawk sed findutils jq
  elif command_exists microdnf; then
    microdnf install -y ca-certificates curl tar coreutils gawk sed findutils jq
    microdnf clean all
  elif command_exists pacman; then
    pacman -Sy --noconfirm --needed ca-certificates curl tar coreutils awk sed findutils jq
  else
    echo "Unsupported base image: missing required commands and no known package manager was found." >&2
    exit 1
  fi
}

install_prereqs

install -d -m 0755 /usr/local/share/ai-codex

cp "$feature_dir/assets/install-codex-safe.sh" /usr/local/share/ai-codex/install-codex-safe.sh
cp "$feature_dir/assets/post-create.sh"        /usr/local/share/ai-codex/post-create.sh
cp "$feature_dir/assets/codex-wrapper.sh"      /usr/local/bin/codex
cp "$feature_dir/assets/ai-codex-doctor.sh"    /usr/local/bin/ai-codex-doctor

chmod 0755 \
  /usr/local/share/ai-codex/install-codex-safe.sh \
  /usr/local/share/ai-codex/post-create.sh \
  /usr/local/bin/codex \
  /usr/local/bin/ai-codex-doctor

echo "ai-codex feature installation complete."
