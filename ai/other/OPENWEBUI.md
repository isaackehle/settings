# OpenWebUI Deployment Guide

## Overview

OpenWebUI provides a unified web interface for interacting with local Ollama instances across the fleet. It supports:

- Multiple Ollama backends (local + remote)
- Chat, RAG, and document Q&A
- Model management and switching
- Multi-user access

## Current Deployment Status

| Machine        | Hardware            | Ollama | OpenWebUI | URL                          | Status |
| -------------- | ------------------- | ------ | --------- | ---------------------------- | ------ |
| **discovery**  | MacBook M5 Max 64GB | ✓      | ✓         | http://localhost:8080        | Active |
| **ds9**        | Mac mini M2 16GB    | ✓      | ✓         | http://ds9.local:8080        | Active |
| **enterprise** | MacBook M1 16GB     | ✓      | ✓         | http://enterprise.local:8080 | Active |

## Deployment Scripts

Two deployment scripts are available in `ai/other/`:

- `openwebui-deploy-ds9.sh` - For ds9 (Mac mini M2 16GB)
- `openwebui-deploy-enterprise.sh` - For enterprise (MacBook M1 16GB)

Both scripts:

1. Check for Docker availability (install Colima if missing)
2. Start Docker daemon if not running
3. Pull the latest OpenWebUI image
4. Create and start the container with proper networking
5. Wait for health check

### Usage

```bash
# On ds9
bash ~/code/isaackehle/settings/ai/other/openwebui-deploy-ds9.sh

# On enterprise
bash ~/code/isaackehle/settings/ai/other/openwebui-deploy-enterprise.sh
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ OpenWebUI (port 8080)                                        │
│  - Web interface for all Ollama interactions                │
│  - Connects to host.docker.internal:11434                   │
│  - Persistent data in Docker volume: openwebui              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ Ollama (port 11434)                                          │
│  - Local model inference                                      │
│  - REST API for model management                             │
│  - Models stored in ~/.ollama/models                         │
└─────────────────────────────────────────────────────────────┘
```

## Container Configuration

- **Image**: `ghcr.io/open-webui/open-webui:main`
- **Container name**: `openwebui`
- **Port mapping**: `8080:8080`
- **Volume**: `openwebui:/app/backend/data` (persistent storage)
- **Host networking**: `--add-host=host.docker.internal:host-gateway`
- **Restart policy**: `unless-stopped`

## First-Time Setup

After deployment:

1. **Access the UI**: Open `http://localhost:8080` (or `http://<machine>.local:8080`)
2. **Create admin account**: First user becomes admin
3. **Configure Ollama connection**:
   - Go to: Settings → Admin Settings → Connections
   - Add Ollama API: `http://host.docker.internal:11434`
   - Click "Test" to verify connection
4. **Verify models**: Models should appear in the model selector

## Management Commands

```bash
# Start OpenWebUI
docker start openwebui

# Stop OpenWebUI
docker stop openwebui

# View logs
docker logs -f openwebui

# Check status
docker ps | grep openwebui

# Remove and recreate
docker rm -f openwebui
# Then run deployment script again

# Update to latest image
docker pull ghcr.io/open-webui/open-webui:main
docker rm -f openwebui
# Then run deployment script again
```

## Troubleshooting

### OpenWebUI can't connect to Ollama

**Symptom**: "Failed to connect to Ollama" error in UI

**Solution**:

```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# Check Docker networking
docker exec openwebui ping host.docker.internal

# Restart Ollama
brew services restart ollama

# Restart OpenWebUI
docker restart openwebui
```

### Port 8080 already in use

**Symptom**: Error binding to port 8080

**Solution**:

```bash
# Check what's using port 8080
lsof -i :8080

# Change port in deployment script
# Edit PORT=8081 in the script, then re-run

# Or stop the conflicting service
sudo launchctl stop <service-name>
```

### Docker daemon not running

**Symptom**: "Cannot connect to Docker daemon"

**Solution**:

```bash
# Start Colima
colima start --cpu 2 --memory 4

# Or start Docker Desktop
open -a Docker
```

## Network Access

### Local network access

OpenWebUI is accessible from other machines on the local network:

- **ds9**: `http://ds9.local:8080`
- **enterprise**: `http://enterprise.local:8080`
- **discovery**: `http://discovery.local:8080`

### Tailscale access (if configured)

If machines are on the same Tailscale network:

- **ds9**: `http://<ds9-tailscale-ip>:8080`
- **enterprise**: `http://<enterprise-tailscale-ip>:8080`
- **discovery**: `http://<discovery-tailscale-ip>:8080`

## Resource Usage

Typical resource usage on a 16GB machine:

- **Docker container**: ~500MB RAM
- **Ollama** (idle): ~200MB RAM
- **Ollama** (active, 7B model): ~6GB RAM
- **Ollama** (active, 32B model): ~20GB RAM

OpenWebUI itself is lightweight. The main resource consumer is Ollama when running inference.

## Comparison with Alternatives

### OpenWebUI vs Kilo Code

- **OpenWebUI**: Web-based, multi-user, RAG support, persistent conversations
- **Kilo Code**: VSCode extension, single-user, focused on code editing
- **Use both**: OpenWebUI for exploration and Q&A, Kilo for development

### OpenWebUI vs Continue.dev

- **OpenWebUI**: Web interface, broader use cases, RAG
- **Continue.dev**: IDE-integrated, focused on code completion
- **Use both**: Continue for autocomplete, OpenWebUI for chat

## Maintenance

### Regular updates

```bash
# Weekly: Pull latest image
docker pull ghcr.io/open-webui/open-webui:main

# Monthly: Recreate container with latest image
docker rm -f openwebui
bash ~/code/isaackehle/settings/ai/other/openwebui-deploy-ds9.sh
```

### Backup configuration

```bash
# Export OpenWebUI data
docker exec openwebui tar czf /tmp/openwebui-backup.tar.gz /app/backend/data
docker cp openwebui:/tmp/openwebui-backup.tar.gz ~/openwebui-backup-$(date +%Y%m%d).tar.gz

# Restore from backup
docker cp ~/openwebui-backup-20260618.tar.gz openwebui:/tmp/openwebui-backup.tar.gz
docker exec openwebui tar xzf /tmp/openwebui-backup.tar.gz -C /
docker restart openwebui
```

## Related Documentation

- [Ollama Setup](../../runtimes/ollama.sh)
- [llama.cpp Router](../../router/models.ini)
- [Model Profiles](../../profiles/)
- [AI Tools Overview](../../AI_TOOLS.md)
