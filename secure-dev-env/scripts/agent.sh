#!/usr/bin/env bash
# Enter the dev box and start the coding agent of your choice.
#   ./scripts/agent.sh aider      (default)
#   ./scripts/agent.sh opencode
#   ./scripts/agent.sh shell      (just a shell)
set -euo pipefail
AGENT="${1:-aider}"

run() { podman exec -it sde-dev bash -lc "$1"; }

case "$AGENT" in
  aider)
    # Talks to the local gateway; --no-auto-commits keeps you in control.
    run 'aider --openai-api-base "$OPENAI_API_BASE" \
               --openai-api-key "$OPENAI_API_KEY" \
               --model openai/local-coder' ;;
  opencode)
    run 'OPENAI_BASE_URL="$OPENAI_API_BASE" opencode' ;;
  shell)
    run 'exec bash' ;;
  *)
    echo "Unknown agent: $AGENT (use aider|opencode|shell)" >&2; exit 1 ;;
esac
