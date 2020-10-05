

## Reference Articles

* http://apple.stackexchange.com/questions/12161/os-x-terminal-must-have-utilities
* http://marcgrabanski.com/setting-up-mac-osx-web-development/
* https://miteshshah.github.io/mac/things-to-do-after-installing-mac-os-x/
* https://mattstauffer.co/blog/setting-up-a-new-os-x-development-machine-part-2-global-package-managers
* https://miteshshah.github.io/mac/install-network-tools-on-mac-os-x/

# New Computer Installation

* [brew](./brew.md)
* [zsh, with oh-my-zsh](./zsh.md)

* generic [colouriser](http://kassiopeia.juls.savba.sk/~garabik/software/grc/)  
  ```bash
  brew install grc
  ```

* Install wget
  ```bash
  brew install wget
  ```


* Updates openssh
  ```bash
  brew install homebrew/dupes/openssh
  ```


## Fonts
```bash
brew cask install font-roboto font-roboto-condensed font-roboto-mono font-roboto-mono-for-powerline font-roboto-slab
``` 

## Programs
* [iterm](./iterm.md)
* [browsers](./browsers.md)
* [editors](./editors.md)
* [internet utils](./internet.md)


* Music
  ```bash
  brew cask install --force amazon-music
  brew cask install --force spotify
  brew cask install --force vlc
  brew cask install --force pandora
  brew cask install --force rdio
  ```

* Compression
  ```bash
  brew install unrar
  brew cask install the-unarchiver
  ```

* Fonts
  ```bash
  brew cask install --force font-noto-sans-hebrew
  brew cask install --force font-open-sans-hebrew
  brew cask install --force font-open-sans-hebrew-condensed
  ```

* Messaging/Conferencing Apps
  ```bash
  brew cask install telegram
  brew cask install telegram-desktop
  brew cask install vsee
  brew cask install gitter 
  brew cask install skype
  brew cask install slack
  brew cask install messenger-for-desktop
  brew cask install adium
  ```

* Adobe

  ```bash
  brew cask install --force adobe-air adobe-reader
  ```

* Cloud Sync

  ```bash
  brew cask install --force dropbox
  brew cask install --force insync
  ```

* Passwords

  ```bash
  brew cask install --force keepassx
  ```

* Tweaks, Drivers
  ```bash
  # brew cask install --force paragon-ntfs -- did not like install via brew
  ```

* Calendars
  ```bash
  brew cask install --force itsycal
  brew cask install --force anylist
  ```

* Uninstaller Programs
  ```bash
  brew cask install --force appcleaner
  ```

* Other Sweet Utils
  ```bash
  brew cask install --force path-finder
  brew cask install --force xquartz
  brew cask install --force burn ccleaner
  brew cask install --force ejector
  brew cask install --force mounty
  brew cask install --force flux
  brew cask install --force controlplane
  brew cask install --force disk-inventory-x
  brew cask install --force airparrot
  brew cask install --force alfred
  brew cask install --force controlplane
  brew cask install --force macid
  brew cask install --force java
  brew cask install --force spectacle
  brew install tree
  ```

* SDKs
  ```bash
  brew cask install --force android-studio
  brew install android-sdk
  ```

* Torrent, Downloaders
  ```bash
  brew cask install --force deluge
  brew cask install --force folx
  ```

* VNC
  ```bash
  brew cask install --force vnc-viewer
  ```

* VPN
  ```bash
  brew cask install --force tunnelblick
  ```

* Drawing, Multimedia, Graphics
  ```bash
  brew cask install --force gimp
  brew cask install --force colorpicker colorpicker-hex colorsnapper
  brew cask install --force ffmpegx
  # brew install ffmpeg
  brew install ffmpeg --with-libvpx
  brew install imagemagick --with-webp
  brew cask install --force inkscape
  brew cask install --force handbrake handbrakebatch handbrakecli
  brew cask install --force omnigraffle
  brew cask install --force id3-editor
  brew cask install --force mp3tag
  brew cask install --force kodi
  brew cask install --force sling
  ```

* [Databases](./databases.md)

* VMs
  ```bash
  brew cask install --force virtualbox
  brew cask install --force vmware-fusion
  brew install docker-machine
  ```


* Version Control
  ```bash
  brew install git
  brew cask install --force github-desktop
  ```

* Node
  ```bash
  brew install node
  ```

# Automation
  ```bash
  brew install ansible
  brew install autossh
  ```


* Encryption, MD5 
  ```bash
  brew install mcrypt
  brew install md5sha1sum
  brew install mhash
  ```


## Other programs that do not have casks
* cisco any connect
* [MenuMeters](http://www.ragingmenace.com/software/menumeters/)
* [Flash Player](http://get.adobe.com/flashplayer/otherversions/)
* [Java RE](http://www.oracle.com/technetwork/java/javase/downloads/index.html)
* [Silverlight](http://www.microsoft.com/getsilverlight/Get-Started/Install/Default.aspx)
* [Wallcat](https://beta.wall.cat/)
* iFax
* Paragon NTFS 14

* Inhibit .DS_Store and .AppleDouble from being created on network drives [Link](http://www.mac-forums.com/forums/switcher-hangout/275107-appledouble-file-directory.html)

```bash
defaults write com.apple.desktopservices DSDontWriteNetworkStores true
```


### Uncategorized brew apps -- things I haven't taken the time to sort

```bash

brew install apg
brew install apr
brew install apr-util
brew install arping
brew install bdw-gc
brew install c-ares
brew install cairo
brew install d-bus
brew install dbus
brew install dialog
brew install expect
brew install faac
brew install ffind
brew install fftw
brew install figlet
brew install findutils
brew install fontconfig
brew install freetype
brew install gdbm
brew install gdk-pixbuf
brew install geoip
brew install gettext
brew install giflib
brew install git
brew install glib
brew install gmp
brew install gnu-sed
brew install gnupg
brew install gnutls
brew install gobject-introspection
brew install grc
brew install grep
brew install harfbuzz
brew install httpd24
brew install icu4c
brew install imagemagick
brew install ipcalc
brew install jpeg
brew install jq
brew install lame
brew install libav
brew install libcroco
brew install libexif
brew install libffi
brew install libgcrypt
brew install libgpg-error
brew install libgsf
brew install libnet
brew install libpng
brew install librsvg
brew install libtasn1
brew install libtiff
brew install libtool
brew install libvpx
brew install libxml2
brew install libyaml
brew install little-cms2
brew install lynx
brew install makedepend
brew install minicom
brew install moreutils
brew install mtr
brew install nettle
brew install nmap
brew install node
brew install nvm
brew install oniguruma
brew install openjpeg
brew install openssh
brew install openssl
brew install openssl@1.1
brew install orc
brew install pango
brew install pcre
brew install perl
brew install php-cs-fixer
brew install php70
brew install pixman
brew install pkg-config
brew install poppler
brew install proctools
brew install pstree
brew install putty
brew install py2cairo
brew install pygobject3
brew install python
brew install qprint
brew install readline
brew install rsync
brew install scons
brew install shared-mime-info
brew install signing-party
brew install sqlformat
brew install sqlite
brew install ssh-copy-id
brew install ssldump
brew install tcping
brew install texi2html

brew install thefuck
eval "$(thefuck --alias)"

brew install unixodbc
brew install vips
brew install w3m
brew install watch
brew install watchman
brew install webp
brew install x264
brew install xvid
brew install xz
brew install yasm
brew install zlib


brew install ssh-copy-id
brew install watch

brew install fish
brew install pv
brew install rename
brew install tree
brew install zopfli
```


Other Appstore Apps


```bash
Wunderlist
VPN Unlimited
Color Picker
iHex - Hex Editor
Microsoft Remote Desktop Beta
Microsft Office
iMovie
Pages, Numbers, etc
XCode
tweetdeck
lastpass
```

Other ones I found helpful one day..

```
brew cask install google-drive-file-stream google-hangouts google-backup-and-sync google-earth-pro
```


