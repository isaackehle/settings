# Transfer from one mac to another

## MongoChef

- Export connections

  1. Open Connect Dialog
  1. Select all (or desired) connections
  1. Click `Export`
  1. Click `Include passwords`
  1. Save to secure location (local flash drive)

- Import connections on new computer

  1. Open Connect Dialog
  1. Click `Import`
  1. Select file on flash drive previously saved
  1. Select all and import. (Note: Names will have the import date appended)

- Kill the connections file

## Navicat

- Copy Settings

  1. Create zip file

     ```shell
     cd ~/Library/Application\ Support/PremiumSoft\ CyberTech
     zip -r ~/insync/pgkehle@gmail.com/settings/navicat/settings.zip .
     ```

  1. Unzip file on new computer

     ```shell
     cd ~/Library/Application\ Support/
     mv PremiumSoft\ CyberTech PremiumSoft\ CyberTech.bak
     mkdir PremiumSoft\ CyberTech
     cd PremiumSoft\ CyberTech
     unzip ~/insync/pgkehle@gmail.com/settings/navicat/settings.zip
     ```

- Kill the settings file

- Save tnsnames.ora, sqlnet.ora

  1. Ensure Navicat Premium is closed
  1. Download from [Oracle](http://www.ncsu.edu/project/oraclenet/tns.html)
  1. Save files to ~/Documents
  1. Link the file(s) to the home folder:

     ```shell
     ln -s ~/Documents/tnsnames.ora ~/.tnsnames.ora
     ln -s ~/Documents/sqlnet.ora ~/.sqlnet.ora
     ```

  1. Link the file(s) to the OCI network folder:

     ```shell
     sudo mkdir -p /opt/oracle/instantclient/network/admin/
     sudo ln -s ~/Documents/tnsnames.ora /opt/oracle/instantclient/network/admin/
     sudo ln -s ~/Documents/sqlnet.ora /opt/oracle/instantclient/network/admin/
     ```

- Update Navicat Settings

  1. Open Navicat->Preferences, Environments tab
  1. Uncheck 'Use Bundled Instant Client'
  1. Set ORACLE_HOME to `/opt/oracle/instantclient`
  1. Set DYLD_LIBRARY_PATH to `/opt/oracle/instantclient`
  1. Set TNS_ADMIN to `/opt/oracle/instantclient/network/admin`

- Check dns server settings on mac:

```shell
scutil --dns | grep 'nameserver\[[0-9]*\]'
```
