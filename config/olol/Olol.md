---
tags: [ai, local, inference, load-balancer, ollama]
---

# olol

Ollama load balancer — routes requests across multiple Ollama backends running on different machines. Each backend runs the full model independently; olol distributes the traffic.

- **GitHub:** [K2/olol](https://github.com/K2/olol)
- **Default port:** `11435`

## How It Works

olol sits in front of multiple Ollama instances and distributes requests round-robin (or by least-busy). Point your tools at `http://localhost:11435/v1` instead of `:11434`.

> This is different from [[Exo]] (which splits one model across machines) — olol requires each backend to load the full model independently.

## Installation

```shell
npm install -g https://github.com/K2/olol.git
```

## Configuration

`~/.config/olol/config.json` (created by `setup_olol.sh` on first run):

```json
{
  "port": 11435,
  "backends": [
    { "url": "http://127.0.0.1:11434", "name": "local-m5max" },
    { "url": "http://192.168.1.100:11434", "name": "mac-studio" }
  ]
}
```

## Usage

```shell
# Start the balancer
olol --config ~/.config/olol/config.json

# Point tools at the balancer port instead of Ollama directly
# Base URL: http://localhost:11435/v1
```

## When to Use

- Multiple Macs each with enough RAM to run the model → distribute load
- Prevent one machine from becoming a bottleneck during parallel tasks
- The model fits on each machine individually

Use [[Exo]] instead if the model is too large for any single machine.

## References

- [GitHub](https://github.com/K2/olol)
