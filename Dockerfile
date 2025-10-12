# syntax=docker/dockerfile:1
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive     LANG=C.UTF-8     LC_ALL=C.UTF-8

# steamcmd & runtime deps
RUN apt-get update -y  && apt-get install -y --no-install-recommends       ca-certificates curl lib32gcc-s1 libssl3 rsync procps tini gosu  && rm -rf /var/lib/apt/lists/*

# Non-root user with configurable uid/gid
ARG PUID=1000
ARG PGID=1000
RUN groupadd -g ${PGID} steam && useradd -u ${PUID} -g ${PGID} -m -s /bin/bash steam

# Workdir layout
WORKDIR /srv/ramshackle
RUN mkdir -p /srv/ramshackle/server /srv/ramshackle/steamcmd

# Copy scripts
COPY ramshackle_server_update.sh /usr/local/bin/ramshackle_server_update.sh
COPY entrypoint.sh                /usr/local/bin/entrypoint.sh
COPY healthcheck.sh               /usr/local/bin/healthcheck.sh

RUN chmod +x /usr/local/bin/*.sh  && chown -R steam:steam /srv/ramshackle

# Default envs (can be overridden by compose)
ENV APP_ID=4021040 DEPOT_ID=4021043     PLATFORM=linux BITNESS=64     INSTALL_DIR=/srv/ramshackle/server     STEAMCMD_DIR=/srv/ramshackle/steamcmd     BRANCH=development BRANCH_PASSWORD=     MANIFEST_ID=     STEAM_USER=anonymous STEAM_PASS= STEAM_GUARD=     SCENARIO=MyWorld EXTRA_ARGS=

# Run as root to fix permissions, entrypoint will drop to steam user
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/local/bin/entrypoint.sh"]
