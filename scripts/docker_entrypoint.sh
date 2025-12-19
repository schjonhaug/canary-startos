#!/bin/bash
set -e

echo "Starting Canary Bitcoin Wallet Manager for StartOS..."

# Configuration from environment (set by Start9)
CANARY_DATA_DIR="${CANARY_DATA_DIR:-/app/data}"
CANARY_BIND_ADDRESS="${CANARY_BIND_ADDRESS:-0.0.0.0:3000}"

# Read configuration from store.json if it exists
STORE_FILE="${CANARY_DATA_DIR}/store.json"
if [ -f "$STORE_FILE" ]; then
    echo "Reading configuration from store.json..."
    CANARY_NETWORK=$(node -e "console.log(require('$STORE_FILE').network || 'mainnet')" 2>/dev/null || echo "mainnet")
    ELECTRUM_SOURCE=$(node -e "console.log(require('$STORE_FILE').electrumSource || 'local')" 2>/dev/null || echo "local")
    EXTERNAL_ELECTRUM_URL=$(node -e "console.log(require('$STORE_FILE').externalElectrumUrl || '')" 2>/dev/null || echo "")
    ADMIN_NOTIFICATION_TOPIC=$(node -e "console.log(require('$STORE_FILE').adminNotificationTopic || '')" 2>/dev/null || echo "")
else
    echo "No store.json found, using defaults..."
    CANARY_NETWORK="mainnet"
    ELECTRUM_SOURCE="local"
    EXTERNAL_ELECTRUM_URL=""
    ADMIN_NOTIFICATION_TOPIC=""
fi

# Determine Electrum URL based on configuration
if [ "$ELECTRUM_SOURCE" = "local" ]; then
    # Use local Electrs (Start9 dependency)
    ELECTRS_HOST="electrs.embassy"
    ELECTRS_PORT="50001"
    CANARY_ELECTRUM_URL="tcp://${ELECTRS_HOST}:${ELECTRS_PORT}"
    echo "Using local Electrs server"
else
    # Use external Electrum server
    if [ -n "$EXTERNAL_ELECTRUM_URL" ]; then
        CANARY_ELECTRUM_URL="$EXTERNAL_ELECTRUM_URL"
    else
        CANARY_ELECTRUM_URL="ssl://electrum.blockstream.info:50002"
    fi
    echo "Using external Electrum server"
fi

# Ensure data directory exists with proper structure
mkdir -p "${CANARY_DATA_DIR}/mainnet"
mkdir -p "${CANARY_DATA_DIR}/testnet"
mkdir -p "${CANARY_DATA_DIR}/regtest"

# Export environment for backend
export CANARY_MODE=self-hosted
export CANARY_DATA_DIR
export CANARY_NETWORK
export CANARY_ELECTRUM_URL
export CANARY_BIND_ADDRESS
export CANARY_SYNC_INTERVAL=60  # Sync every 60 seconds (vs 300s default)

# Export admin notification topic if set
if [ -n "$ADMIN_NOTIFICATION_TOPIC" ]; then
    export CANARY_ADMIN_NOTIFICATION_TOPIC="$ADMIN_NOTIFICATION_TOPIC"
fi

# Export environment for frontend
export NEXT_PUBLIC_CANARY_MODE=self-hosted
export NEXT_PUBLIC_API_URL="http://localhost:3000"
export NODE_ENV=production
export PORT=3001
export HOSTNAME=0.0.0.0

echo "========================================"
echo "Canary Configuration:"
echo "  Mode: self-hosted (StartOS)"
echo "  Network: ${CANARY_NETWORK}"
echo "  Electrum Source: ${ELECTRUM_SOURCE}"
echo "  Electrum URL: ${CANARY_ELECTRUM_URL}"
echo "  Backend: ${CANARY_BIND_ADDRESS}"
echo "  Data directory: ${CANARY_DATA_DIR}"
echo "  Sync interval: ${CANARY_SYNC_INTERVAL}s"
if [ -n "$ADMIN_NOTIFICATION_TOPIC" ]; then
    echo "  Admin Notifications: ${ADMIN_NOTIFICATION_TOPIC}"
fi
echo "========================================"

# Start backend in background
echo "Starting backend API server..."
cd /app/backend
./canary &
BACKEND_PID=$!

# Wait for backend to be ready
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

# Start frontend
echo "Starting frontend server..."
cd /app/frontend
node server.js &
FRONTEND_PID=$!

echo "========================================"
echo "Canary is running!"
echo "  Backend API: http://localhost:3000"
echo "  Frontend UI: http://localhost:3001"
echo "========================================"

# Handle shutdown gracefully
shutdown() {
    echo "Shutting down Canary..."
    kill $FRONTEND_PID 2>/dev/null || true
    kill $BACKEND_PID 2>/dev/null || true
    exit 0
}

trap shutdown SIGTERM SIGINT

# Wait for any process to exit
wait -n $BACKEND_PID $FRONTEND_PID
EXIT_CODE=$?

echo "A process exited with code $EXIT_CODE, shutting down..."
shutdown
