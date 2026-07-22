#!/bin/zsh

#-----------------------------------------------------------------------------
# History configuration (the zsh analog of bash.d/history.sh).
#-----------------------------------------------------------------------------

# Where history is saved, and how many entries to keep in memory (HISTSIZE)
# and on disk (SAVEHIST).  Matches bash's HISTSIZE/HISTFILESIZE of 100000.
HISTFILE="${HOME}/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

# Record each command with a timestamp so `history` can show when it ran
# (the analog of bash's HISTTIMEFORMAT).
setopt EXTENDED_HISTORY

# Do not record a command that duplicates the previous one
# (the analog of bash's HISTCONTROL=ignoredups).
setopt HIST_IGNORE_DUPS

# Strip superfluous blanks from each command line before saving it.
setopt HIST_REDUCE_BLANKS

# Append to the history file rather than overwriting it (bash: shopt -s
# histappend).  Implied by SHARE_HISTORY, but stated explicitly for clarity.
setopt APPEND_HISTORY

# Live shared history: write each command to the history file as it is entered
# and re-read new entries from other sessions, so a command run in one terminal
# is immediately available in another.  This is opt-in (not a zsh default);
# bash can only approximate it by forcing history -a/-c/-r on every prompt.
setopt SHARE_HISTORY
