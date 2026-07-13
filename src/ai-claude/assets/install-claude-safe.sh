#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="$HOME/.local/bin"
BINARY_NAME="claude"
BIN_PATH="$BIN_DIR/$BINARY_NAME"
DOWNLOAD_BASE_URL="https://downloads.claude.ai/claude-code-releases"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

require_cmd curl
require_cmd sha256sum
require_cmd sed
require_cmd grep
require_cmd tr
require_cmd cut
require_cmd mkdir
require_cmd chmod
require_cmd mv
require_cmd rm
require_cmd mktemp

case "$(uname -s)" in
  Linux) os="linux" ;;
  *)
    echo "Only Linux is supported by this installer." >&2
    exit 1
    ;;
esac

case "$(uname -m)" in
  x86_64|amd64) arch="x64" ;;
  arm64|aarch64) arch="arm64" ;;
  *)
    echo "Unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

if [ "$os" = "linux" ]; then
  if [ -f /lib/libc.musl-x86_64.so.1 ] || [ -f /lib/libc.musl-aarch64.so.1 ] || ldd /bin/ls 2>&1 | grep -q musl; then
    platform="linux-${arch}-musl"
  else
    platform="linux-${arch}"
  fi
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT INT TERM

echo "==> Resolving latest Claude Code version"

latest_version="$(curl -fsSL "$DOWNLOAD_BASE_URL/latest")"

if [[ ! "$latest_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
  echo "Failed to get valid Claude Code version. Got: $latest_version" >&2
  exit 1
fi

installed_version=""
if [ -x "$BIN_PATH" ]; then
  installed_version="$("$BIN_PATH" --version 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 || true)"
fi

echo "==> Latest version: $latest_version"
if [ -n "$installed_version" ]; then
  echo "==> Installed version: $installed_version"
fi
echo "==> Platform: $platform"

if [ "$installed_version" = "$latest_version" ]; then
  echo "Claude Code is already up to date."
  exit 0
fi

manifest_path="$tmp_dir/manifest.json"
binary_path="$tmp_dir/claude"

echo "==> Downloading manifest"
curl -fsSL "$DOWNLOAD_BASE_URL/$latest_version/manifest.json" -o "$manifest_path"

manifest_json="$(tr -d '\n\r\t' < "$manifest_path" | sed 's/ \+/ /g')"

if [[ $manifest_json =~ \"$platform\"[^}]*\"checksum\"[[:space:]]*:[[:space:]]*\"([a-f0-9]{64})\" ]]; then
  expected_checksum="${BASH_REMATCH[1]}"
else
  echo "Could not find checksum for platform: $platform" >&2
  exit 1
fi

echo "==> Downloading Claude binary"
curl -fsSL "$DOWNLOAD_BASE_URL/$latest_version/$platform/claude" -o "$binary_path"

actual_checksum="$(sha256sum "$binary_path" | cut -d' ' -f1)"

if [ "$actual_checksum" != "$expected_checksum" ]; then
  echo "Checksum verification failed" >&2
  echo "expected: $expected_checksum" >&2
  echo "actual:   $actual_checksum" >&2
  exit 1
fi

chmod 0755 "$binary_path"

mkdir -p "$BIN_DIR"

tmp_target="$BIN_DIR/.claude.$$"
mv "$binary_path" "$tmp_target"
mv -f "$tmp_target" "$BIN_PATH"

echo "==> Verifying installed binary"
"$BIN_PATH" --version

echo "Claude Code installed/updated successfully:"
echo "$BIN_PATH"
