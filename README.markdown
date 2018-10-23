# ~/bin/MacConfig

Files for configuring my Mac OS X boxes, including hidden dot files and
scripts. This repository is used to transfer changes back and forth between
machines.

Inspired by [Mark Carroll's dotfiles](https://github.com/markcarroll/dotfiles)
and Jason Weathered's [dotfiles](https://github.com/jasoncodes/dotfiles) and
[scripts](https://github.com/jasoncodes/scripts).

## Installation

```bash
bash < <( curl -sL http://github.com/DavidPotter/MacConfig/raw/master/install.sh )
```

Installing in this way will do the following:

- Clone this Git repository to ~/bin/MacConfig.
- Attempt to create a symbolic link for all the files in the dotfiles
  subdirectory in your root directory.

## What else you have to do

To take full advantage of these scripts, you also need to install the
following packages:

| Tool                     | Description                                                                                                                                                   |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Git                      | This is installed with Xcode. Go to the Downloads pane of the Preferences panel to do this.                                                                   |
| Git Completion (\*)      | Located in the [contrib directory of the git repository](https://github.com/git/git.git).                                                                     |
| Git-Flow (\*)            | [Git extensions](https://github.com/nvie/gitflow) to provide high-level repository operations for Vincent Driessen's branching model.                         |
| Git-Flow Completion (\*) | [Command line completion](https://github.com/bobthecow/git-flow-completion.git) for Git-Flow.                                                                 |
| Ruby                     | If you have Ruby installed additional features are added for editing and recognizing Ruby files. Most of this is commented out as I don't currently use Ruby. |

To install the starred items, you can execute the install-tools.sh script.

## What It Gives You

### profile

- Sets the command line prompt to show:
  - The current time
  - The current user and machine
  - The current directory
  - The current branch and status if in a directory that is a GIT repository
- Sets TextMate as the default editor
- Sets the default man pager to 'less'
- Configures the command line history
- Sets up GIT command line completion
- Defines a number of useful aliases (dir, .., etc.)
- Defines a number of useful functions:

| Function  | Description                                                     |
| --------- | --------------------------------------------------------------- |
| pman      | Open man pages in Preview app                                   |
| cd_smburl | 'cd' into SMB URLs like this: cd_smburl smb://host/share        |
| mategem   | Open a gem in TextMate.                                         |
| dif       | Compare two files using the selected diff application (p4merge) |

### inputrc

- Up/down restricts history lookup (type some characters and it restricts to
  those commands that begin with those characters)
- Support Ctrl-left and right arrows for word moving
- Support delete and insert keys

## Packages to Install

[Homebrew](https://brew.sh/) is the first thing to install. Homebrew is a
package manager for installing other packages.

Once you've installed Homebrew, you may want to install the following
packages. You will install these using the syntax:

```bash
brew install <package>
```

| Tool                                                                                 | Description                                                               |
| ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------- |
| [bash-completion](https://github.com/scop/bash-completion)                           | Command-line completion for bash (Bourne Again Shell)                     |
| [carthage](https://github.com/Carthage/Carthage)                                     | Dependency manager (use CocoaPods instead if you can)                     |
| [cocoapods](https://cocoapods.org/)                                                  | Dependency manager for for Swift and Objective-C Cocoa projects           |
| [dos2unix](https://linux.die.net/man/1/dos2unix)                                     | Convert line endings in a file from CR/LF (Windows) to just LF (Unix/Mac) |
| [gdub](https://github.com/dougborg/gdub)                                             | Simple command-line tool for running Gradle or the Gradle wrapper script  |
| [gradle](https://gradle.org/)                                                        | Build tool                                                                |
| [node](https://nodejs.org/)                                                          | (Node.js) a JavaScript runtime                                            |
| [swiftlint](https://github.com/realm/SwiftLint)                                      | A tool to enforce Swift style and conventions                             |
| [tree](https://rschu.me/list-a-directory-with-tree-command-on-mac-os-x-3b2d4c4a4827) | Command line tool to display a directory tree hierarchically              |
| [unix2dos](https://linux.die.net/man/1/unix2dos)                                     | Convert line endings in a file from LF (Unix/Mac) to CR/LF (Windows)      |
| [yarn](https://yarnpkg.com/en/)                                                      | Dependency management for node.js projects                                |

## Terminal

Do this to support the Home and End keys in Terminal:

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
- [Rewrap](https://marketplace.visualstudio.com/items?itemName=stkb.rewrap)
- [TODO Highlight](https://marketplace.visualstudio.com/items?itemName=wayou.vscode-todo-highlight)
- [TSLint](https://marketplace.visualstudio.com/items?itemName=eg2.tslint)
- [Version Lens](https://marketplace.visualstudio.com/items?itemName=pflannery.vscode-versionlens)
- [VS Live Share](https://marketplace.visualstudio.com/items?itemName=MS-vsliveshare.vsliveshare)
- [vscode-icons](https://marketplace.visualstudio.com/items?itemName=robertohuertasm.vscode-icons)
- [Wallaby.js](https://marketplace.visualstudio.com/items?itemName=WallabyJs.wallaby-vscode)
- [yarn](https://marketplace.visualstudio.com/items?itemName=gamunu.vscode-yarn)

## Other Settings

Here are other changes you will want to make to settings that are not exposed through the UI.

| Command                                                                  | Description                               |
| ------------------------------------------------------------------------ | ----------------------------------------- |
| `defaults write com.apple.dt.Xcode ShowBuildOperationDuration -bool YES` | Shows how long it takes to build in Xcode |
