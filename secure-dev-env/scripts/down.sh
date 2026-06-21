#!/usr/bin/env bash
# Tear down. With -v also drops the ephemeral target/ and maven cache volumes.
set -euo pipefail
cd "$(dirname "$0")/.."
if command -v podman-compose >/dev/null 2>&1; then C="podman-compose";
elif podman compose version >/dev/null 2>&1; then C="podman compose";
else C="docker compose"; fi
$C down "${@:-}"
