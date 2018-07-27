#!/bin/bash -e

# History configuration
export HISTSIZE=100000
export HISTFILESIZE=${HISTSIZE}
export HISTCONTROL=ignoredups      # Ignore duplicates in history
export HISTTIMEFORMAT='%Y-%m-%d %H:%M:%S  '

# Set history list to append to the history file when the shell exists, rather than overwrite.
shopt -s histappend
