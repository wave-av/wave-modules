#!/bin/bash
# WAVE Module: wave-companion — Bitfocus Companion Integration
set -euo pipefail

MODULE_DIR="/opt/wave/modules/wave-companion"
echo "[wave-companion] Installing..."

apt-get update -qq
apt-get install -y -qq curl jq

mkdir -p "$MODULE_DIR/bin"
cp "$(dirname "$0")/module.yaml" "$MODULE_DIR/"

cat > "$MODULE_DIR/config.yaml" << 'CONFIG'
companion_host: "127.0.0.1"
companion_port: 8000
auto_discover: true
CONFIG

# Companion API client
cat > "$MODULE_DIR/bin/companion-client.sh" << 'CLIENT'
#!/bin/bash
# WAVE Companion API Client
# Wraps Bitfocus Companion REST + WebSocket API
source /opt/wave/modules/wave-companion/config.env 2>/dev/null

HOST="${COMPANION_HOST:-127.0.0.1}"
PORT="${COMPANION_PORT:-8000}"
BASE="http://${HOST}:${PORT}"

case "${1:-help}" in
    trigger)
        PAGE="${2:?Usage: companion-client.sh trigger <page> <button>}"
        BUTTON="${3:?Usage: companion-client.sh trigger <page> <button>}"
        curl -s -X POST "${BASE}/api/location/${PAGE}/${BUTTON}/press" | jq .
        ;;
    release)
        PAGE="${2:?}"
        BUTTON="${3:?}"
        curl -s -X POST "${BASE}/api/location/${PAGE}/${BUTTON}/release" | jq .
        ;;
    pages)
        curl -s "${BASE}/api/buttons" | jq '.[] | {page: .page, button: .button, text: .text}' 2>/dev/null || echo "Cannot reach Companion at ${BASE}"
        ;;
    status)
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${BASE}/api/buttons" 2>/dev/null || echo "000")
        if [ "$HTTP_CODE" = "200" ]; then
            echo "connected"
            BUTTON_COUNT=$(curl -s "${BASE}/api/buttons" | jq 'length' 2>/dev/null || echo "?")
            echo "buttons: $BUTTON_COUNT"
        else
            echo "disconnected (HTTP $HTTP_CODE)"
        fi
        ;;
    help|*)
        echo "WAVE Companion Client"
        echo "  trigger <page> <button>  — Press button"
        echo "  release <page> <button>  — Release button"
        echo "  pages                    — List all pages/buttons"
        echo "  status                   — Check connection"
        ;;
esac
CLIENT
chmod +x "$MODULE_DIR/bin/companion-client.sh"
ln -sf "$MODULE_DIR/bin/companion-client.sh" /usr/local/bin/wave-companion

# Health check daemon
cat > "$MODULE_DIR/bin/health-daemon.sh" << 'HEALTH'
#!/bin/bash
source /opt/wave/modules/wave-companion/config.env 2>/dev/null
HOST="${COMPANION_HOST:-127.0.0.1}"
PORT="${COMPANION_PORT:-8000}"
METRICS_FILE="/opt/wave/modules/wave-companion/metrics.json"

while true; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://${HOST}:${PORT}/api/buttons" 2>/dev/null || echo "000")
    CONNECTED=$( [ "$HTTP_CODE" = "200" ] && echo "true" || echo "false" )
    cat > "$METRICS_FILE" << METRICS
{"companion_connected": $CONNECTED, "check_time": "$(date -Iseconds)", "http_code": $HTTP_CODE}
METRICS
    sleep 15
done
HEALTH
chmod +x "$MODULE_DIR/bin/health-daemon.sh"

cat > /etc/systemd/system/wave-companion.service << SERVICE
[Unit]
Description=WAVE Companion Integration Module
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/opt/wave/modules/wave-companion/bin/health-daemon.sh
Restart=always
RestartSec=10
EnvironmentFile=-/opt/wave/modules/wave-companion/config.env

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
echo "[wave-companion] Installed."
echo "  CLI: wave-companion trigger 1 1"
echo "  CLI: wave-companion status"
