---
tags: [databases]
---

# Databases

Setup and GUI tools for common databases.

## MongoDB

```shell
brew tap mongodb/brew
brew install mongodb-community
brew services start mongodb-community
```

GUI: [[Databases#Studio 3T|Studio 3T]]

## PostgreSQL

```shell
brew install postgresql@14
brew services start postgresql@14
/usr/local/opt/postgresql@14/bin/createuser -s postgres
```

Useful JSON operators:

- `->` returns a JSON field as JSON
- `->>` returns a JSON field as text

- [PostgreSQL JSON Functions](https://www.postgresql.org/docs/current/functions-json.html)

## GUI Tools

### Navicat

```shell
brew install --force navicat-premium
```

If connecting to SQL Server, set the TDS version:

```shell
# Current session
launchctl setenv TDSVER 7.0
```

### Studio 3T

MongoDB GUI (formerly MongoChef):

```shell
brew install --cask studio-3t
```

### dBeaver (multi-database)

```shell
brew install --cask dbeaver-community
```

### Robomongo

```shell
brew install --cask robomongo
```

## References

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [MongoDB Documentation](https://www.mongodb.com/docs/)
- [How to install PostgreSQL on Mac via Homebrew](https://dyclassroom.com/howto-mac/how-to-install-postgresql-on-mac-using-homebrew)
