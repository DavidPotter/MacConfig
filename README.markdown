# ~/bin/MacConfig

Files for configuring my Mac OS X boxes, including hidden dot files and scripts.  This repository is used to transfer changes back and forth between machines.

Inspired by https://github.com/markcarroll/dotfiles, https://github.com/jasoncodes/dotfiles, and https://github.com/jasoncodes/scripts.


## Installation
    bash < <( curl -sL http://github.com/DavidPotter/MacConfig/raw/master/install.sh )

Installing in this way will do the following:

* Clone this Git repository to ~/bin/MacConfig.
* Attempt to create a symbolic link for all the files in the dotfiles subdirectory in your root directory.

## What else you have to do

To take full advantage of these scripts, you also need to install the following packages:

* Git - This is installed with Xcode.  Go to the Downloads pane of the Preferences panel to do this.
* Git Completion (*) - This is located in the contrib directory of the git repository, which can be found at https://github.com/git/git.git.
* Git-Flow (*) - This can be found at https://github.com/nvie/gitflow.git.
* Git-Flow Completion (*) - This can be found at https://github.com/bobthecow/git-flow-completion.git.
* git wtf command - This can be found at git://gitorious.org/willgit/mainline.git/.
* Ruby - If you have Ruby installed additional features are added for editing and recognizing Ruby files.  Most of this is commented out as I don't currently use Ruby.

To install the starred items, you can execute the install-tools.sh script.

## What it gives you

profile:

* Sets the command line prompt to show:
  * The current time.
  * The current user and machine.
  * The current directory.
  * The current branch and status if in a directory that is a GIT repository.
* Sets TextMate as the default editor.
* Sets the default man pager to 'less'.
* Configures the command line history.
* Sets up GIT command line completion.
* Defines a number of useful aliases (dir, .., etc.)
* Defines a number of useful functions:
  * pman - Open man pages in Preview app.
  * cd_smburl - 'cd' into SMB URLs like this:  cd_smburl smb://host/share
  * mategem - Open a gem in TextMate.
  * gup - Update the current branch from the upstream branch. If there are uncommited changes, rebase them on top of the upstream changes.
  * dif - Compare two files using the selected diff application (p4merge).

inputrc:

* Up/down restricts history lookup (type some characters and it restricts to those commands that begin with those characters).
* Support Ctrl-left and right arrows for word moving.
* Support delete and insert keys.
