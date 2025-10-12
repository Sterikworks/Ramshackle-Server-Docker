#!/usr/bin/env bash
set -euo pipefail

# Fix permissions for volume mounts (runs as root, then drops to steam user)
PUID="${PUID:-1000}"
PGID="${PGID:-1000}"

echo "[*] Ensuring correct permissions for volumes..."
mkdir -p /srv/ramshackle/server /srv/ramshackle/steamcmd "/home/steam/.config/Mountainous Development/REMProject"
chown -R "${PUID}:${PGID}" /srv/ramshackle "/home/steam/.config"

# Drop to steam user and continue
if [ "$(id -u)" = "0" ]; then
  echo "[*] Dropping privileges to steam user (${PUID}:${PGID})..."
  exec gosu steam "$0" "$@"
fi

# Now running as steam user
export INSTALL_DIR="${INSTALL_DIR:-/srv/ramshackle/server}"
export STEAMCMD_DIR="${STEAMCMD_DIR:-/srv/ramshackle/steamcmd}"
export START_SCRIPT="${START_SCRIPT:-start_dedicated_server.sh}"
export SERVER_BIN="${SERVER_BIN:-}"   # Optional: direct path to server binary to bypass vendor script
export FORCE_SCENARIO="${FORCE_SCENARIO:-0}"
export SCENARIO="${SCENARIO:?set SCENARIO to your world name}"
export EXTRA_ARGS="${EXTRA_ARGS:-}"
export SOFT_RESTART="${SOFT_RESTART:-0}" # if the game supports in-proc restart

# 1) Update / install server files
/usr/local/bin/ramshackle_server_update.sh

cd "${INSTALL_DIR}"

# 2) If a direct binary is specified, prefer it.
if [[ -n "$SERVER_BIN" && -x "$SERVER_BIN" ]]; then
  echo "[*] Launching server binary directly: $SERVER_BIN"
  exec "$SERVER_BIN" -scenario:"${SCENARIO}" ${EXTRA_ARGS}
fi

# 3) Fallback to vendor start script
if [[ ! -f "$START_SCRIPT" ]]; then
  echo "[!] Cannot find $START_SCRIPT in $INSTALL_DIR" >&2
  ls -la
  exit 1
fi

# 4) Patch -scenario if missing, or replace if FORCE_SCENARIO=1
if grep -q -- "-scenario:" "$START_SCRIPT"; then
  if [[ "$FORCE_SCENARIO" == "1" ]]; then
    echo "[*] Replacing existing scenario with ${SCENARIO} in $START_SCRIPT"
    cp "$START_SCRIPT" "$START_SCRIPT.bak" || true
    sed -E -i "s/-scenario:([A-Za-z0-9._-]+)/-scenario:${SCENARIO}/g" "$START_SCRIPT"
  fi
else
  echo "[*] Injecting required scenario flag into $START_SCRIPT"
  cp "$START_SCRIPT" "$START_SCRIPT.bak" || true
  awk -v flag="-scenario:${SCENARIO}" '
    NF{last=NR} {lines[NR]=$0} END{
      for(i=1;i<=NR;i++){
        if(i==last){
          if(index(lines[i], flag)==0){ print lines[i]" "flag }
          else { print lines[i] }
        } else print lines[i]
      }
    }
  ' "$START_SCRIPT" > "$START_SCRIPT.tmp" && mv "$START_SCRIPT.tmp" "$START_SCRIPT"
fi

chmod +x "$START_SCRIPT"

# 5) Graceful signal handling: forward SIGTERM to child
_term(){
  echo "[*] Caught SIGTERM, forwarding to server..."
  pkill -TERM -P $$ || true
}
trap _term TERM INT

# 6) Launch
ulimit -n ${ULIMIT_NOFILE:-1048576} || true
mkdir -p "${LOG_DIR:-./logs}"

echo "[*] Starting server with scenario '${SCENARIO}'"
exec bash "$START_SCRIPT" ${EXTRA_ARGS}
