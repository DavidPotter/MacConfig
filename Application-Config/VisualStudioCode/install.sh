#!/bin/bash -e

#
# install.sh
#   Creates symbolic links for files in this directory from the application
#   directory.

pushd "$(dirname $BASH_SOURCE)" > /dev/null
SCRIPT_DIR="$(pwd)"
popd > /dev/null

# CREATE SYMBOLIC LINKS FOR CONFIG FILES
# Loop through the files in the local directory and create a symlink to
# each one from the Visual Studio Code settings directory.
find $SCRIPT_DIR -maxdepth 1 -type f -not -name 'install.sh' -not -name 'README*' | while read SRC
do
	FILENAME="$(basename $SRC)"
	DST="$HOME/Library/Application Support/Code/User/$FILENAME"
	create_link "$SRC" "$DST"
done
