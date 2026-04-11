#!/bin/bash

if curl -s http://localhost:3000/api/block-headers/current > /dev/null 2>&1; then
    echo '{"result":{"version":"0","message":"The Canary API is responding","value":null,"variant":"success"}}'
    exit 0
else
    echo '{"result":{"version":"0","message":"The Canary API is not responding","value":null,"variant":"loading"}}'
    exit 0
fi
