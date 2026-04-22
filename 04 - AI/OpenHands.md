---
tags: [ai, coding, productivity, agents]
---

# <img src="https://github.com/OpenHands.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> OpenHands

Open-source platform for AI software developers that can autonomously write code, fix bugs, and ship features. Formerly known as OpenDevin.

## Installation

```shell
# Run via Docker
docker run -it --pull=always \
  -e WORKSPACE_MOUNT_PATH=$(pwd) \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -p 3000:3000 \
  ghcr.io/all-hands-ai/openhands:main
```

## Start / Usage

```shell
docker run -it --pull=always \
  -e WORKSPACE_MOUNT_PATH=$(pwd) \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -p 3000:3000 \
  ghcr.io/all-hands-ai/openhands:main
```

Open `http://localhost:3000` in your browser.

## References

- [OpenHands GitHub](https://github.com/OpenHands/OpenHands)
