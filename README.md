# Ramshackle Server Docker

A containerized Ramshackle server setup using Docker and SteamCMD for easy deployment and updates.

## Prerequisites

1. **Install Docker & Docker Compose**  
   Follow the [official Docker installation guide](https://docs.docker.com/get-docker/) for your Linux distribution.

2. **Git**  
   Most Linux distributions include `git` by default. If not, install it via your package manager.

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/Sterikworks/Ramshackle-Server-Docker.git
cd Ramshackle-Server-Docker
```

### 2. Configure Your Server

Edit `docker-compose.yml` and update the `environment` section:

- **`SCENARIO`** (required): Set this to your world/scenario name
- **`STEAM_USER`** / **`STEAM_PASS`**: Leave as `anonymous` (the app is publicly available on SteamCMD; only use credentials if you have a special server account)
- **`BRANCH`**: Use `public` or `development`
- **`EXTRA_ARGS`**: Add any additional server launch arguments

Example:
```yaml
environment:
  - SCENARIO=MyWorld
  - BRANCH=public
  - EXTRA_ARGS=-batchmode -nographics -debug -lobby -end
```

### 3. Build and Start

```bash
# Build the Docker image
docker compose build

# Start the server
docker compose up -d

# View logs
docker compose logs -f ramshackle

# bring down the Docker image (when you want to update from git, then you need to build)
```

### 4. Verify It's Running

Check that the server is running and Steam initialized properly:
```bash
docker compose logs ramshackle -f
```

You should **not** see this message. If you do, check the full logs for errors.

## Configuration Reference

| Variable | Purpose | Default |
|----------|---------|---------|
| `SCENARIO` | World/scenario name | `MyWorld` |
| `BRANCH` | Game branch (`public`, `development`) | `development` |
| `BRANCH_PASSWORD` | Password if branch requires it | Empty |
| `AUTO_UPDATE` | Auto-update server on container start | `true` |
| `EXTRA_ARGS` | Additional server launch flags | See compose file |
| `PUID` / `PGID` | Linux user/group IDs for file permissions | `1000` / `1000` |

## Ports

The server exposes:
- **Steam broadcast**: 4998 (UDP & TCP)
- **Lobby**: 4999 (UDP & TCP)
- **Battle rooms**: 5000–5007 (UDP & TCP)

Forward these ports on your firewall/router as needed.

## Stopping the Server

```bash
docker compose down
```

## Troubleshooting

**Server won't start:**
- Check logs: `docker compose logs ramshackle`
- Ensure `SCENARIO` is set correctly in `docker-compose.yml`

**Permission issues on volumes:**
- Update `PUID` and `PGID` in `docker-compose.yml` to match your user (run `id` to find them)
- I have no idea what these do its just setting it to 1000 made linux shut up.

