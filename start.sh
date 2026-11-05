#!/bin/bash
# Entrypoint: runs as root only long enough to fix volume ownership,
# then re-executes itself as the unprivileged "dev" user.
set -euo pipefail

if [ "$(id -u)" = "0" ]; then
  mkdir -p "$HOME"
  chown -R dev:dev "$DATA_DIR"
  exec gosu dev env HOME="$HOME" "$0" "$@"
fi

if [ -z "${SUPERSET_API_KEY:-}" ]; then
  echo "ERROR: SUPERSET_API_KEY is not set." >&2
  echo "Create one in the desktop app: Settings -> API Keys, then set it as a Railway variable." >&2
  exit 1
fi

# Keep all host state on the volume.
export SUPERSET_HOME_DIR="${SUPERSET_HOME_DIR:-$HOME/.paradev}"
mkdir -p "$SUPERSET_HOME_DIR" "$HOME/code"

# Git identity (optional but avoids commit failures inside agent runs)
git config --global user.name  "${GIT_USER_NAME:-Paradev Cloud Host}"
git config --global user.email "${GIT_USER_EMAIL:-paradev-host@users.noreply.github.com}"
git config --global --add safe.directory '*'

# GitHub auth: gh reads GH_TOKEN / GITHUB_TOKEN automatically.
if [ -n "${GH_TOKEN:-${GITHUB_TOKEN:-}}" ]; then
  gh auth setup-git || echo "WARN: gh auth setup-git failed (continuing)" >&2
else
  echo "WARN: GH_TOKEN not set; cloning private repos and opening PRs will fail." >&2
fi

echo "Starting host server (foreground)..."
superset --version || true

ARGS=()
if [ -n "${SUPERSET_ORG:-}" ]; then
  ARGS+=(--org "$SUPERSET_ORG")
fi

# Foreground (no --daemon) so Railway tracks the process and restarts it on exit.
exec superset start "${ARGS[@]}"