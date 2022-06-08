- Databases

  - Navicat

  ```bash
   brew install --force navicat-premium
  ```

  - Might need to set the TDS for navicat

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

  - Studio-3T MongoChef
    ```bash
    brew install --force studio-3t
    ```
  - MongoDB

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

  - Robomongo
    ```bash
    brew install --force robomongo
    ```
