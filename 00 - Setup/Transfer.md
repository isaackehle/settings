---
tags: [setup]
---

# <img src="https://github.com/apple.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Transfer

Steps for migrating settings and connections to a new Mac.

## Studio 3T (MongoDB)

### Export connections

1. Open the Connect dialog
2. Select all desired connections
3. Click **Export** → enable **Include passwords**
4. Save to a secure location (e.g., a local flash drive)

### Import on new Mac

1. Open the Connect dialog
2. Click **Import** → select the previously saved file
3. Select all and import (note: names will have the import date appended)

## Navicat

### Copy settings

```shell
cd ~/Library/Application\ Support/PremiumSoft\ CyberTech
zip -r ~/settings-backup/navicat/settings.zip .
```

On the new Mac:

```shell
cd ~/Library/Application\ Support/
mv PremiumSoft\ CyberTech PremiumSoft\ CyberTech.bak
mkdir PremiumSoft\ CyberTech && cd "$_"
unzip ~/settings-backup/navicat/settings.zip
```

### Oracle TNS configuration

1. Ensure Navicat is closed
2. Download `tnsnames.ora` and `sqlnet.ora`, save to `~/Documents`
3. Create symlinks:

```shell
ln -s ~/Documents/tnsnames.ora ~/.tnsnames.ora
ln -s ~/Documents/sqlnet.ora ~/.sqlnet.ora

sudo mkdir -p /opt/oracle/instantclient/network/admin/
sudo ln -s ~/Documents/tnsnames.ora /opt/oracle/instantclient/network/admin/
sudo ln -s ~/Documents/sqlnet.ora /opt/oracle/instantclient/network/admin/
```

4. In Navicat → Preferences → Environments:
   - Uncheck **Use Bundled Instant Client**
   - `ORACLE_HOME` → `/opt/oracle/instantclient`
   - `DYLD_LIBRARY_PATH` → `/opt/oracle/instantclient`
   - `TNS_ADMIN` → `/opt/oracle/instantclient/network/admin`

## DNS Check

```shell
scutil --dns | grep 'nameserver\[[0-9]*\]'
```
