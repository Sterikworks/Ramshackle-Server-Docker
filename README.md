# THIS DOESNT WORK YET

## Healthcheck note

The compose healthcheck was intentionally made conservative to avoid repeated restarts during startup. Frequent restarts can trigger repeated steamcmd logins which may lead to login throttling or account lockouts.

If you prefer to disable the healthcheck entirely, remove the `healthcheck` block in `docker-compose.yml` or set it to `none`.

To tune behavior, adjust `interval`, `timeout`, and `retries` in `docker-compose.yml`.

## Ports added

This project exposes the following additional ports for the game lobby and battle rooms:

- Lobby: 4999 (UDP and TCP)
- Battle rooms: 5000–5007 (UDP and TCP)

If your server config uses a different number of battle rooms, update the ports in `docker-compose.yml` accordingly.
