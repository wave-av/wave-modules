#!/bin/bash
# WAVE Module: wave-srt-in — Install Script
set -euo pipefail

MODULE_DIR="/opt/wave/modules/wave-srt-in"
CONFIG_DIR="/opt/wave/config"

echo "[wave-srt-in] Installing..."

# Install GStreamer SRT dependencies
apt-get update -qq
apt-get install -y -qq \
    gstreamer1.0-tools \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly

# Create module directory
mkdir -p "$MODULE_DIR"
cp "$(dirname "$0")/module.yaml" "$MODULE_DIR/"

# Generate default config
cat > "$MODULE_DIR/config.yaml" << 'CONFIG'
# WAVE SRT Input Module Configuration
port: 9000
mode: listener
passphrase: ""
latency: 200
caller_address: ""
output: hdmi    # hdmi, pipeline, or both
CONFIG

# Create GStreamer pipeline script
cat > "$MODULE_DIR/start-pipeline.sh" << 'PIPELINE'
#!/bin/bash
# WAVE SRT Input GStreamer Pipeline
source /opt/wave/modules/wave-srt-in/config.env 2>/dev/null

PORT="${SRT_PORT:-9000}"
MODE="${SRT_MODE:-listener}"
PASSPHRASE="${SRT_PASSPHRASE:-}"
LATENCY="${SRT_LATENCY:-200}"
OUTPUT="${SRT_OUTPUT:-hdmi}"
CALLER_ADDR="${SRT_CALLER_ADDRESS:-}"

# Build SRT URI
if [ "$MODE" = "caller" ] && [ -n "$CALLER_ADDR" ]; then
    SRT_URI="srt://${CALLER_ADDR}:${PORT}?mode=caller"
else
    SRT_URI="srt://0.0.0.0:${PORT}?mode=${MODE}"
fi

if [ -n "$PASSPHRASE" ]; then
    SRT_URI="${SRT_URI}&passphrase=${PASSPHRASE}"
fi

SRT_URI="${SRT_URI}&latency=${LATENCY}"

echo "[wave-srt-in] Starting SRT pipeline"
echo "  URI: $SRT_URI"
echo "  Output: $OUTPUT"

# Detect hardware decoder
HW_DECODER="avdec_h264"
if [ -e /dev/video-dec0 ] || [ -e /dev/rkvdec ]; then
    # RK3328 hardware decoder
    HW_DECODER="v4l2slh264dec"
    echo "  Decoder: Hardware (V4L2)"
elif gst-inspect-1.0 omxh264dec &>/dev/null; then
    HW_DECODER="omxh264dec"
    echo "  Decoder: Hardware (OMX)"
else
    echo "  Decoder: Software (avdec)"
fi

case "$OUTPUT" in
    hdmi)
        # SRT → Decode → HDMI output via DRM/KMS
        gst-launch-1.0 -e \
            srtsrc uri="$SRT_URI" \
            ! tsdemux \
            ! h264parse \
            ! "$HW_DECODER" \
            ! videoconvert \
            ! kmssink
        ;;
    pipeline)
        # SRT → Decode → appsink (for other modules to consume)
        gst-launch-1.0 -e \
            srtsrc uri="$SRT_URI" \
            ! tsdemux \
            ! h264parse \
            ! "$HW_DECODER" \
            ! videoconvert \
            ! shmsink socket-path=/tmp/wave-video-bus wait-for-connection=false
        ;;
    both)
        # SRT → Decode → tee → HDMI + shared memory
        gst-launch-1.0 -e \
            srtsrc uri="$SRT_URI" \
            ! tsdemux \
            ! h264parse \
            ! "$HW_DECODER" \
            ! videoconvert \
            ! tee name=t \
            t. ! queue ! kmssink \
            t. ! queue ! shmsink socket-path=/tmp/wave-video-bus wait-for-connection=false
        ;;
esac
PIPELINE
chmod +x "$MODULE_DIR/start-pipeline.sh"

# Create systemd service
cat > /etc/systemd/system/wave-srt-in.service << SERVICE
[Unit]
Description=WAVE SRT Input Module
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/opt/wave/modules/wave-srt-in/start-pipeline.sh
Restart=always
RestartSec=5
Environment=HOME=/root
EnvironmentFile=-/opt/wave/modules/wave-srt-in/config.env

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
echo "[wave-srt-in] Installed. Start with: systemctl start wave-srt-in"
