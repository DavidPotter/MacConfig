# ~/bin/MacConfig

Files for configuring my Mac OS boxes, including hidden dot files and scripts.
This repository is used to transfer changes back and forth between machines.

Inspired by [Mark Carroll's dotfiles](https://github.com/markcarroll/dotfiles)
and Jason Weathered's [dotfiles](https://github.com/jasoncodes/dotfiles) and
[scripts](https://github.com/jasoncodes/scripts).

## Additional Repositories

This repository is just a beginning for configuring your Mac. Consider the following repositories as well.

- [Shared Config](https://gitlab.com/DavidPotter/SharedConfig)
  - Shared configuration across Mac and Windows.

## Prerequisites

The following packages are required before installing this set of tools:

- Xcode (this turns out to be optional)
- Xcode Command Line Tools
- Java JVM
- [Homebrew](https://brew.sh/) - package manager for installing other packages
- [Visual Studio Code](https://code.visualstudio.com)

Then install the [powershell](https://docs.microsoft.com/en-us/powershell/) package:

```bash
brew install powershell/tap/powershell
```

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
- Install `~/.bash_profile` and `~/.zshrc` as small local files that source
  the matching shared loader from the repo rather than symlinking them
  directly. This keeps machine-local lines that tool installers append to
  those rc files out of version control so they don't leak to other machines.

### Shell configuration layout

Both shells load from the same repo, sharing everything that is
shell-agnostic and differing only where bash and zsh genuinely diverge:

| Path                   | Loaded by     | Contents                                                                        |
| ---------------------- | ------------- | ------------------------------------------------------------------------------- |
| `shell.d/`             | bash **and** zsh | Portable core: functions, environment, `PATH`, aliases, Ruby. Sourced first. |
| `bash.d/`              | bash only     | Bash adapters: completion, history, prompt (readline/`PROMPT_COMMAND`).         |
| `zsh.d/`               | zsh only      | Zsh adapters: completion, history, prompt, and line-editor (`zle`) keybindings. |
| `dotfiles/bash_profile`| bash          | Loader: sources `shell.d/` then `bash.d/`, then `~/.bash.d/` machine-local.     |
| `dotfiles/zshrc`       | zsh           | Loader: sources `shell.d/` then `zsh.d/`, then `~/.shell.d/` and `~/.zsh.d/`.    |

Files in `shell.d/` and `bash.d/`/`zsh.d/` are numbered (`1-`, `2-`, ...) so
they load in a predictable order; the numbering matches across the shared and
per-shell directories.

> **Note:** `dotfiles/inputrc` configures GNU readline, which only bash uses.
> zsh ignores it entirely and reconstructs the equivalent keybindings in
> `zsh.d/4-zle.zsh`.

### Migrating an existing installation

Older installs symlinked `~/.bash_profile` straight into the repo. To convert
such a machine to the stub approach (preserving any lines tools appended and
reverting the tracked profile), run:

```bash
~/bin/MacConfig/scripts/migrate-bash-profile-stub
```

To have an existing `~/.zshrc` load the shared zsh configuration (the repo
loader is injected at the top, preserving your existing machine-local lines),
run:

```bash
~/bin/MacConfig/scripts/migrate-zshrc-stub
```

Both are safe to run repeatedly and leave a hand-written rc file's own
content untouched.

## What else you have to do

To take full advantage of these scripts, you also need to install the
following packages.

> The most convenient way to do this is by executing the **_install-tools.sh_** script.

| Tool                     | Description                                                                                                                                                   |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Git Completion (\*)      | Located in the [contrib directory of the git repository](https://github.com/git/git.git).                                                                     |
| Ruby                     | If you have Ruby installed additional features are added for editing and recognizing Ruby files. Most of this is commented out as I don't currently use Ruby. |

## What It Gives You

### profile (bash and zsh)

The bash loader (`dotfiles/bash_profile`) and zsh loader (`dotfiles/zshrc`)
both produce the same experience:

- Sets the command line prompt to show:
  - The current time
  - The current user and machine
  - The current directory
  - The current branch and status if in a directory that is a GIT repository
  - The exit code of the previous command, when it was non-zero
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

### Key bindings

Both shells get the same line-editing keys, configured for bash in
`dotfiles/inputrc` (GNU readline) and reconstructed for zsh in
`zsh.d/4-zle.zsh` (`zle`), since zsh ignores `inputrc`:

- Up/down restricts history lookup (type some characters and it restricts to
  those commands that begin with those characters)
- Support Ctrl-left and right arrows for word moving
- Support delete and insert keys
- Home and End jump to the start/end of the line

## System Configuration

The following commands should be executed from a bash command line to
configure the Mac for the user. [TODO: Consider moving to a script.]

### Change Screenshot Location

```sh
# Screenshots: Stop dumping them on the Desktop
mkdir -p ~/Screenshots
defaults write com.apple.screencapture location ~/Screenshots

# Screenshots as JPEG instead of huge PNGs
defaults write com.apple.screencapture type jpg
```

### Show Hidden Files in Finder

```sh
# Show hidden files in Finder
defaults.write com.apple.finder AppleShowAllFiles - bool true
killall Finder
```

### Speed up Dock Animation

```sh
# Speed up dock animation
defaults.write com.apple.dock autohide-time-modifier -float 0.3
killall Dock
```

## Packages and Applications to Install via Homebrew

[Homebrew](https://brew.sh/) is the next thing to install. Homebrew is a
package manager for installing other packages.

### Packages to Install

Once you've installed Homebrew, you may want to install the following
packages. You will install these using the syntax:

```bash
brew install <package>
```

| Tool                                                                                 | Description                                                                                   |
| ------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------- |
| [bash](http://git.savannah.gnu.org/cgit/bash.git/)                                   | Latest version of the Bourne Again SHell (see notes below)                                    |
| [bash-completion](https://github.com/scop/bash-completion)                           | Command-line completion for bash (Bourne Again Shell)                                         |
| [carthage](https://github.com/Carthage/Carthage)                                     | Dependency manager (use CocoaPods instead if you can)                                         |
| [cocoapods](https://cocoapods.org/)                                                  | Dependency manager for for Swift and Objective-C Cocoa projects                               |
| [dos2unix](https://linux.die.net/man/1/dos2unix)                                     | Converts line endings in a file from CR/LF (Windows) to just LF (Unix/Mac)                    |
| [gng](https://github.com/gdubw/gng)                                                  | Simple command-line tool for running Gradle or the Gradle wrapper script using a `gw` command |
| [gradle](https://gradle.org/)                                                        | Build tool                                                                                    |
| [node](https://nodejs.org/)                                                          | (Node.js) a JavaScript runtime                                                                |
| [n](https://github.com/tj/n)                                                         | Interactively manage node.js versions                                                         |
| [swiftlint](https://github.com/realm/SwiftLint)                                      | A tool to enforce Swift style and conventions                                                 |
| [tree](https://rschu.me/list-a-directory-with-tree-command-on-mac-os-x-3b2d4c4a4827) | Command line tool to display a directory tree hierarchically                                  |
| [unix2dos](https://linux.die.net/man/1/unix2dos)                                     | Converts line endings in a file from LF (Unix/Mac) to CR/LF (Windows)                         |
| [wget](https://www.gnu.org/software/wget/)                                           | Retrieves files from a web server                                                             |
| [yarn](https://yarnpkg.com/en/)                                                      | Dependency management for node.js projects                                                    |

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
| [react-native-debugger](https://github.com/jhen0409/react-native-debugger) | Standalone application for debugging React Native applications.       |
| [reactotron](https://github.com/infinitered/reactotron)                    | Desktop app for inspecting React JS and React Native projects         |
| [thaw](https://formulae.brew.sh/cask/thaw)                                 | Menu bar management tool ([website](https://github.com/stonerl/Thaw)) |

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

### Zsh

macOS uses zsh as the default login shell. This repo configures both shells
from a shared core (see [Shell configuration layout](#shell-configuration-layout)),
so you can run either one. To use zsh in Terminal, set the desired profile's
shell back to the default login shell (or point it explicitly at
`/bin/zsh`) instead of launching bash. `~/.zshrc` (installed by `install.sh`)
sources the repo's zsh loader, which brings up the same prompt, history,
completion, aliases, and key bindings as the bash configuration.

For a full walkthrough of moving from bash to zsh on a machine, see
[MIGRATION-zsh.md](MIGRATION-zsh.md).

### PowerShell

The PowerShell cask installs an application in the `Applications` directory
and also installs a command line tool in `/user/local/bin`.

To run PowerShell from the command line, execute the following command:

```shell
pwsh
```

## Terminal

### Home and End keys

These key bindings are now handled by the shell configuration itself:
`dotfiles/inputrc` (for bash) and `zsh.d/4-zle.zsh` (for zsh) bind Home and End
to jump to the start/end of the line, covering every common escape sequence
Terminal profiles send — including the `\e[1~` / `\e[4~` that macOS
Terminal.app sends by default. No manual per-profile key remapping is
required.

If you use a terminal that sends something unusual, you can still remap the
keys in the profile:

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

### Mac App Store Applications

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

| Application                                                        | Description                         |
| ------------------------------------------------------------------ | ----------------------------------- |
| [Cocoa Rest Client](http://mmattozzi.github.io/cocoa-rest-client/) | App for testing HTTP/REST endpoints |
| [iExplorer](https://macroplant.com)                                | Transfer utility for iOS devices    |
| \*[TextMate](https://macromates.com)                               | Text editor                         |

### Utilities

| Application                                                                           | Description                                              |
| ------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| [AccessMenuBarApps](http://www.ortisoft.de/en/accessmenubarapps/)                     | Gives access to all menu bar apps                        |
| [BoringNotch](https://theboring.name)                                                 | Makes the notch useful                                   |
| [Duet](https://www.duetdisplay.com)                                                   | App to use attached iOS device as screen                 |
| [Fanny for macOS](https://www.fannywidget.com)                                        | Notification Center Widget/Menu Bar app to monitor fans  |
| [GrandPerspective](https://grandperspectiv.sourceforge.net)                           | Disk space visualizer                                    |
| [Intel Power Gadget](https://software.intel.com/en-us/articles/intel-power-gadget-20) | Power usage monitoring tool                              |
| [\*iStat Menus](https://bjango.com/mac/istatmenus/)                                   | System monitor for the menubar                           |
| [Malwarebytes](https://www.malwarebytes.com)                                          | Malware detection software                               |
| [OmniDiskSweeper](https://www.omnigroup.com/more/)                                    | Disk cleaning application                                |
| [OverSight](https://objective-see.com/products/oversight.html)                        | Mic and webcam monitor                                   |
| [Say No To Notch](https://apps.apple.com/de/app/say-no-to-notch/id1639306886?mt=12)   | Moves the menubar down so menubar icons won't get hidden |
| [\*Stay](https://cordlessdog.com/stay/)                                               | Restores window positions                                |
| [TinkerTool](https://www.bresink.com/osx/TinkerTool.html)                             | Provides access to additional Mac settings               |

### Productivity

| Application                                           | Description                |
| ----------------------------------------------------- | -------------------------- |
| [PDF Expert](https://pdfexpert.com)                   | PDF editor                 |
| [TeamViewer](https://www.teamviewer.com/en/download/) | Remote desktop application |

### Corporate/Subscription Applications

| Application | Description                          |
| ----------- | ------------------------------------ |
| Mimecast    | Mail quarantine application          |
| Remotix     | Remote desktop application           |
| Parallels   | Virtual machine software for the Mac |

### Personal Applications

| Application                                                              | Description               |
| ------------------------------------------------------------------------ | ------------------------- |
| [Infinity Dashboard](https://fiplab.com/apps/infinity-dashboard-for-mac) | Customizable menubar tool |

### Music and Theater Applications

| Application   | Description |
| ------------- | ----------- |
| Ableton Live  |             |
| Ampado (lite) |             |
| Audacity      |             |
| Cog           |             |
| IINA          |             |
| Soundplant 50 |             |

### Theater Cueing Applications

| Application   | Description |
| ------------- | ----------- |
| MIX16 GO      |             |
| QLab          |             |
| QLC+          |             |
| Stage Traxx 3 |             |

## Other Settings

| Command                                                                  | Description                               |
| ------------------------------------------------------------------------ | ----------------------------------------- |
| `defaults write com.apple.dt.Xcode ShowBuildOperationDuration -bool YES` | Shows how long it takes to build in Xcode |
