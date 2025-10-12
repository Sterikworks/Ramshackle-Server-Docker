# Ramshackle Dedicated Server - Docker

Docker container for running a Ramshackle dedicated server with automatic updates from Steam.

## Features

- Automatic server installation and updates via SteamCMD
- Automatic injection of required `-scenario:XXX` flag
- Persistent data volumes for server files and saves
- Configurable Steam credentials and branch selection
- Non-root user execution for security
- Health checks and automatic restart on failure
- Support for both public and development branches

## Quick Start

### 1. Configure

Edit `docker-compose.yml` and set your values in the `environment:` section:

```yaml
environment:
  - STEAM_USER=mountainousbuilder       # your Steam username
  - STEAM_PASS=your_password_here       # your Steam password
  - SCENARIO=MyWorld                    # REQUIRED: change this to your world name!
```

### 2. Build and Run

```bash
# Build the image
docker-compose build

# Start the server
docker-compose up -d

# View logs
docker-compose logs -f
```

### 3. First Time Setup

The container will:
1. Download SteamCMD
2. Download/update the Ramshackle server files
3. Automatically inject the `-scenario:MyWorld` flag into `start_dedicated_server.sh`
4. Start the server

## Configuration

All settings are in the `environment:` section of `docker-compose.yml`. Just edit the file and restart the container.

### Configuration Options

| Variable | Default | Description |
|----------|---------|-------------|
| `STEAM_USER` | anonymous | Steam username |
| `STEAM_PASS` | - | Steam password |
| `STEAM_GUARD` | - | Steam Guard code (if enabled) |
| `SCENARIO` | **REQUIRED** | World/scenario name for `-scenario:XXX` flag |
| `BRANCH` | development | Steam branch (public/development) |
| `BRANCH_PASSWORD` | - | Password for protected branches |
| `MANIFEST_ID` | - | Pin to specific manifest version |
| `EXTRA_ARGS` | - | Additional server launch arguments |
| `PUID` | 1000 | User ID for file ownership |
| `PGID` | 1000 | Group ID for file ownership |

### Volumes

```yaml
volumes:
  - ./data/server:/srv/ramshackle/server       # Server binaries and files
  - ./data/steamcmd:/srv/ramshackle/steamcmd   # SteamCMD cache
  - ./data/saves:/home/steam/.config/Mountainous Development/REMProject  # Game saves and config
```

All server data persists in `./data/` on your host machine:
- `./data/server/` - Server installation files
- `./data/steamcmd/` - Steam download cache
- `./data/saves/` - **Your world saves and game configuration**

### Ports

Update `docker-compose.yml` with the actual game ports. Example:

```yaml
ports:
  - "7777:7777/udp"   # Game port
  - "27015:27015/udp" # Query port
```

## Usage

### Start/Stop Server

```bash
# Start
docker-compose up -d

# Stop
docker-compose down

# Restart
docker-compose restart
```

### View Logs

```bash
# Follow logs
docker-compose logs -f

# Last 100 lines
docker-compose logs --tail=100
```

### Update Server

The server automatically updates on each restart. To force an update:

```bash
docker-compose restart
```

### Change Scenario/World

Edit `docker-compose.yml` and change the `SCENARIO` variable, then restart:

```yaml
- SCENARIO=MyNewWorld
```

```bash
docker-compose restart
```

### Force Scenario Replacement

To replace an existing `-scenario:` flag in the start script, edit `docker-compose.yml`:

```yaml
- FORCE_SCENARIO=1
```

## Advanced

### Using a Specific Manifest

Pin to a specific version by editing `docker-compose.yml`:

```yaml
- MANIFEST_ID=1234567890123456789
```

### User/Group IDs

Match your host user to avoid permission issues. Edit `docker-compose.yml`:

```bash
# Get your UID/GID
id

# Set in docker-compose.yml
- PUID=1000
- PGID=1000
```

## Troubleshooting

### Server won't start

1. Check logs: `docker-compose logs -f`
2. Verify `SCENARIO` is set in `docker-compose.yml`
3. Ensure Steam credentials are correct
4. Check that ports aren't already in use

### Permission denied errors

Set `PUID` and `PGID` in `docker-compose.yml` to match your host user:

```bash
id  # Shows your UID and GID
```

### Steam Guard issues

When using Steam Guard:
1. Start the container: `docker-compose up`
2. Wait for Steam Guard prompt in logs
3. Stop the container
4. Edit `docker-compose.yml` and set `STEAM_GUARD=XXXXX` with your code
5. Restart within a few minutes: `docker-compose up -d`

### Server crashes after update

If a game update breaks your server:
1. Find a working manifest ID from SteamDB
2. Set `MANIFEST_ID=...` in `docker-compose.yml`
3. Restart: `docker-compose restart`

## Files

- `Dockerfile` - Container image definition
- `docker-compose.yml` - Service configuration (edit this to configure your server)
- `entrypoint.sh` - Server startup script
- `ramshackle_server_update.sh` - SteamCMD update script
- `healthcheck.sh` - Container health check

## Notes

- First launch downloads ~several GB, be patient
- Server files persist in `./data/server/`
- **World saves are in `./data/saves/`** - backup this folder regularly!
- Container runs as non-root user `steam` for security
- Health checks monitor the server process

## Support

For issues with:
- **This Docker setup**: Open an issue in this repo
- **The game itself**: Check Ramshackle community/forums
- **SteamCMD**: See Valve's developer documentation
