# ~/bin/MacConfig

Files for configuring my Mac OS X boxes, including hidden dot files and scripts.  This repository is used to transfer changes back and forth between machines.

Inspired by https://github.com/markcarroll/dotfiles, https://github.com/jasoncodes/dotfiles, and https://github.com/jasoncodes/scripts.


## Installation
    bash < <( curl -sL http://github.com/DavidPotter/MacConfig/raw/master/install.sh )

Installing in this way will do the following:
* Clone this Git repository to ~/bin/MacConfig.
* Attempt to create a symbol link for all the files in the dotfiles subdirectory in your root directory.
* Run the installChangeHosts.sh script to configure the ChangeHosts script.
