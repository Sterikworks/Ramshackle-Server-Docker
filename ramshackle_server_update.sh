#!/usr/bin/env bash
# Dedicated server installer/updater for Ramshackle (Steam AppID 4021040, Depot 4021043)
# Everything (steamcmd + downloaded content) stays in this container's bind mounts.
set -euo pipefail

### --- Config / Env ---
BASE_DIR="/srv/ramshackle"
APP_ID=${APP_ID:-4021040}
DEPOT_ID=${DEPOT_ID:-4021043}
PLATFORM=${PLATFORM:-linux}
BITNESS=${BITNESS:-64}
INSTALL_DIR="${INSTALL_DIR:-${BASE_DIR}/server}"
STEAMCMD_DIR="${STEAMCMD_DIR:-${BASE_DIR}/steamcmd}"

STEAM_USER="${STEAM_USER:-anonymous}"
STEAM_PASS="${STEAM_PASS:-}"
STEAM_GUARD="${STEAM_GUARD:-}"

BRANCH="${BRANCH:-development}"
BRANCH_PASSWORD="${BRANCH_PASSWORD:-}"

MANIFEST_ID="${MANIFEST_ID:-}"
RETRIES=${RETRIES:-3}
RETRY_SLEEP=${RETRY_SLEEP:-10}

### --- Prereqs ---
mkdir -p "${STEAMCMD_DIR}" "${INSTALL_DIR}"

# Install steamcmd locally if missing
if [ ! -x "${STEAMCMD_DIR}/steamcmd.sh" ]; then
  echo "[*] Installing steamcmd into ${STEAMCMD_DIR}..."
  (
    cd "${STEAMCMD_DIR}"
    curl -fsSL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" -o steamcmd_linux.tar.gz
    tar -xzf steamcmd_linux.tar.gz
    rm -f steamcmd_linux.tar.gz
  )
fi

### --- Helpers ---
login_fragment() {
  if [ "${STEAM_USER}" = "anonymous" ]; then
    printf '+login anonymous'
  elif [ -n "${STEAM_GUARD}" ]; then
    printf '+login %s %s %s' "${STEAM_USER}" "${STEAM_PASS}" "${STEAM_GUARD}"
  else
    printf '+login %s %s' "${STEAM_USER}" "${STEAM_PASS}"
  fi
}

beta_fragment() {
  if [ -n "${BRANCH}" ] && [ "${BRANCH}" != "public" ]; then
    if [ -n "${BRANCH_PASSWORD}" ]; then
      printf -- '-beta %s -betapassword %s' "${BRANCH}" "${BRANCH_PASSWORD}"
    else
      printf -- '-beta %s' "${BRANCH}"
    fi
  fi
}

steamcmd_base() {
  printf '%s '     "+@ShutdownOnFailedCommand 1"     "+@NoPromptForPassword 1"     "+force_install_dir ${INSTALL_DIR}"     "+@sSteamCmdForcePlatformType ${PLATFORM}"     "+@sSteamCmdForcePlatformBitness ${BITNESS}"
}

retry() {
  local tries=0
  until "$@"; do
    tries=$((tries+1))
    if [ "${tries}" -ge "${RETRIES}" ]; then
      echo "[!] Command failed after ${RETRIES} attempts."
      return 1
    fi
    echo "[!] Attempt ${tries}/${RETRIES} failed. Retrying in ${RETRY_SLEEP}s..."
    sleep "${RETRY_SLEEP}"
  done
}

app_update_latest() {
  echo "[*] Updating APP ${APP_ID} on branch '${BRANCH:-public}' into ${INSTALL_DIR}"
  "${STEAMCMD_DIR}/steamcmd.sh"     $(steamcmd_base)     $(login_fragment)     +app_update "${APP_ID}" $(beta_fragment) validate     +quit
}

download_specific_manifest() {
  echo "[*] Downloading DEPOT ${DEPOT_ID} manifest ${MANIFEST_ID} (branch '${BRANCH:-public}') into ${INSTALL_DIR}"
  local tmp_out="${STEAMCMD_DIR}/depot_download"
  rm -rf "${tmp_out}"
  mkdir -p "${tmp_out}"

  "${STEAMCMD_DIR}/steamcmd.sh"     "+@ShutdownOnFailedCommand 1" "+@NoPromptForPassword 1"     "+@sSteamCmdForcePlatformType ${PLATFORM}" "+@sSteamCmdForcePlatformBitness ${BITNESS}"     $(login_fragment)     +app_info_update 1     +download_depot "${APP_ID}" "${DEPOT_ID}" "${MANIFEST_ID}"     +quit

  local depot_path
  depot_path="$(find "${STEAMCMD_DIR}" -type d -path "*/content/app_${APP_ID}/depot_${DEPOT_ID}" -print -quit || true)"
  if [ -z "${depot_path}" ]; then
    echo "[!] Could not locate downloaded depot content."
    return 1
  fi

  echo "[*] Syncing depot to ${INSTALL_DIR}..."
  mkdir -p "${INSTALL_DIR}"
  rsync -a --delete "${depot_path}/" "${INSTALL_DIR}/"
}

# Optional lightweight cache cleanup
rm -rf "${STEAMCMD_DIR}/appcache" 2>/dev/null || true

if [ -n "${MANIFEST_ID}" ]; then
  retry download_specific_manifest
else
  retry app_update_latest
fi

echo "[ ^|^s] Server files updated in: ${INSTALL_DIR}"
