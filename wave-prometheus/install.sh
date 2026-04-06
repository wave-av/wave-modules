#!/bin/bash
# WAVE Module: wave-prometheus — Metrics Exporter
set -euo pipefail

MODULE_DIR="/opt/wave/modules/wave-prometheus"
echo "[wave-prometheus] Installing..."

mkdir -p "$MODULE_DIR/bin"
cp "$(dirname "$0")/module.yaml" "$MODULE_DIR/"

# Download node_exporter for ARM64
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then
    NE_ARCH="arm64"
elif [ "$ARCH" = "x86_64" ]; then
    NE_ARCH="amd64"
else
    NE_ARCH="arm64"
fi

if ! command -v node_exporter &>/dev/null; then
    NE_VERSION="1.8.2"
    NE_URL="https://github.com/prometheus/node_exporter/releases/download/v${NE_VERSION}/node_exporter-${NE_VERSION}.linux-${NE_ARCH}.tar.gz"
    echo "  Downloading node_exporter v${NE_VERSION}..."
    curl -sL "$NE_URL" | tar xz -C /tmp/
    cp "/tmp/node_exporter-${NE_VERSION}.linux-${NE_ARCH}/node_exporter" "$MODULE_DIR/bin/"
    ln -sf "$MODULE_DIR/bin/node_exporter" /usr/local/bin/node_exporter
fi

# WAVE custom metrics collector
cat > "$MODULE_DIR/bin/wave-metrics.sh" << 'METRICS'
#!/bin/bash
# WAVE Custom Metrics Collector
# Outputs Prometheus text format on stdout

METRICS_DIR="/opt/wave/modules"

echo "# HELP wave_device_info WAVE device information"
echo "# TYPE wave_device_info gauge"
HOSTNAME=$(hostname)
VERSION=$(cat /opt/wave/config/device.yaml 2>/dev/null | grep firmware_version | awk '{print $2}' || echo "unknown")
echo "wave_device_info{hostname=\"${HOSTNAME}\",version=\"${VERSION}\"} 1"

echo "# HELP wave_cpu_temp_celsius CPU temperature"
echo "# TYPE wave_cpu_temp_celsius gauge"
TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0)
echo "wave_cpu_temp_celsius $(echo "scale=1; $TEMP/1000" | bc 2>/dev/null || echo 0)"

echo "# HELP wave_memory_used_bytes Memory used"
echo "# TYPE wave_memory_used_bytes gauge"
MEM_USED=$(free -b | awk 'NR==2{print $3}')
echo "wave_memory_used_bytes $MEM_USED"

echo "# HELP wave_disk_used_percent Root disk usage percent"
echo "# TYPE wave_disk_used_percent gauge"
DISK=$(df / | awk 'NR==2{print $5}' | tr -d '%')
echo "wave_disk_used_percent $DISK"

echo "# HELP wave_uptime_seconds Device uptime"
echo "# TYPE wave_uptime_seconds counter"
UPTIME=$(awk '{print int($1)}' /proc/uptime)
echo "wave_uptime_seconds $UPTIME"

echo "# HELP wave_modules_installed Number of installed modules"
echo "# TYPE wave_modules_installed gauge"
MODULES=$(ls -d /opt/wave/modules/wave-* 2>/dev/null | wc -l)
echo "wave_modules_installed $MODULES"

# Collect metrics from each installed module
for mod_metrics in /opt/wave/modules/*/metrics.json; do
    [ -f "$mod_metrics" ] || continue
    MOD_NAME=$(basename "$(dirname "$mod_metrics")")
    # Parse JSON metrics and output as Prometheus format
    if command -v jq &>/dev/null; then
        jq -r "to_entries[] | select(.value | type == \"number\") | \"wave_module_\(.key){module=\\\"${MOD_NAME}\\\"} \(.value)\"" "$mod_metrics" 2>/dev/null || true
    fi
done
METRICS
chmod +x "$MODULE_DIR/bin/wave-metrics.sh"

# Simple HTTP metrics server (no dependency needed)
cat > "$MODULE_DIR/bin/metrics-server.sh" << 'SERVER'
#!/bin/bash
PORT="${PROMETHEUS_PORT:-9100}"
WAVE_METRICS="/opt/wave/modules/wave-prometheus/bin/wave-metrics.sh"

echo "[wave-prometheus] Serving metrics on :${PORT}/metrics"

while true; do
    # Collect all metrics
    BODY=$( (node_exporter --web.listen-address=":0" --collector.disable-defaults --collector.cpu --collector.meminfo --collector.filesystem --collector.netdev --collector.loadavg 2>/dev/null & sleep 0.5; kill $! 2>/dev/null) || true)
    WAVE_BODY=$("$WAVE_METRICS" 2>/dev/null || true)
    FULL_BODY="${BODY}${WAVE_BODY}"
    CONTENT_LENGTH=${#FULL_BODY}

    # Serve via netcat
    echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: ${CONTENT_LENGTH}\r\n\r\n${FULL_BODY}" | nc -l -p "$PORT" -q 1 2>/dev/null || sleep 1
done
SERVER
chmod +x "$MODULE_DIR/bin/metrics-server.sh"

cat > /etc/systemd/system/wave-prometheus.service << SERVICE
[Unit]
Description=WAVE Prometheus Metrics Exporter
After=network.target

[Service]
Type=simple
ExecStart=/opt/wave/modules/wave-prometheus/bin/metrics-server.sh
Restart=always
RestartSec=10
Environment=PROMETHEUS_PORT=9100

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
echo "[wave-prometheus] Installed. Metrics at http://localhost:9100/metrics"
