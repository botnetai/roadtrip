#!/bin/bash

# Start both the web server and agent worker
echo "🚀 Starting web server and agent worker..."

# Start agent worker in background using virtual environment
/opt/venv/bin/python agent.py &
AGENT_PID=$!
echo "✅ Agent worker started (PID: $AGENT_PID)"

# Start web server in foreground
echo "✅ Starting web server..."
npm start
