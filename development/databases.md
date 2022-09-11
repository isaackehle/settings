# Databases

## Database types

### MongoDB

```bash
brew tap mongodb/brew
brew install mongodb-community
brew install mongodb

# To have launchd start mongodb at login:

ln -sfv /usr/local/opt/mongodb/*.plist ~/Library/LaunchAgents

# Then to load mongodb now:
launchctl load ~/Library/LaunchAgents/homebrew.mxcl.mongodb.plist
```

- Or, for mongodb with a replica set

### Postgresql

- [How to Install Postgresql on Mac using Homebrew](https://dyclassroom.com/howto-mac/how-to-install-postgresql-on-mac-using-homebrew)
- [PSQL Fatal: role `postgres` does not exist](https://stackoverflow.com/questions/15301826/psql-fatal-role-postgres-does-not-exist)

```bash
brew install postgresql@14
brew services start postgresql@14

/usr/local/opt/postgresql@14/bin/createuser -s postgres
```

```note
PostgreSQL: Documentation: 13: 9.16. JSON Functions and Operators
The operator -> returns JSON object field as JSON.
The operator ->> returns JSON object field as text.
```

## GUIs

### Navicat

```bash
brew install --force navicat-premium
```

> Might need to set the TDS for navicat

```bash
# Current Session
launchctl setenv TDSVER 7.0
```

```bash
# Permanent
echo '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
 <key>Label</key>
     <string>setenv.TDSVER</string>
 <key>ProgramArguments</key>
 <array>
   <string>/bin/launchctl</string>
   <string>setenv</string>
   <string>TDSVER</string>
   <string>7.0</string>
 </array>
 <key>RunAtLoad</key>
     <true/>
</dict>
</plist>' > ~/Library/LaunchAgents/setenv.TDSVER.plist
```

### Studio-3T MongoChef

```bash
brew install --cask studio-3t
```

### Robomongo

```bash
brew install --cask robomongo
```

### dBeaver

```bash
brew install --cask dbeaver-community
```

### Cassandra
