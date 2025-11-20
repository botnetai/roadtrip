# Railway Configuration Files

## Current Setup

The project now deploys **two Railway services** from the same GitHub repo:

1. **Node service** – API only (no embedded agent)
   - **Config file**: `railway-node.json`
   - **Root dir**: `backend`
   - **Start command**: `npm start` (root dir is already `backend`)
   - **Build plan**: `backend/nixpacks.toml`

2. **Python service** – Dedicated LiveKit agent worker
   - **Config file**: `railway-python.json`
   - **Root dir**: `backend`
   - **Start command**: `bash start-agent.sh` (root dir is already `backend`)
   - **Build plan**: `backend/nixpacks-agent.toml`

### Legacy combined service

`railway.json` is kept for reference/testing (it still launches the combined Node + agent stack via `bash start.sh`). New deployments should use the service-specific config files above.

## File Structure

```
roadtrip/
├── railway.json              ← Legacy combined config (unused in split setup)
├── railway-node.json         ← Node service config-as-code
├── railway-python.json       ← Python agent config-as-code
├── start.sh                  ← Wrapper (combined mode only)
└── backend/
    ├── start.sh              ← Combined-mode launcher
    ├── start-agent.sh        ← Python-only launcher
    ├── nixpacks.toml         ← Node build plan
    └── nixpacks-agent.toml   ← Python build plan
```

## Railway Dashboard Settings

### Node service
- **Config file**: `railway-node.json`
- **Root Directory**: `backend`
- **Nixpacks Config Path**: `backend/nixpacks.toml`
- **Start Command**: `npm start`
- **Env**: add `DISABLE_EMBEDDED_AGENT=1` plus LiveKit/OpenAI/DB secrets

### Python service
- **Config file**: `railway-python.json`
- **Root Directory**: `backend`
- **Nixpacks Config Path**: `backend/nixpacks-agent.toml`
- **Start Command**: `bash start-agent.sh`
- **Env**: LiveKit + OpenAI + Cartesia + ElevenLabs (+ optional LLM keys)

## Why This Structure?

- **Single source of truth**: Main service uses root-level configs
- **Clear separation**: Python-only service has its own configs in backend/
- **Works with CLI**: `railway up` from root works correctly
- **Works with GitHub**: Auto-deploy works correctly

## Removed Files

- ~~`backend/railway.json`~~ - superseded by `railway-node.json`
- ~~`backend/railway-agent.json`~~ - superseded by `railway-python.json`
