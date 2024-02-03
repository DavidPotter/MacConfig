# ~/bin/MacConfig

Files for configuring my Mac OS boxes, including hidden dot files and scripts.
This repository is used to transfer changes back and forth between machines.

Inspired by [Mark Carroll's dotfiles](https://github.com/markcarroll/dotfiles)
and Jason Weathered's [dotfiles](https://github.com/jasoncodes/dotfiles) and
[scripts](https://github.com/jasoncodes/scripts).

## Prerequisites

The following packages are required before installing this set of tools:

- Xcode
- Xcode Command Line Tools
- Java JVM

## Installation

From GitLab:
```bash
bash < <( curl -sL https://raw.githubusercontent.com/DavidPotter/MacConfig/master/install.sh )
```

From GitHub:
```bash
bash < <( curl -sL http://github.com/DavidPotter/MacConfig/raw/master/install.sh )
```

Installing in this way will do the following:

- Clone this Git repository to ~/bin/MacConfig.
- Attempt to create a symbolic link for all the files in the dotfiles
  subdirectory in your root directory.

## What else you have to do

To take full advantage of these scripts, you also need to install the
following packages. You can do this by executing the install-tools.sh script.

| Tool                     | Description                                                                                                                                                   |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Git                      | This is installed with Xcode. Go to the Downloads pane of the Preferences panel to do this.                                                                   |
| Git Completion (\*)      | Located in the [contrib directory of the git repository](https://github.com/git/git.git).                                                                     |
| Git-Flow (\*)            | [Git extensions](https://github.com/nvie/gitflow) to provide high-level repository operations for Vincent Driessen's branching model.                         |
| Git-Flow Completion (\*) | [Command line completion](https://github.com/bobthecow/git-flow-completion.git) for Git-Flow.                                                                 |
| Ruby                     | If you have Ruby installed additional features are added for editing and recognizing Ruby files. Most of this is commented out as I don't currently use Ruby. |

## What It Gives You

### profile

- Sets the command line prompt to show:
  - The current time
  - The current user and machine
  - The current directory
  - The current branch and status if in a directory that is a GIT repository
- Sets the default man pager to 'less'
- Configures the command line history
- Sets up GIT command line completion
- Defines a number of useful aliases (dir, .., etc.)
- Defines a number of useful functions:

| Function  | Description                                                     |
| --------- | --------------------------------------------------------------- |
| pman      | Open man pages in Preview app                                   |
| cd_smburl | 'cd' into SMB URLs like this: cd_smburl smb://host/share        |
| dif       | Compare two files using the selected diff application (p4merge) |

### inputrc

- Up/down restricts history lookup (type some characters and it restricts to
  those commands that begin with those characters)
- Support Ctrl-left and right arrows for word moving
- Support delete and insert keys

## Packages and Applications to Install via Homebrew

[Homebrew](https://brew.sh/) is the next thing to install. Homebrew is a
package manager for installing other packages.

### Packages to Install

Once you've installed Homebrew, you may want to install the following
packages. You will install these using the syntax:

```bash
brew install <package>
```

| Tool                                                                                 | Description                                                                |
| ------------------------------------------------------------------------------------ | -------------------------------------------------------------------------- |
| [bash](http://git.savannah.gnu.org/cgit/bash.git/)                                   | Latest version of the Bourne Again SHell (see notes below)                 |
| [bash-completion](https://github.com/scop/bash-completion)                           | Command-line completion for bash (Bourne Again Shell)                      |
| [carthage](https://github.com/Carthage/Carthage)                                     | Dependency manager (use CocoaPods instead if you can)                      |
| [cocoapods](https://cocoapods.org/)                                                  | Dependency manager for for Swift and Objective-C Cocoa projects            |
| [dos2unix](https://linux.die.net/man/1/dos2unix)                                     | Converts line endings in a file from CR/LF (Windows) to just LF (Unix/Mac) |
| [gdub](https://github.com/dougborg/gdub)                                             | Simple command-line tool for running Gradle or the Gradle wrapper script   |
| [gradle](https://gradle.org/)                                                        | Build tool                                                                 |
| [node](https://nodejs.org/)                                                          | (Node.js) a JavaScript runtime                                             |
| [n](https://github.com/tj/n)                                                         | Interactively manage node.js versions                                      |
| [swiftlint](https://github.com/realm/SwiftLint)                                      | A tool to enforce Swift style and conventions                              |
| [tree](https://rschu.me/list-a-directory-with-tree-command-on-mac-os-x-3b2d4c4a4827) | Command line tool to display a directory tree hierarchically               |
| [unix2dos](https://linux.die.net/man/1/unix2dos)                                     | Converts line endings in a file from LF (Unix/Mac) to CR/LF (Windows)      |
| [wget](https://www.gnu.org/software/wget/)                                           | Retrieves files from a web server                                          |
| [yarn](https://yarnpkg.com/en/)                                                      | Dependency management for node.js projects                                 |

### Applications to Install via Homebrew

Homebrew provides formulae for installing some applications. This is a
convenient way to install applications that doesn't require visiting a web
page and downloading a disk image file (.dmg).

Use the following command to install an application with Homebrew:

```bash
brew install --cask <cask>
```

Once an application has been installed, it will be available in the
`Application` directory just like applications installed via the App Store
app.

| Application                                                                | Description                                                           |
| -------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| [docker](https://www.docker.com/)                                          | Tool for creating, deploying, and running applications in a container |
| [powershell](https://docs.microsoft.com/en-us/powershell/)                 | Command-line shell built on .NET                                      |
| [react-native-debugger](https://github.com/jhen0409/react-native-debugger) | Standalone application for debugging React Native applications.       |
| [reactotron](https://github.com/infinitered/reactotron)                    | Desktop app for inspecting React JS and React Native projects         |

### Bash

The version of bash included with macOS is very old (something like 3.2.57)
and the state of art has moved on. Here are the steps to configure the latest
version of bash once it's been installed:

1. Add the new version to the `/etc/shells` file:

   ```shell
   sudo bash -c "echo $(brew --prefix)/bin/bash >> /private/etc/shells"
   ```

2. Change the default terminal shell:

   ```shell
   sudo chsh -s $(brew --prefix)/bin/bash
   ```

3. Reboot

#### References

- [shell bash 4 on macos](http://www.aozsky.com/shelltools/shell-bash)
- [Upgrade bash on your mac os !](https://coderwall.com/p/dmuxma/upgrade-bash-on-your-mac-os)
- [Upgrade to bash 4 in Mac OS X](https://clubmate.fi/upgrade-to-bash-4-in-mac-os-x/)
- [GNU Bash](https://www.gnu.org/software/bash/)

### PowerShell

The PowerShell cask installs an application in the `Applications` directory
and also installs a command line tool in `/user/local/bin`.

To run PowerShell from the command line, execute the following command:

```shell
pwsh
```

## Terminal

By default the Home and End keys don't do anything in Terminal. The following
procedure will modify their behavior to be like in Windows.

1. Bring up preferences on Terminal
2. Switch to the Profiles tab
3. Switch to the Keyboard tab of the desired profile
4. Click the + to add a new keyboard definition
5. Set the key to Home or End
6. Set Modifier to None
7. Set Action to Send Text
8. Type one of the following in the text box (press the esc key for `\033`):
   - Home: `\033[H`
   - End: `\033[F`

(from https://apple.stackexchange.com/questions/12997/can-home-and-end-keys-be-mapped-when-using-terminal)

## Applications

The following sections list the applications that I use either on every
machine or on select machines depending on their use.

\* Purchase required

### App Store Applications

| Application               | Type         | Description                                          |
| ------------------------- | ------------ | ---------------------------------------------------- |
| \*Affinity Designer       | Development  | Professional graphic design software                 |
| Amphetamine               | Utility      | Keep the Mac awake (e.g. for presentations)          |
| Asset Catalog Creator Pro | Development  | Creates asset catalogs in Xcode projects             |
| \*BetterSnapTool          | Utility      | Improved window management                           |
| Commander One             | Utility      | File manager                                         |
| Display Menu              | Utility      | Menu for display settings                            |
| FullContact               | Productivity | Contact manager                                      |
| Hex Fiend                 | Development  | Hex editor                                           |
| iMage Tools               | Media        | Simple image editing tool                            |
| \*JSON Editor             | Development  | A simple but powerful JSON editor                    |
| Kindle                    | Productivity | Amazon's book reader                                 |
| Microsoft OneDrive        | Productivity | Cloud drive software                                 |
| Microsoft OneNote         | Productivity | Note taking application                              |
| Microsoft Remote Desktop  | Productivity | Remote access software for connecting to Windows PCs |
| Motif                     | Productivity | Create photo books                                   |
| \*My Movies 2 Pro         | Media        | Movie catalog application                            |
| \*OmniGraffle             | Development  | Graphic design software                              |
| Pocket                    | Productivity | Internet news reader                                 |
| QR Journal                | Productivity | Scan QR codes                                        |
| Simplenote                | Productivity | Note application                                     |

### Development Tools

| Application                                                        | Description                             |
| ------------------------------------------------------------------ | --------------------------------------- |
| [Android Studio](https://developer.android.com/studio/)            | IDE for developing Android applications |
| [\*AppCode by JetBrains](https://www.jetbrains.com)                | IDE for iOS/macOS development           |
| [\*CLion by JetBrains](https://www.jetbrains.com)                  | A cross-platform IDE for C and C++      |
| [Cocoa Rest Client](http://mmattozzi.github.io/cocoa-rest-client/) | App for testing HTTP/REST endpoints     |
| [\*DataGrip by JetBrains](https://www.jetbrains.com)               | Database tool                           |
| [DB Browser for SQLite](https://sqlitebrowser.org)                 | SQLite database browser                 |
| [GitKraken](https://www.gitkraken.com)                             | Git client                              |
| [iExplorer](https://macroplant.com)                                | Transfer utility for iOS devices        |
| [MySQL Workbench](https://www.mysql.com/products/workbench/)       | Visual tool for MySQL                   |
| [\*PhpStorm by JetBrains](https://www.jetbrains.com)               | IDE for PHP development                 |
| [\*PyCharm by JetBrains](https://www.jetbrains.com)                | IDE for Python development              |
| [RESTClient](https://github.com/wiztools/rest-client)              | Tool to test HTTP RESTful web services  |
| [SourceTree](https://www.sourcetreeapp.com)                        | Git client                              |
| [\*TextMate](https://macromates.com)                               | Text editor                             |
| [Visual Studio Code](https://code.visualstudio.com)                | Excellent free IDE from Microsoft       |
| [\*WebStorm by JetBrains](https://www.jetbrains.com)               | IDE for web development                 |

### Utilities

| Application                                                                           | Description                                             |
| ------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| [AccessMenuBarApps](http://www.ortisoft.de/en/accessmenubarapps/)                     | Gives access to all menu bar apps                       |
| [Duet](https://www.duetdisplay.com)                                                   | App to use attached iOS device as screen                |
| [Fanny for macOS](https://www.fannywidget.com)                                        | Notification Center Widget/Menu Bar app to monitor fans |
| [Intel Power Gadget](https://software.intel.com/en-us/articles/intel-power-gadget-20) | Power usage monitoring tool                             |
| [\*iStat Menus](https://bjango.com/mac/istatmenus/)                                   | System monitor for the menubar                          |
| [LastPass](https://www.lastpass.com)                                                  | Password manager                                        |
| [Malwarebytes](https://www.malwarebytes.com)                                          | Malware detection software                              |
| [OmniDiskSweeper](https://www.omnigroup.com/more/)                                    | Disk cleaning application                               |
| [OverSight](https://objective-see.com/products/oversight.html)                        | Mic and webcam monitor                                  |
| [\*Stay](https://cordlessdog.com/stay/)                                               | Restores window positions                               |
| [TinkerTool](https://www.bresink.com/osx/TinkerTool.html)                             | Provides access to additional Mac settings              |

### Productivity

| Application                                                       | Description                             |
| ----------------------------------------------------------------- | --------------------------------------- |
| [Dropbox](https://www.dropbox.com/downloading)                    | Dropbox desktop sync app                |
| [Evernote](https://evernote.com/download)                         | Evernote notes manager                  |
| [FileZilla](https://filezilla-project.org)                        | FTP client                              |
| [Firefox](https://www.mozilla.org/en-US/firefox/)                 | Web browser                             |
| [Google Chrome](https://www.google.com/chrome/)                   | Web browser                             |
| [PDF Expert](https://pdfexpert.com)                               | PDF editor                              |
| [Signal](https://signal.org/download/)                            | Secure chat application                 |
| [Skype](https://www.skype.com/en/get-skype/)                      | Video conferencing application          |
| [TeamViewer](https://www.teamviewer.com/en/download/)             | Remote desktop application              |
| [VNC Viewer](https://www.realvnc.com/en/connect/download/viewer/) | Remote desktop application from RealVNC |

### Corporate/Subscription Applications

| Application                        | Description                          |
| ---------------------------------- | ------------------------------------ |
| Microsoft Office (from Office 365) | Office productivity suite            |
| Mimecast                           | Mail quarantine application          |
| Remotix                            | Remote desktop application           |
| Parallels                          | Virtual machine software for the Mac |

### Media

| Application                                                                                 | Description                                         |
| ------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| [Adobe Digital Negative Converter](https://helpx.adobe.com/photoshop/digital-negative.html) | Converts photos between various RAW formats and DNG |
| [Amazon Photos](https://www.amazon.com/b/?node=16409408011)                                 | Desktop app for syncing photos with Amazon          |
| [Amazon Music](https://www.amazon.com/Amazon-Music-Apps/b?ie=UTF8&node=2658409011)          | Desktop app for managing music from Amazon          |
| [\*MakeMKV](https://makemkv.com)                                                            | Video conversion tool                               |
| [Plex Media Player](https://www.plex.tv/media-server-downloads/#plex-app)                   | Player for streaming from a Plex server             |
| [VLC](https://www.videolan.org)                                                             | Video player                                        |

### Personal Applications

| Application                                                                             | Description                                         |
| --------------------------------------------------------------------------------------- | --------------------------------------------------- |
| [HDHomeRun](https://www.silicondust.com/products/software/)                             | Viewer for playing video from HDHomeRun devices     |
| [Infinity Dashboard](https://fiplab.com/apps/infinity-dashboard-for-mac)                | Customizable menubar tool                           |
| [Logos Bible Software](https://www.logos.com)                                           | Bible study software                                |
| [NETGEAR Switch Discovery Tool](https://www.netgear.com/support/product/GS116Ev2.aspx)  | Tool for discovering NETGEAR smart switches         |
| [SketchUp](https://www.sketchup.com)                                                    | 3D modeling application                             |
| [Synology Assistant](https://www.synology.com/en-us/support/download/DS1517+#utilities) | Application to help connect to Synology NAS devices |

## Visual Studio Code Extensions

- [Bracket Pair Colorizer](https://marketplace.visualstudio.com/items?itemName=CoenraadS.bracket-pair-colorizer)
- [CocoaPods Snippets](https://marketplace.visualstudio.com/items?itemName=Agenric.cocoapods-snippets)
- [Code Spell Checker](https://marketplace.visualstudio.com/items?itemName=streetsidesoftware.code-spell-checker)
- [Color Highlight](https://marketplace.visualstudio.com/items?itemName=naumovs.color-highlight)
- [Document This](https://marketplace.visualstudio.com/items?itemName=joelday.docthis)
- [EditorConfig for VS Code](https://marketplace.visualstudio.com/items?itemName=EditorConfig.EditorConfig)
- [GitLens](https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens)
- [Gradle Language Support](https://marketplace.visualstudio.com/items?itemName=naco-siren.gradle-language)
- [HTML Preview](https://marketplace.visualstudio.com/items?itemName=tht13.html-preview-vscode)
- [iOS Common Files](https://marketplace.visualstudio.com/items?itemName=Orta.vscode-ios-common-files)
- [Kotlin Language](https://marketplace.visualstudio.com/items?itemName=mathiasfrohlich.Kotlin)
- [markdownlint](https://marketplace.visualstudio.com/items?itemName=DavidAnson.vscode-markdownlint)
- [Path Intellisense](https://marketplace.visualstudio.com/items?itemName=christian-kohler.path-intellisense)
- [Prettier](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode)
- [React Native Tools](https://marketplace.visualstudio.com/items?itemName=vsmobile.vscode-react-native)
- [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client)
- [Rewrap](https://marketplace.visualstudio.com/items?itemName=stkb.rewrap)
- [TODO Highlight](https://marketplace.visualstudio.com/items?itemName=wayou.vscode-todo-highlight)
- [TSLint](https://marketplace.visualstudio.com/items?itemName=eg2.tslint)
- [Version Lens](https://marketplace.visualstudio.com/items?itemName=pflannery.vscode-versionlens)
- [VS Live Share Extension Pack](https://marketplace.visualstudio.com/items?itemName=MS-vsliveshare.vsliveshare-pack), includes:
  - [VS Live Share](https://marketplace.visualstudio.com/items?itemName=MS-vsliveshare.vsliveshare)
  - [VS Live Share Audio](https://marketplace.visualstudio.com/items?itemName=ms-vsliveshare.vsliveshare-audio)
  - [Team Chat: for Slack, Discord, Live Share](https://marketplace.visualstudio.com/items?itemName=karigari.chat)
- [vscode-icons](https://marketplace.visualstudio.com/items?itemName=robertohuertasm.vscode-icons)
- [Wallaby.js](https://marketplace.visualstudio.com/items?itemName=WallabyJs.wallaby-vscode)
- [yarn](https://marketplace.visualstudio.com/items?itemName=gamunu.vscode-yarn)

## Other Settings

| Command                                                                  | Description                               |
| ------------------------------------------------------------------------ | ----------------------------------------- |
| `defaults write com.apple.dt.Xcode ShowBuildOperationDuration -bool YES` | Shows how long it takes to build in Xcode |
