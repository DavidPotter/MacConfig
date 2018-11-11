#!/bin/bash -e

#
# install-application-config.sh
#   Executes all install.sh files below this directory to install application
#   configuration files.

pushd "$(dirname $BASH_SOURCE)" > /dev/null
SCRIPT_DIR="$(pwd)"
popd > /dev/null

# EXECUTE APPLICATION INSTALL SCRIPTS
# Loop through the files in subdirectories named install.sh and execute each
# one.
find $SCRIPT_DIR -maxdepth 2 -type f -name 'install.sh' | while read SRC
do
    source $SRC
done
