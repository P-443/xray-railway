#!/bin/bash
PORT=${PORT:-8080}
sed -i "s/\"port\": 8080/\"port\": $PORT/" /etc/xray/config.json
exec /usr/local/bin/xray run -c /etc/xray/config.json
