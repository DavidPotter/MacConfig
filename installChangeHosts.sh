#!/bin/bash

function realpath()
{
	python -c 'import os,sys;print os.path.realpath(sys.argv[1])' "$@"
}

INSTALLSCRIPTLOC="$(realpath `dirname $BASH_SOURCE`)"

# Create an entry in the ~/Library/LaunchAgents directory to automatically execute
# the ChangeHosts script whenever a change occurs in the network configuration.
cat $INSTALLSCRIPTLOC/scripts/ChangeHosts.plist | sed 's#SCRIPTLOCATION#'$INSTALLSCRIPTLOC'/scripts#' > $HOME/Library/LaunchAgents/ChangeHosts.plist

echo '#'
echo "# `basename $BASH_SOURCE`:"
echo '# You must log out and back in again for the ChangeHosts script to take effect.'
echo '#'
