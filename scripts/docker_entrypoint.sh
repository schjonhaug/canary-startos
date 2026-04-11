#!/bin/bash
set -e

echo "Starting Canary Bitcoin Wallet Manager for StartOS..."

CANARY_DATA_DIR="${CANARY_DATA_DIR:-/app/data}"
CANARY_BIND_ADDRESS="${CANARY_BIND_ADDRESS:-0.0.0.0:3000}"

CANARY_NETWORK="mainnet"

# Read electrum server selection from Start9 config
ELECTRUM_SERVER="electrs"
CONFIG_FILE="${CANARY_DATA_DIR}/start9/config.yaml"
if [ -f "$CONFIG_FILE" ]; then
    ELECTRUM_SERVER=$(yq e '.electrum-server.type' "$CONFIG_FILE" 2>/dev/null || echo "electrs")
fi

if [ "$ELECTRUM_SERVER" = "fulcrum" ]; then
    CANARY_ELECTRUM_URL="tcp://fulcrum.embassy:50001"
    echo "Using Fulcrum server"
else
    CANARY_ELECTRUM_URL="tcp://electrs.embassy:50001"
    echo "Using Electrs server"
fi

mkdir -p "${CANARY_DATA_DIR}/mainnet"

export CANARY_MODE=self-hosted
export CANARY_DATA_DIR
export CANARY_NETWORK
export CANARY_ELECTRUM_URL
export CANARY_BIND_ADDRESS
export CANARY_SYNC_INTERVAL=60

export NEXT_PUBLIC_CANARY_MODE=self-hosted
export NEXT_PUBLIC_API_URL="http://localhost:3000"
export NODE_ENV=production
export PORT=3001
export HOSTNAME=0.0.0.0

echo "========================================"
echo "Canary Configuration:"
echo "  Mode: self-hosted (StartOS)"
echo "  Network: ${CANARY_NETWORK}"
echo "  Electrum Server: ${ELECTRUM_SERVER}"
echo "  Electrum URL: ${CANARY_ELECTRUM_URL}"
echo "  Backend: ${CANARY_BIND_ADDRESS}"
echo "  Data directory: ${CANARY_DATA_DIR}"
echo "  Sync interval: ${CANARY_SYNC_INTERVAL}s"
echo "========================================"

BACKEND_PID=""
FRONTEND_PID=""

shutdown() {
    echo "Shutting down Canary..."
    [ -n "$FRONTEND_PID" ] && kill $FRONTEND_PID 2>/dev/null || true
    [ -n "$BACKEND_PID" ] && kill $BACKEND_PID 2>/dev/null || true
    exit 0
}

trap shutdown SIGTERM SIGINT

echo "Starting backend API server..."
cd /app/backend
./canary &
BACKEND_PID=$!

echo "Waiting for backend to be ready..."
for i in {1..60}; do
    if curl -s http://localhost:3000/api/block-headers/current > /dev/null 2>&1; then
        echo "Backend is ready!"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "Warning: Backend not responding after 60 seconds, continuing anyway..."
    fi
    sleep 1
done

echo "Starting frontend server..."
cd /app/frontend
node server.js &
FRONTEND_PID=$!

echo "========================================"
echo "Canary is running!"
echo "  Backend API: http://localhost:3000"
echo "  Frontend UI: http://localhost:3001"
echo "========================================"

wait -n $BACKEND_PID $FRONTEND_PID
echo "A process exited unexpectedly, shutting down..."
shutdown
