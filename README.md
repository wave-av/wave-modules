# wave-modules

**WAVE modules** are the modular streaming components that run on WAVE edge devices, managed by [wave-agent](https://github.com/wave-av/wave-agent). Each module is a self-contained directory with a YAML manifest, an install script, and (for media modules) a GStreamer pipeline template.

## What's here

This repo ships a starter set of modules; the full set is documented in [MODULE-CATALOG.md](MODULE-CATALOG.md).

| Module | Category | Description |
|--------|----------|-------------|
| [`wave-srt-in`](wave-srt-in) | Video input | Receive SRT streams, decode H.264/H.265 |
| [`wave-ndi-in`](wave-ndi-in) | Video input | NDI 5 receive with auto-discover and tally |
| [`wave-hdmi-out`](wave-hdmi-out) | Video output | HDMI display via DRM/KMS |
| [`wave-companion`](wave-companion) | Control | Bitfocus Companion integration |
| [`wave-prometheus`](wave-prometheus) | Monitoring | WAVE metrics + node_exporter |

See [MODULE-CATALOG.md](MODULE-CATALOG.md) for the broader catalog of input/output/control/monitoring modules.

## Module format

Every module is a directory containing a `module.yaml` manifest that declares its version, category, protocol, hardware requirements, package dependencies, conflicts, a pipeline template, and a config schema. The full format is defined in [MODULE-SPEC.md](MODULE-SPEC.md).

## Install a module

Each module includes an `install.sh` that installs OS dependencies and lays down the module under `/opt/wave/modules`. On a WAVE edge device:

```bash
sudo ./wave-srt-in/install.sh
```

Install scripts install required packages (e.g. GStreamer plugins for media modules) and write a default config. In normal operation, modules are installed and driven by [wave-agent](https://github.com/wave-av/wave-agent) rather than by hand.

## Status

Module spec is at version 0.1.0 — early and evolving. The modules in this repo are the initial reference set.

## See also

- [MODULE-SPEC.md](MODULE-SPEC.md) — module manifest format
- [MODULE-CATALOG.md](MODULE-CATALOG.md) — full module catalog
- [AGENTS.md](AGENTS.md) · [CHANGELOG.md](CHANGELOG.md)

## Links
- [wave.online](https://wave.online) · [Docs](https://docs.wave.online) · [Developer portal](https://dev.wave.online)

Operated by WAVE Online, LLC.
