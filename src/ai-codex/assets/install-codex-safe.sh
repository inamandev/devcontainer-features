#!/usr/bin/env sh
set -eu

BIN_DIR="$HOME/.local/bin"
BIN_PATH="$BIN_DIR/codex"
INSTALL_ROOT="$HOME/.local/share/codex-standalone"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

file_sha256() {
  sha256sum "$1" | awk '{print $1}'
}

release_asset_digest() {
  # $1 = asset name, $2 = release JSON path. Prints the lowercase hex sha256, or nothing.
  jq -r --arg name "$1" '(.assets[] | select(.name == $name) | .digest) // ""' "$2" \
    | sed -n 's/^sha256://p' | head -n 1
}

archive_digest_from_manifest() {
  asset="$1"
  manifest_path="$2"

  awk -v asset="$asset" '
    $2 == asset && $1 ~ /^[0-9a-fA-F]{64}$/ {
      print tolower($1)
      found = 1
      exit
    }

    END {
      if (!found) exit 1
    }
  ' "$manifest_path"
}

require_cmd curl
require_cmd jq
require_cmd tar
require_cmd sha256sum
require_cmd awk
require_cmd sed
require_cmd head
require_cmd mktemp
require_cmd mkdir
require_cmd chmod
require_cmd mv
require_cmd rm
require_cmd ln

case "$(uname -s)" in
  Linux) ;;
  *)
    echo "Only Linux is supported by this installer." >&2
    exit 1
    ;;
esac

case "$(uname -m)" in
  x86_64|amd64)
    target="x86_64-unknown-linux-musl"
    ;;
  aarch64|arm64)
    target="aarch64-unknown-linux-musl"
    ;;
  *)
    echo "Unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT INT TERM

echo "==> Resolving latest Codex release"

release_json="$tmp_dir/release.json"
curl -fsSL "https://api.github.com/repos/openai/codex/releases/latest" -o "$release_json"

# Fail loudly if the API response is incomplete / not valid JSON.
jq empty "$release_json" 2>/dev/null || {
  echo "GitHub API response was incomplete or not valid JSON." >&2
  exit 1
}

latest_version="$(jq -r '.tag_name // ""' "$release_json" | sed -n 's/^rust-v//p' | head -n 1)"

if [ -z "$latest_version" ]; then
  echo "Could not resolve latest Codex release version." >&2
  exit 1
fi

installed_version=""
if [ -x "$BIN_PATH" ]; then
  installed_version="$("$BIN_PATH" --version 2>/dev/null | sed -n 's/.* \([0-9][0-9A-Za-z.+-]*\)$/\1/p' | head -n 1 || true)"
fi

echo "==> Latest version: $latest_version"
if [ -n "$installed_version" ]; then
  echo "==> Installed version: $installed_version"
fi
echo "==> Target: $target"

if [ "$installed_version" = "$latest_version" ]; then
  echo "Codex CLI is already up to date."
  exit 0
fi

archive="codex-package-$target.tar.gz"
checksums="codex-package_SHA256SUMS"

base_url="https://github.com/openai/codex/releases/download/rust-v$latest_version"
archive_url="$base_url/$archive"
checksums_url="$base_url/$checksums"

archive_path="$tmp_dir/$archive"
checksums_path="$tmp_dir/$checksums"

echo "==> Reading release asset digests"

expected_checksums_sha="$(release_asset_digest "$checksums" "$release_json")"
[ -n "$expected_checksums_sha" ] || {
  echo "Could not find digest for $checksums in the GitHub API response." >&2
  exit 1
}

echo "==> Downloading checksum manifest"
curl -fsSL "$checksums_url" -o "$checksums_path"

actual_checksums_sha="$(file_sha256 "$checksums_path")"

if [ "$actual_checksums_sha" != "$expected_checksums_sha" ]; then
  echo "Checksum manifest verification failed" >&2
  echo "expected: $expected_checksums_sha" >&2
  echo "actual:   $actual_checksums_sha" >&2
  exit 1
fi

expected_archive_sha="$(archive_digest_from_manifest "$archive" "$checksums_path")"

echo "==> Downloading Codex package"
curl -fsSL "$archive_url" -o "$archive_path"

actual_archive_sha="$(file_sha256 "$archive_path")"

if [ "$actual_archive_sha" != "$expected_archive_sha" ]; then
  echo "Codex archive verification failed" >&2
  echo "expected: $expected_archive_sha" >&2
  echo "actual:   $actual_archive_sha" >&2
  exit 1
fi

release_dir="$INSTALL_ROOT/$latest_version-$target"
stage_dir="$INSTALL_ROOT/.staging-$latest_version-$target-$$"

echo "==> Installing to $release_dir"

mkdir -p "$INSTALL_ROOT" "$BIN_DIR"
rm -rf "$stage_dir"
mkdir -p "$stage_dir"

tar -xzf "$archive_path" -C "$stage_dir"

if [ ! -f "$stage_dir/bin/codex" ]; then
  echo "Extracted package does not contain bin/codex." >&2
  exit 1
fi

chmod 0755 "$stage_dir/bin/codex"

if [ -f "$stage_dir/codex-path/rg" ]; then
  chmod 0755 "$stage_dir/codex-path/rg"
fi

if [ -f "$stage_dir/codex-resources/bwrap" ]; then
  chmod 0755 "$stage_dir/codex-resources/bwrap"
fi

rm -rf "$release_dir"
mv "$stage_dir" "$release_dir"

tmp_link="$BIN_DIR/.codex.$$"
rm -f "$tmp_link"
ln -s "$release_dir/bin/codex" "$tmp_link"
mv -Tf "$tmp_link" "$BIN_PATH" 2>/dev/null || mv -f "$tmp_link" "$BIN_PATH"

# Keep only the currently installed standalone release.
for dir in "$INSTALL_ROOT"/*; do
  [ -e "$dir" ] || continue
  [ "$dir" = "$release_dir" ] && continue
  rm -rf "$dir"
done

echo "==> Verifying installed binary"
"$BIN_PATH" --version

echo "Codex CLI installed/updated successfully:"
echo "$BIN_PATH -> $release_dir/bin/codex"
