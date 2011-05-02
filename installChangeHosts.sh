#!/bin/bash

INSTALLSCRIPTLOC="$(realpath `dirname $BASH_SOURCE`)"

# Create an entry in the ~/Library/LaunchAgents directory to automatically execute
# the ChangeHosts script whenever a change occurs in the network configuration.
cat $INSTALLSCRIPTLOC/scripts/ChangeHosts.plist | sed 's#SCRIPTLOCATION#'$INSTALLSCRIPTLOC'/scripts#' > $HOME/Library/LaunchAgents/ChangeHosts.plist

echo 'You must log out and back in again for the ChangeHosts script to take effect.'
