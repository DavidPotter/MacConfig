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
#
# Each sub-installer is sourced inside its own subshell `( . "$SRC" )` rather
# than directly into this loop.  This loop runs under `set -e` (inherited from
# the top-level install.sh); sourcing a failing sub-installer directly here
# would abort THIS loop's subshell (the pipe from `find` forces one) the
# moment it failed, skipping every sub-installer that sorts after it
# alphabetically -- e.g. a missing app breaking an unrelated app's config.
# Wrapping the source in its own subshell contains that abort to just the one
# sub-installer; the `if` around it suspends `set -e` for the check (POSIX),
# so a nonzero exit here only logs a warning instead of taking down the loop.
find "$SCRIPT_DIR" -maxdepth 2 -type f -name 'install.sh' | while read SRC
do
    MACCONFIG_APP_INSTALL_DIR="$(cd "$(dirname "$SRC")" > /dev/null && pwd)"
    export MACCONFIG_APP_INSTALL_DIR

    # Derive the app's display name from its directory (e.g. "Cursor",
    # "VisualStudioCode") and export it so create_link can label its own
    # messages per-app instead of with the generic repo name.
    MACCONFIG_APP_NAME="$(basename "$MACCONFIG_APP_INSTALL_DIR")"
    export MACCONFIG_APP_NAME

    echo "--- INSTALL $MACCONFIG_APP_NAME CONFIG ---"
    if ! ( . "$SRC" )
    then
        echo "install-application-configs: $SRC exited with an error; continuing with remaining app installers" >&2
    fi
done
