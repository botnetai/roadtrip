# Splitting backend and agent into two Railway services

The repo can now run the Node backend and Python agent as independent Railway services. Use this runbook when handing off or recreating the split deployment.

## 0. Snapshot current Railway variables

Before touching anything, export the live env vars for both services so nothing gets lost:

```bash
railway service list
railway variables --service <existing-service-id> --json > node-vars.json
railway variables --service <python-service-id> --json > agent-vars.json
```

If you prefer the UI: Railway project → each service → **Variables** → **Download**. Store the JSON in a safe place so you can restore secrets if needed.

## 1. Service naming layout

1. In Railway UI go to each service → **Settings → Name**.
2. Rename the existing combined service to **Node** (this will become the API only service).
3. Create or clone a second service from the same repo and rename it **Python** (this runs only the agent worker).

Both services keep the repository root as the source, but each will use different start commands/config.

## 2. Node service (API)

- **Root directory**: `backend`
- **Build config**: `nixpacks.toml` (already in `backend/`)
- **Start command**: `npm start`
- **Env vars**:
  - Required: `LIVEKIT_URL`, `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`, `OPENAI_API_KEY`, `PERPLEXITY_API_KEY`, database creds (`DATABASE_URL`, etc.), Stripe/App Store secrets, anything the API already used.
  - Add `DISABLE_EMBEDDED_AGENT=1` so `backend/start.sh` skips booting the Python worker and simply launches the Node server (`npm start`).
- **Deploy timing**: Deploy only after the Python service is healthy, because `/health/agent` checks will fail otherwise.

## 3. Python service (Agent)

- **Root directory**: `backend`
- **Build config**: `backend/nixpacks-agent.toml`
- **Start command**: `bash start-agent.sh`
- **Required env vars**:
  - `LIVEKIT_URL`, `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`
  - `OPENAI_API_KEY`
  - `CARTESIA_API_KEY`
  - `ELEVENLABS_API_KEY`
- **Optional env vars**:
  - `LIVEKIT_AGENT_NAME` (defaults to `agent`)
  - Additional LLM keys (`ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, etc.)
  - `PERPLEXITY_API_KEY` if you want the agent’s web-search tool to work (the Node service still needs it too)
- **Log expectations** (from `agent.py`):
  - `Connecting to LiveKit Cloud...`
  - `📢 Using TTS plugin directly (does NOT count against LiveKit Inference limit)`
  - `   TTS provider: cartesia|elevenlabs`

These lines confirm LiveKit connectivity plus the TTS plugin selection that bypasses LiveKit inference quotas.

## 4. Deployment order

1. **Deploy Python service first**
   - Trigger deploy → tail logs.
   - Confirm the log lines above plus `🚀 Starting LiveKit agent worker...` (emitted by `start-agent.sh`).
2. **Deploy Node service**
   - Ensure `DISABLE_EMBEDDED_AGENT=1` is in Variables.
   - Confirm logs show normal API startup without Python supervisor chatter.

## 5. Verification checklist

1. Python logs should include the LiveKit connection + TTS provider lines. If missing, check secrets or `start-agent.sh`.
2. Hit the backend health endpoint once Node is up:
   ```bash
   curl -s https://<node-service-url>/health/agent | jq
   ```
   Expect `{"livekit_connected":true,...}`.
3. Start a voice session from the app:
   - Backend dispatches via `dispatchAgentToRoom`.
   - Agent (Python service) joins from Railway; watch LiveKit dashboard for participants.
4. If the session fails, note the LiveKit room name and inspect:
   - Railway Python logs for errors after the dispatch timestamp.
   - `/health/agent` output for `livekit_connected=false`.
   - LiveKit Cloud logs/participants for join failures.

## 6. Why the `DISABLE_EMBEDDED_AGENT` flag matters

`backend/start.sh` still supports the combined mode, but when `DISABLE_EMBEDDED_AGENT=1` it skips the supervisor loop and only runs `npm start`. That keeps the Node service lightweight while the dedicated Python service handles LiveKit jobs.

## 7. Troubleshooting tips

- Python deploy stuck at `libstdc++.so.6`: `start-agent.sh` already searches `/root/.nix-profile` and `/nix/store`. Make sure `nixpacks-agent.toml` stays in place.
- Missing TTS provider line: ensure `CARTESIA_API_KEY` (or ElevenLabs) is set; otherwise the agent will fall back to LiveKit Inference and log `📢 Using LiveKit Inference TTS...`.
- `/health/agent` failing: verify Python service is reachable and that both services share identical LiveKit credentials and (optionally) the same `LIVEKIT_AGENT_NAME`.
