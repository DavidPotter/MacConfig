#!/bin/sh -e

#
# install.sh
#   Creates symbolic links for files in this directory from the application
#   directory.

# Resolve this directory.  When sourced by the aggregator, our own directory is
# handed to us in MACCONFIG_APP_INSTALL_DIR (a sourced POSIX script can't find
# its own path).  Fall back to $0 when run standalone.
SCRIPT_DIR="${MACCONFIG_APP_INSTALL_DIR:-$(cd "$(dirname "$0")" > /dev/null && pwd)}"

# CREATE SYMBOLIC LINKS FOR CONFIG FILES
# Loop through the files in the local directory and create a symlink to
# each one from the Visual Studio Code settings directory.
#
# Bail out cleanly where VS Code's User directory doesn't exist (VS Code isn't
# installed on this machine) instead of letting `ln` fail on the first file
# with a raw, confusing error.
CODE_USER_DIR="$HOME/Library/Application Support/Code/User"
if [ ! -d "$CODE_USER_DIR" ]
then
	echo "Visual Studio Code: $CODE_USER_DIR does not exist (VS Code not installed?); skipping"
else
	find "$SCRIPT_DIR" -maxdepth 1 -type f -not -name 'install.sh' -not -name 'README*' | while read SRC
	do
		FILENAME="$(basename "$SRC")"
		DST="$CODE_USER_DIR/$FILENAME"
		create_link "$SRC" "$DST"
	done
fi
