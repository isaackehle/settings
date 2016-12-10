
# Transfer from one mac to another


## MongoChef

* Export connections
  1. Open Connect Dialog
  1. Select all (or desired) connections
  1. Click `Export`
  1. Click `Include passwords`
  1. Save to secure location (local flash drive)
  
* Import connections on new computer
  1. Open Connect Dialog
  1. Click `Import`
  1. Select file on flash drive previously saved
  1. Select all and import.  (Note: Names will have the import date appended)
  
* Kill the connections file

  
## Navicat

* Export connections
  1. Connections menu -> Export Connections...
  1. Select all (or desired) connections
  1. Click `OK`
  1. Save to secure location (local flash drive)
  
* Import connections on new computer
  1. Connections menu -> Import Connections...
  1. Select file on flash drive previously saved
  1. Select `OK`
  
* Kill the connections file

* Save tnsnames.ora, sqlnet.ora
  1. Ensure Navicat Premium is closed
  1. Download from http://www.ncsu.edu/project/oraclenet/tns.html
  1. Save files to ~/Documents
  1. Link the file(s) to the home folder:
     ```
     ln -s ~/Documents/tnsnames.ora ~/.tnsnames.ora
     ln -s ~/Documents/sqlnet.ora ~/.sqlnet.ora
     ```
  1. Link the file(s) to the OCI network folder:
     ```
     sudo mkdir -p /opt/oracle/instantclient/network/admin/
     sudo ln -s ~/Documents/tnsnames.ora /opt/oracle/instantclient/network/admin/
     sudo ln -s ~/Documents/sqlnet.ora /opt/oracle/instantclient/network/admin/
     ```
* Save Navicat Settings
  1. Open Navicat->Preferences, Environments tab
  1. Uncheck 'Use Bundled Instant Client'
  1. Set ORACLE_HOME to `/opt/oracle/instantclient`
  1. Set DYLD_LIBRARY_PATH to `/opt/oracle/instantclient`
  1. Set TNS_ADMIN to `/opt/oracle/instantclient/network/admin`
