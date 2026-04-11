#!/bin/bash

if curl -s http://localhost:3001 > /dev/null 2>&1; then
    echo '{"result":{"version":"0","message":"The Canary web interface is ready","value":null,"variant":"success"}}'
    exit 0
else
    echo '{"result":{"version":"0","message":"The Canary web interface is not ready","value":null,"variant":"loading"}}'
    exit 0
fi
