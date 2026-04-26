---
tags: [ai, coding, productivity, self-hosted]
---

# <img src="https://github.com/TabbyML.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Tabby

Open-source, self-hosted AI coding assistant. Alternative to GitHub Copilot that keeps code completely private.

## Installation

```shell
# Run via Docker
docker run -it -p 8080:8080 -v $HOME/.tabby:/data tabbyml/tabby serve --model StarCoder-1B
```

## Start / Usage

```shell
docker run -it -p 8080:8080 -v $HOME/.tabby:/data tabbyml/tabby serve --model StarCoder-1B
```

## References

- [Tabby GitHub](https://github.com/TabbyML/tabby)
