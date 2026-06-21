#!/usr/bin/env bash
# Bring up the sandbox. Prefers rootless podman-compose, falls back to docker.
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f .env ] || { echo "Creating .env from template (edit secrets!)"; cp .env.example .env; }

if command -v podman-compose >/dev/null 2>&1; then
  COMPOSE="podman-compose"
elif podman compose version >/dev/null 2>&1; then
  COMPOSE="podman compose"
elif docker compose version >/dev/null 2>&1; then
  COMPOSE="docker compose"
else
  echo "Need podman-compose / 'podman compose' / 'docker compose'." >&2; exit 1
fi

echo ">> Building & starting with: $COMPOSE"
$COMPOSE up -d --build

echo ">> Pulling a local coder model into ollama (first run only)..."
podman exec sde-ollama ollama pull qwen2.5-coder:7b 2>/dev/null || \
  echo "   (pull later: podman exec -it sde-ollama ollama pull qwen2.5-coder:7b)"

cat <<'EOF'

Ready.
  Enter the agent box : ./scripts/agent.sh
  IDE remote debug    : attach to localhost:5005
  App port            : http://localhost:8080
EOF
