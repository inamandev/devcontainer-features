# AI Agents Dev Container Features

Reusable [Dev Container Features](https://containers.dev/implementors/features/) that install the **Claude Code** and **OpenAI Codex** CLIs into a dev container, with optional persistent login stored on named volumes — so you install and authenticate **once**, not per project.

## Features

| Feature | What it does |
|---|---|
| `ai-codex` | Installs the Codex CLI (checksum-verified) into the container user's `~/.local/bin`. |
| `ai-claude` | Installs the Claude Code CLI (checksum-verified) into the container user's `~/.local/bin`. |
| `ai-codex-trusted` | Adds persistent Codex login: sets `CODEX_HOME=/ai-state/codex` and mounts the `ai-codex-global` volume there. |
| `ai-claude-trusted` | Adds persistent Claude login: sets `CLAUDE_CONFIG_DIR=/ai-state/claude` and mounts the `ai-claude-global` volume there. |
| `ai-agents` | Convenience bundle: pulls in both trusted features and adds `ai-agents-doctor`. |

> Replace `OWNER/REPO` in the examples below with your published GHCR path (e.g. `ghcr.io/you/devcontainer-features`).

## Quick start

Install just the CLIs (no persistent login):

```jsonc
"features": {
  "ghcr.io/OWNER/REPO/ai-codex:1": {},
  "ghcr.io/OWNER/REPO/ai-claude:1": {}
}
```

Install **and** persist login across rebuilds and projects (recommended):

```jsonc
"features": {
  "ghcr.io/OWNER/REPO/ai-agents:1": {}
}
```

`ai-agents` brings in `ai-codex` + `ai-claude` + the two trusted features, so both CLIs are installed and their logins persist on the `ai-codex-global` / `ai-claude-global` volumes.

## Using with Zed

Zed's dev container support (as of Zed 1.7.x) does **not** resolve feature `dependsOn`, so the `ai-agents` bundle and the `-trusted → install` links pull in nothing on their own. **List every feature explicitly** instead (adding `ai-agents` alone only gives you `ai-agents-doctor`):

```jsonc
"features": {
  "ghcr.io/OWNER/REPO/ai-codex:1": {},
  "ghcr.io/OWNER/REPO/ai-codex-trusted:1": {},
  "ghcr.io/OWNER/REPO/ai-claude:1": {},
  "ghcr.io/OWNER/REPO/ai-claude-trusted:1": {}
}
```

Zed may also not run each feature's `postCreateCommand`. If `codex` / `claude` aren't installed after the container builds, add a **top-level** `postCreateCommand` to your `devcontainer.json`:

```jsonc
"postCreateCommand": "/usr/local/share/ai-codex/post-create.sh && /usr/local/share/ai-claude/post-create.sh"
```

Two more podman + Zed notes:
- Set `"use_podman": true` in your Zed `settings.json`.
- Your base image's `/tmp` must be world-writable (`1777`). Some custom images leave it at `755`, which breaks non-root installs **and** Zed's own remote server — fix it with `RUN chmod 1777 /tmp` in the base image's Dockerfile.

## Authenticate once

You log in **one time**. The login token is written to a named volume (`CODEX_HOME` / `CLAUDE_CONFIG_DIR` point at it), so every container that uses a trusted feature — this project rebuilt, or any other project — reuses it.

Open a terminal **inside the dev container** and run:

**Codex**
```sh
codex login --device-auth
```
Open the printed URL and enter the code in your browser. The token is saved to `/ai-state/codex` (on the `ai-codex-global` volume).

**Claude Code**
```sh
claude
# then, inside Claude:
/login
```
Follow the browser/URL flow. Config + credentials are saved to `/ai-state/claude` (on the `ai-claude-global` volume).

That's it. Rebuild the container or open a different project with these features — **you stay logged in**.

### Check status

```sh
ai-agents-doctor      # shows CODEX_HOME / CLAUDE_CONFIG_DIR, the volume dirs, and both CLIs
codex login status
```

### Reset / log out

```sh
podman volume rm ai-codex-global ai-claude-global   # (docker volume rm on Docker)
```
Then log in again on the next container start.

## How it works

- `ai-codex` / `ai-claude` run their checksum-verifying installers at container-create time (`postCreateCommand`) **as the container user**, installing into `~/.local/bin`, with a `/usr/local/bin` wrapper on `PATH`.
- The trusted features add:
  - `containerEnv`: `CODEX_HOME=/ai-state/codex`, `CLAUDE_CONFIG_DIR=/ai-state/claude`
  - a named-volume `mount` at each of those paths (`ai-codex-global`, `ai-claude-global`)
  - a post-create step that prepares the directory (and seeds `config.toml` with `cli_auth_credentials_store = "file"` for codex) **without overwriting** anything.
- Because the CLIs read their auth from those env-pointed dirs, and the dirs are backed by named volumes, your login survives container rebuilds and is shared across projects.

You do **not** need to create the volumes beforehand — a named volume is created automatically the first time a container mounts it.

## Security

- Auth is **never** baked into images or committed to git.
- Persistence is **only** via the named volumes `ai-codex-global` / `ai-claude-global`.
- No host `~/.codex` / `~/.claude` is mounted or copied by the features.
- No API keys are set (`OPENAI_API_KEY` / `ANTHROPIC_API_KEY` are not configured) — these features use interactive login, not API billing.

## Seeding auth from an existing login (optional)

Prefer the in-container login above. If you must import an existing host login into the volume — note this copies tokens off your host, so it's your call:

```sh
podman volume create ai-codex-global
podman run --rm -v ai-codex-global:/dst -v "$HOME/.codex":/src:ro alpine \
  sh -c 'cp -a /src/. /dst/ && chown -R 1000:1000 /dst'
# repeat for  ~/.claude -> ai-claude-global
```

The files must end up owned by **UID 1000** (the container user), and it only works if the token isn't machine- or keyring-bound.
