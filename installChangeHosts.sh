#!/bin/bash

#
# installChangeHosts.sh
#   Partially configures the system to execute the ChangeHosts script whenever
#   a network configuration change occurs.  This script swaps the file pointed
#   at by the /etc/hosts symbol link file to allow per-network changes to be
#   made to the system's hosts file.
#
# Possible improvements:
#  - Get the user's domain name and username and replace it in the plist file.
#  - Create the symbolic link from /etc/hosts.

# Function to construct the canonical full path for a path.
function realpath()
{
	python -c 'import os,sys;print os.path.realpath(sys.argv[1])' "$@"
}

INSTALLSCRIPTLOC="$(realpath `dirname $BASH_SOURCE`)"

# Create an entry in the ~/Library/LaunchAgents directory to automatically execute
# the ChangeHosts script whenever a change occurs in the network configuration.
cat $INSTALLSCRIPTLOC/scripts/ChangeHosts.plist | sed 's#SCRIPTLOCATION#'$INSTALLSCRIPTLOC'/scripts#' > $HOME/Library/LaunchAgents/ChangeHosts.plist

# Mark the ChangeHosts script as executable.
chmod 755 $INSTALLSCRIPTLOC/scripts/ChangeHosts

# Execute the ChangeHosts file for the first time.
source $INSTALLSCRIPTLOC/scripts/ChangeHosts

echo '#'
echo "# `basename $BASH_SOURCE`:"
echo '# Execute the following command:'
echo '#'
echo '#   ln -sf $INSTALLSCRIPTLOC/scripts/hostinfo/hosts /etc/hosts'
echo '#'
echo '# This command creates a symbolic link from /etc/hosts to the hosts file'
echo '# created by the ChangeHosts script.  You may need to execute this with sudo.'
echo '#'
echo '# For more details, see $INSTALLSCRIPTLOC/scripts/ChangeHosts.  This script'
echo '# creates a symbolic link in $INSTALLSCRIPTLOC/scripts/hostinfo for a hosts'
echo '# file that can be pointed to by the system hosts file.  This script will get'
echo '# executed automatically whenever there is a network change due to the'
echo '# ChangeHosts.plist file that was created in the ~/Library/LaunchAgents'
echo '# directory by this install script.'
echo '#'
echo '# This is necessary as changing the hosts file in /etc cannot be automated'
echo '# without sudo access.'
echo '#'
