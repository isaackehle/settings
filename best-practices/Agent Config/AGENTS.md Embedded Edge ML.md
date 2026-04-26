---
tags: [development, ai, agents]
---

# [Project Name] — Embedded / Edge ML Agent Instructions

> **Canonical source:** This file governs agent behavior repo-wide. Per-subsystem overrides live in `model/AGENTS.md` and `firmware/AGENTS.md`.

## Purpose

<!-- Describe what this project does, the target hardware, and the ML task being solved. -->

---

## Tech Stack

**Host (macOS Apple Silicon):** Python 3.12+ (`uv`) · TensorFlow/TFLite · Docker (Buildx) · PlatformIO CLI (`pio`) or `arduino-cli` · Ruff · `clang-format` · `pytest`

**Target:** C/C++ (Arduino framework or bare-metal CMSIS) · TFLite Micro · ARM Cortex-M (MCU) / ARM Linux (SBC)

**Hardware:**

| Board | Core | Notes |
|---|---|---|
| Raspberry Pi (3/4/5/Zero 2) | ARM Cortex-A (Linux) | GPIO, I2C, SPI via `/dev` or `pigpio` |
| Arduino Nano 33 BLE Sense | Cortex-M4F (nRF52840) | Onboard IMU, mic, proximity; 256 KB RAM |
| Adafruit accessories | varies | VID/PID and I2C address → `board_config.h` |

**ML Pipeline:**

```
Train (Python / Docker on Mac)  →  SavedModel
  └─▶ convert_model.py  →  model.tflite (int8 quantized)
       └─▶ xxd / bin2header.py  →  model_data.h  →  compiled into firmware
```

---

## Key Commands

```bash
# Training (containerized)
docker build -t edgeml-train .
docker run --rm -v "$(pwd)/model":/workspace edgeml-train python train.py

# Model conversion & quantization
python scripts/convert_model.py --input model/saved_model --output model/model.tflite

# PlatformIO
pio run                          # build
pio run -t upload                # flash
pio test -e native               # Unity tests on host

# arduino-cli
arduino-cli compile --fqbn arduino:mbed_nano:nano33ble firmware/
arduino-cli upload  --fqbn arduino:mbed_nano:nano33ble -p /dev/cu.usbmodem* firmware/

# Host tests
uv run pytest tests/ -v

# Serial monitor
pio device monitor -b 115200
```

---

## Project Structure

```
.
├── model/                  # Python training code
│   ├── train.py
│   ├── convert_model.py
│   ├── notebooks/
│   └── AGENTS.md           # ML pipeline overrides
├── firmware/               # Device C/C++ code
│   ├── src/
│   ├── include/
│   │   └── board_config.h  # Pin assignments, I2C addresses, constants
│   ├── lib/                # Vendored / project libraries
│   ├── platformio.ini
│   └── AGENTS.md           # Firmware overrides
├── scripts/                # Build, flash, and conversion helpers
├── tests/                  # Host-side pytest suite
├── Dockerfile
└── AGENTS.md               ← this file
```

---

## Non-Obvious Patterns

- **Quantization is mandatory.** Models train in float32; the deployed artifact is int8 TFLite. Validate accuracy post-quantization — don't assume it is preserved.
- **`.pio/` is generated.** Never edit files under `.pio/build/`. Changes are silently overwritten on the next build.
- **`board_config.h` is the single pin/address registry.** Check it before assuming any GPIO number, I2C address, or SPI CS line.
- **Model header generation.** `scripts/bin2header.py` (or `xxd -i`) converts `.tflite` → C array. Re-run it whenever the model changes; keep `firmware/include/model_data.h` in sync.
- **RAM budget on Nano 33 BLE is tight.** Keep `MODEL_ARENA_SIZE` in `board_config.h` current. Profile with `MicroInterpreter::arena_used_bytes()` after every model update.
- **Docker cross-compilation.** Containers target `linux/arm64` by default for Pi parity. Set `--platform` explicitly in CI.
- **ISRs must be minimal.** Set a flag; handle work in the main loop. No heap allocation or blocking calls inside interrupt handlers.

---

## Code Style

**C/C++:** Follow `.clang-format` (fall back to Arduino style guide) · `const`/`constexpr` over `#define` · `<cstdint>` fixed-width types for register-width-sensitive values · no `new`/`malloc` in firmware unless explicitly justified.

**Python:** Ruff lint + format · full type hints on public functions · `uv` manages the virtualenv (`pip install` is not permitted directly).

---

## Testing Rules

- **Host pipeline:** `pytest tests/` covers training utilities, conversion scripts, and post-quantization accuracy — all must pass before a firmware PR that consumes a new model.
- **Accuracy gate:** Threshold in `tests/test_quantization.py`. Do not skip or lower it without explicit approval.
- **Firmware unit tests:** Unity via `pio test`. Cover pure-logic modules (DSP, feature extraction); exclude hardware-dependent code from the native runner.
- **On-device smoke test:** Confirm expected serial output after every flash; document the command in the PR description.

---

## Git Commits

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(firmware): add sliding window inference on IMU data
fix(model): correct label mapping in convert_model.py
chore(docker): pin tensorflow base image to 2.17.0
```

No `Co-Authored-By` trailers. Do not commit `.tflite` files > 10 MB without Git LFS.

---

## Agent Skills

Reusable prompt fragments live in `.agents/skills/`:

```
.agents/skills/
├── quantize-and-validate.md   # Convert + run accuracy gate
├── flash-and-verify.md        # Flash sequence + expected serial output
└── add-sensor-driver.md       # Checklist for a new I2C sensor
```

Reference at the top of a prompt: `skills: quantize-and-validate`

---

## Boundaries

| | Scope |
|---|---|
| ✅ **Allowed** | Read any file · Run `ruff` / `clang-format` · Run `pytest` · Edit `model/` and `firmware/src/` · Build with `pio run` |
| ⚠️ **Ask first** | Flash device · Install new dependencies · Modify `board_config.h` · Change model architecture or quantization scheme |
| 🚫 **Never** | Commit model binaries > 10 MB without LFS · Edit `.pio/build/` · Force-push any branch · Commit credentials, Wi-Fi SSIDs, or API keys |

---

## Modular Overrides

| File | Governs |
|---|---|
| `model/AGENTS.md` | Training, dataset handling, conversion pipeline, accuracy thresholds |
| `firmware/AGENTS.md` | Device code conventions, memory budget, peripheral drivers, flash procedure |

Subdirectory `AGENTS.md` files extend — not replace — this file unless explicitly stated.

---

## Tool-Specific Symlinks

| Tool | Config path | Notes |
|---|---|---|
| Cursor | `.cursor/rules/` → `AGENTS.md` | Symlink so Cursor picks up the same rules |
| Copilot (VS Code) | `.github/copilot-instructions.md` → `AGENTS.md` | GitHub Copilot workspace instructions |
| Aider | `.aider.conf.yml` `read:` list | Reference this file directly |
| Claude Code | `CLAUDE.md` → `AGENTS.md` | Symlink at repo root |
