# Databases

## Database types

### MongoDB

```bash
brew tap mongodb/brew
brew install mongodb-community
```

```bash
brew install mongodb
```

- To have launchd start mongodb at login:

```bash
ln -sfv /usr/local/opt/mongodb/*.plist ~/Library/LaunchAgents
```

- Then to load mongodb now:

```bash
launchctl load ~/Library/LaunchAgents/homebrew.mxcl.mongodb.plist
```

- Or, for mongodb with a replica set:

### Postgresql

From [here](https://dyclassroom.com/howto-mac/how-to-install-postgresql-on-mac-using-homebrew)

```bash
brew install postgres
brew services start postgresql
```

## GUIs

@## Navicat

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
