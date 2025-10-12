#!/usr/bin/env bash
set -euo pipefail
# Health check tries (in order):
# 1) Process name
if pgrep -f "start_dedicated_server.sh" >/dev/null; then exit 0; fi
# 2) Optional port check if GAME_PORT is set
if [[ -n "${GAME_PORT:-}" ]]; then
  (echo >/dev/tcp/127.0.0.1/${GAME_PORT}) >/dev/null 2>&1 && exit 0
fi
exit 1
