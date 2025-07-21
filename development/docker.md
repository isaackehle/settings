# Docker

```shell
brew install docker docker-compose
```

## Docker Desktop

[Install page](https://www.docker.com/products/docker-desktop/)

## postgresql image

```shell
brew install postgresql@15

createuser -s postgres
```

### ~/.docker/config.json

```json
{
	"auths": {
	},
	"cliPluginsExtraDirs": [
		"/opt/homebrew/lib/docker/cli-plugins"
	]
}
```

```shell

#!/usr/bin/env bash

set -euo pipefail
which psql > /dev/null || (echoerr "Please ensure that postgres client is in your PATH" && exit 1)

mkdir -p $HOME/docker/volumes/postgres
rm -rf $HOME/docker/volumes/postgres/data

docker run --rm --name pg-docker -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=dev -d -p 5432:5432 -v $HOME/docker/volumes/postgres:/var/lib/postgresql postgres
sleep 3
export PGPASSWORD=postgres
psql -U postgres -d dev -h localhost -f schema.sql
psql -U postgres -d dev -h localhost -f data.sql
```
