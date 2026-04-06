# WAVE Edge Module Catalog

> Complete catalog of available modules for WAVE edge devices.

## Video Input

| Module | Protocol | Hardware | Description |
|--------|----------|----------|-------------|
| `wave-srt-in` | SRT | GbE | Receive SRT streams, decode H.264/H.265 |
| `wave-ndi-in` | NDI 5 | GbE | Receive full-bandwidth NDI with tally |
| `wave-ndi-hx-in` | NDI\|HX3 | GbE | Receive compressed NDI HX3 |
| `wave-whep-in` | WHEP/WebRTC | GbE/WiFi | Receive WHEP from browsers/CDN |
| `wave-rtmp-in` | RTMP | GbE | Receive RTMP from OBS/encoders |
| `wave-rtsp-in` | RTSP | GbE | Receive RTSP from IP cameras |
| `wave-hls-in` | HLS | GbE/WiFi | Pull HLS streams |
| `wave-hdmi-in` | HDMI capture | USB capture card | Capture via Magewell/generic USB |
| `wave-usb-cam-in` | V4L2 | USB camera | Capture from USB UVC cameras |
| `wave-omt-in` | OMT | GbE | Receive OMT transport streams |

## Video Output

| Module | Protocol | Hardware | Description |
|--------|----------|----------|-------------|
| `wave-hdmi-out` | HDMI | Built-in | Display on TV/projector via DRM/KMS |
| `wave-srt-out` | SRT | GbE | Send SRT to destinations |
| `wave-whip-out` | WHIP/WebRTC | GbE | Send to Cloudflare/YouTube via WHIP |
| `wave-ndi-out` | NDI | GbE | Send NDI to local network |
| `wave-rtmp-out` | RTMP | GbE | Send to YouTube/Twitch/custom |
| `wave-hls-out` | HLS | GbE + storage | Generate HLS segments locally |
| `wave-multiview-out` | HDMI | Built-in | Multi-source grid display |
| `wave-usb-kvm-out` | USB gadget | USB-C OTG | Act as USB KVM device |

## Audio

| Module | Description | Hardware |
|--------|-------------|----------|
| `wave-audio-in` | USB audio capture (mic, mixer) | USB audio interface |
| `wave-audio-out` | USB/HDMI audio playback | Built-in HDMI or USB |
| `wave-dante-in` | Dante audio over IP receive | GbE |
| `wave-aes67-in` | AES67 audio over IP receive | GbE |
| `wave-comms` | Production intercom (IFB/PL) | USB audio + headset |
| `wave-sip-bridge` | SIP/VoIP telephony bridge | GbE |

## AI

| Module | Description | Hardware |
|--------|-------------|----------|
| `wave-ai-caption` | Real-time captioning via Deepgram/Cohere | Cloud API |
| `wave-ai-director` | AI camera switching (WAVE Autopilot) | Cloud API |
| `wave-ai-detect` | Object/face detection | NPU or cloud |
| `wave-ai-transcribe` | VOD transcription (batch) | Cloud API |
| `wave-ai-translate` | Real-time translation overlay | Cloud API |
| `wave-ollama` | Local LLM inference | 8GB+ RAM device |

## Control

| Module | Description | Hardware |
|--------|-------------|----------|
| `wave-companion` | Bitfocus Companion integration | GbE |
| `wave-streamdeck` | Elgato Stream Deck USB support | USB Stream Deck |
| `wave-midi` | MIDI controller input | USB MIDI |
| `wave-gpio` | GPIO tally/GPI/O control | GPIO pins (Pi) |
| `wave-ptz` | PTZ camera control (VISCA/ONVIF) | GbE/Serial |
| `wave-crestron` | Crestron control integration | GbE |
| `wave-qsys` | Q-SYS control integration | GbE |
| `wave-mqtt` | IoT/home automation bridge | WiFi/GbE |
| `wave-osc` | OSC control protocol | GbE |

## Network

| Module | Description | Hardware |
|--------|-------------|----------|
| `wave-poe` | Power over Ethernet via HAT | PoE HAT |
| `wave-wifi-ap` | Create WiFi access point | WiFi adapter |
| `wave-bonding` | Multi-NIC bonding/failover | USB Ethernet |
| `wave-vpn` | WireGuard/Tailscale mesh VPN | GbE |
| `wave-usb-passthrough` | USB device forwarding over network | USB-C |

## Monitoring

| Module | Description |
|--------|-------------|
| `wave-prometheus` | Node exporter + custom WAVE metrics |
| `wave-grafana-agent` | Push metrics to WAVE cloud Grafana |
| `wave-sentry-edge` | Error tracking + crash reporting |
| `wave-tally` | Tally light control (GPIO LED strip) |
| `wave-health` | Hardware health monitor (temp, CPU, storage) |

## Hardware Profiles

| Profile | Modules Included | Use Case |
|---------|-----------------|----------|
| **ndi-decoder** | ndi-in, hdmi-out, prometheus | Display NDI on screen |
| **srt-gateway** | srt-in, srt-out, whip-out, rtmp-out | Re-stream SRT to multiple |
| **ai-assistant** | srt-in, ai-caption, ai-director, hdmi-out | AI production |
| **stream-deck** | companion, streamdeck, mqtt, osc | Production control |
| **comms-node** | comms, sip-bridge, audio-in, audio-out | Intercom + phone |
| **recording-node** | srt-in, ndi-in, hls-out | ISO recording |
| **usb-kvm** | hdmi-in, usb-kvm-out, srt-out | Remote KVM |
