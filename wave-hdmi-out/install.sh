#!/bin/bash
# WAVE Module: wave-hdmi-out — Install Script
set -euo pipefail

MODULE_DIR="/opt/wave/modules/wave-hdmi-out"

echo "[wave-hdmi-out] Installing..."

apt-get update -qq
apt-get install -y -qq \
    gstreamer1.0-tools \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    libdrm-dev

mkdir -p "$MODULE_DIR"
cp "$(dirname "$0")/module.yaml" "$MODULE_DIR/"

cat > "$MODULE_DIR/config.yaml" << 'CONFIG'
resolution: auto
refresh_rate: 60
audio: passthrough
input_source: shm    # shm (from other modules) or test
CONFIG

# HDMI output script
cat > "$MODULE_DIR/start-output.sh" << 'OUTPUT'
#!/bin/bash
source /opt/wave/modules/wave-hdmi-out/config.env 2>/dev/null

INPUT="${HDMI_INPUT:-shm}"
RESOLUTION="${HDMI_RESOLUTION:-auto}"

echo "[wave-hdmi-out] Starting HDMI output"
echo "  Input: $INPUT"
echo "  Resolution: $RESOLUTION"

# Detect DRM device
DRM_DEV=""
for dev in /dev/dri/card*; do
    if [ -e "$dev" ]; then
        DRM_DEV="$dev"
        break
    fi
done

if [ -z "$DRM_DEV" ]; then
    echo "  ERROR: No DRM device found"
    exit 1
fi
echo "  DRM: $DRM_DEV"

# Get EDID info
if command -v modetest &>/dev/null; then
    CONNECTED=$(modetest -c 2>/dev/null | grep "connected" | head -1 || echo "unknown")
    echo "  Display: $CONNECTED"
fi

case "$INPUT" in
    shm)
        # Read from shared memory (written by video input modules)
        gst-launch-1.0 -e \
            shmsrc socket-path=/tmp/wave-video-bus is-live=true \
            ! video/x-raw,format=I420 \
            ! videoconvert \
            ! kmssink
        ;;
    test)
        # Test pattern for verification
        gst-launch-1.0 -e \
            videotestsrc pattern=smpte \
            ! video/x-raw,width=1920,height=1080,framerate=60/1 \
            ! kmssink
        ;;
esac
OUTPUT
chmod +x "$MODULE_DIR/start-output.sh"

cat > /etc/systemd/system/wave-hdmi-out.service << SERVICE
[Unit]
Description=WAVE HDMI Output Module
After=network.target

[Service]
Type=simple
ExecStart=/opt/wave/modules/wave-hdmi-out/start-output.sh
Restart=always
RestartSec=5
EnvironmentFile=-/opt/wave/modules/wave-hdmi-out/config.env

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
echo "[wave-hdmi-out] Installed. Start with: systemctl start wave-hdmi-out"
