#!/bin/zsh

#-----------------------------------------------------------------------------
# Command-line completion (the zsh analog of bash.d/completion.sh).
#
# Unlike bash -- which sources hand-written *.bash completion scripts
# (git-completion.bash, npm completion, yarn-completion.bash, bash_completion)
# -- zsh ships a native completion system.  `compinit` autoloads completion
# functions found on $fpath, so git, npm, brew, etc. complete out of the box
# without sourcing anything.  Homebrew installs its zsh completion functions
# under $HOMEBREW_PREFIX/share/zsh/site-functions and `brew shellenv` adds that
# directory to $FPATH, so those are picked up automatically too.
#
# If you ever need a bash-only `complete` script, load bashcompinit after
# compinit (`autoload -Uz bashcompinit && bashcompinit`) and then `source` it.
#-----------------------------------------------------------------------------

# Defensively add Homebrew's completion directory to fpath in case this file is
# sourced in a shell where `brew shellenv` has not run.
if [ -n "${HOMEBREW_PREFIX}" ] && [ -d "${HOMEBREW_PREFIX}/share/zsh/site-functions" ]; then
    fpath=("${HOMEBREW_PREFIX}/share/zsh/site-functions" $fpath)
fi

# Initialize the completion system.  -U suppresses alias expansion while
# autoloading; -z selects zsh-style autoloading.  -i skips (rather than
# refusing) any completion directories Homebrew leaves group-writable, so the
# shell starts without an "insecure directories" prompt.
autoload -Uz compinit
compinit -i

# Complete case-insensitively (bash inputrc: completion-ignore-case on).
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Present ambiguous completions as a navigable, highlighted menu
# (richer than bash inputrc's show-all-if-ambiguous, which only lists them).
zstyle ':completion:*' menu select

# Colorize completion listings like `ls` does (bash inputrc: visible-stats on).
zstyle ':completion:*' list-colors ''

# Only complete directories for directory-related commands
# (the zsh-native replacement for bash's `complete -d cd mkdir rmdir`).
compdef _directories cd mkdir rmdir
