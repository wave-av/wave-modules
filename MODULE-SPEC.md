# WAVE Edge Module Specification

> Version 0.1.0 — Defines how modules are packaged, discovered, installed, and managed on WAVE edge devices.

## Module Manifest (module.yaml)

Every module is a directory containing a `module.yaml` manifest:

```yaml
# module.yaml
name: wave-srt-in
version: 0.3.0
description: Receive SRT streams and decode to local pipeline
category: video-input
protocol: srt

author: WAVE
license: MIT
homepage: https://github.com/wave-av/wave-modules/tree/main/wave-srt-in

# Hardware requirements
requires:
  network: true        # Needs ethernet/wifi
  gpu: false           # No GPU needed for receive
  min_ram_mb: 256      # Minimum RAM
  arch:                # Supported architectures
    - aarch64
    - x86_64

# Software dependencies
depends:
  packages:            # apt packages needed
    - gstreamer1.0-plugins-bad
    - libsrt1.5-openssl
  modules: []          # Other WAVE modules needed

# Conflicts with these modules (can't run simultaneously)
conflicts:
  - wave-srt-in-v2    # Can't have two SRT input modules

# GStreamer pipeline template
pipeline:
  type: gstreamer
  template: |
    srtsrc uri=srt://{{bind_address}}:{{port}}?mode={{mode}}&passphrase={{passphrase}} latency={{latency}}
    ! tsdemux
    ! h264parse
    ! {{decoder}}
    ! videoconvert
    ! appsink name=wave_video_out

# Configuration schema
config:
  port:
    type: integer
    default: 9000
    min: 1024
    max: 65535
    description: SRT listen port
  mode:
    type: string
    default: listener
    enum: [listener, caller, rendezvous]
    description: SRT connection mode
  passphrase:
    type: string
    default: ""
    secret: true
    description: SRT encryption passphrase
  latency:
    type: integer
    default: 200
    min: 20
    max: 8000
    description: SRT latency in milliseconds
  bind_address:
    type: string
    default: "0.0.0.0"
    description: Address to bind to

# Health check
health:
  type: gstreamer-pipeline
  check_interval_seconds: 10
  metrics:
    - name: bitrate_mbps
      source: pipeline
      description: Current receive bitrate
    - name: packet_loss_pct
      source: srt_stats
      description: SRT packet loss percentage
    - name: rtt_ms
      source: srt_stats
      description: SRT round-trip time

# Systemd service
service:
  name: wave-srt-in
  type: simple
  restart: always
  restart_sec: 5

# API endpoints added by this module
api:
  - path: /api/modules/srt-in/status
    method: GET
    description: SRT input status and statistics
  - path: /api/modules/srt-in/config
    method: GET
    description: Current SRT configuration
  - path: /api/modules/srt-in/config
    method: PUT
    description: Update SRT configuration
```

## Module Directory Structure

```
/opt/wave/modules/wave-srt-in/
├── module.yaml          # Manifest (required)
├── install.sh           # Install script (optional, runs on install)
├── uninstall.sh         # Uninstall script (optional)
├── wave-srt-in.service  # Systemd service file
├── config.yaml          # Runtime configuration (generated)
├── pipeline.gst         # GStreamer pipeline definition
└── bin/                 # Module-specific binaries (optional)
    └── srt-stats        # SRT statistics collector
```

## Module Lifecycle

```
discover → install → configure → start → health-check → stop → uninstall
```

| State | Description |
|-------|-------------|
| `available` | In module catalog, not installed |
| `installing` | Being downloaded and set up |
| `installed` | Files on disk, not running |
| `configuring` | Configuration being applied |
| `running` | Active and healthy |
| `degraded` | Running but health check failing |
| `stopped` | Installed but not running |
| `uninstalling` | Being removed |
| `error` | Failed to install/start |

## Module Categories

| Category | Description | Examples |
|----------|-------------|---------|
| `video-input` | Receive/capture video | wave-srt-in, wave-ndi-in, wave-hdmi-in |
| `video-output` | Display/send video | wave-hdmi-out, wave-srt-out, wave-ndi-out |
| `audio` | Audio input/output/processing | wave-audio-in, wave-comms, wave-dante-in |
| `ai` | AI/ML processing | wave-ai-caption, wave-ai-director |
| `control` | Device/protocol control | wave-companion, wave-streamdeck, wave-ptz |
| `network` | Network configuration | wave-poe, wave-wifi-ap, wave-vpn |
| `monitoring` | Health/metrics/telemetry | wave-prometheus, wave-tally |

## CLI Commands

```bash
# List available modules
wave module list                    # Show installed
wave module list --available        # Show catalog
wave module list --category video-input

# Install/remove
wave module install wave-srt-in
wave module install wave-srt-in --version 0.3.0
wave module remove wave-srt-in

# Configure
wave module config wave-srt-in                    # Show config
wave module config wave-srt-in --set port=9001    # Set value
wave module config wave-srt-in --reset            # Reset to defaults

# Control
wave module start wave-srt-in
wave module stop wave-srt-in
wave module restart wave-srt-in
wave module status wave-srt-in      # Show health + metrics

# Profiles (module bundles)
wave profile list
wave profile apply ndi-decoder
wave profile export my-setup.yaml
wave profile import my-setup.yaml
```

## Module Catalog (v0.1.0 — Initial Release)

| Module | Category | Status | Description |
|--------|----------|--------|-------------|
| wave-srt-in | video-input | Planned | SRT receive + decode |
| wave-hdmi-out | video-output | Planned | HDMI display output |
| wave-ndi-in | video-input | Planned | NDI 5 receive |
| wave-whep-in | video-input | Planned | WHEP/WebRTC receive |
| wave-srt-out | video-output | Planned | SRT send |
| wave-rtmp-out | video-output | Planned | RTMP send |
| wave-audio-in | audio | Planned | USB audio input |
| wave-audio-out | audio | Planned | USB/HDMI audio output |
| wave-ai-caption | ai | Planned | Real-time captioning |
| wave-companion | control | Planned | Bitfocus Companion |
| wave-streamdeck | control | Planned | Elgato Stream Deck |
| wave-prometheus | monitoring | Planned | Metrics exporter |

## Profile Format

```yaml
# profiles/ndi-decoder.yaml
name: ndi-decoder
description: Receive NDI stream and display on HDMI
modules:
  - name: wave-ndi-in
    config:
      auto_discover: true
  - name: wave-hdmi-out
    config:
      resolution: auto
      audio: passthrough
  - name: wave-prometheus
    config:
      port: 9100
```
