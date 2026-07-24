#!/bin/sh -e

#
# install-application-config.sh
#   Executes all install.sh files below this directory to install application
#   configuration files.

# Resolve this directory.  This file is normally SOURCED by the top-level
# install.sh, which exports MACCONFIG_APP_CONFIGS_DIR so we know where we live
# (a sourced POSIX script can't discover its own path -- $0 is the executor and
# bash's $BASH_SOURCE isn't portable).  Fall back to $0 when run standalone.
if [ -n "${MACCONFIG_APP_CONFIGS_DIR:-}" ]
then
    SCRIPT_DIR="$MACCONFIG_APP_CONFIGS_DIR"
else
    SCRIPT_DIR="$(cd "$(dirname "$0")" > /dev/null && pwd)"
fi

# EXECUTE APPLICATION INSTALL SCRIPTS
# Loop through the files in subdirectories named install.sh and execute each
# one.  Each sub-installer is sourced (so it inherits create_link); we export
# its own directory in MACCONFIG_APP_INSTALL_DIR first so it, too, can find its
# files without relying on $BASH_SOURCE.
find "$SCRIPT_DIR" -maxdepth 2 -type f -name 'install.sh' | while read SRC
do
    MACCONFIG_APP_INSTALL_DIR="$(cd "$(dirname "$SRC")" > /dev/null && pwd)"
    export MACCONFIG_APP_INSTALL_DIR
    . "$SRC"
done
