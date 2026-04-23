---
tags: [apps]
---

# <img src="https://github.com/grafana.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Dashboards

Monitoring and observability dashboards.

## Grafana

Open-source observability platform for metrics, logs, and traces.

```shell
brew install grafana
brew services start grafana
```

Access at `http://localhost:3000` (default credentials: `admin` / `admin`).

## Prometheus

Metrics collection and alerting:

```shell
brew install prometheus
brew services start prometheus
```

## Configuration

No basic configuration required.

## Start / Usage

```shell
open http://localhost:3000
open http://localhost:9090
```

## References

- [Grafana](https://grafana.com/)
- [Prometheus](https://prometheus.io/)
