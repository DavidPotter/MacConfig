#!/bin/zsh

#-----------------------------------------------------------------------------
# Prompt (the zsh analog of bash.d/prompt.sh).
#
# bash builds PS1 imperatively in a PROMPT_COMMAND hook so it can read $? and
# conditionally append the exit code.  zsh does not need a hook: prompt escapes
# read the shell state at display time.  A single static PROMPT string with the
# PROMPT_SUBST option (for the $(__git_ps1) command substitution) and the
# %(?..) conditional (for the exit code) reproduces the bash prompt exactly.
#
# bash escape        zsh escape   meaning
# -----------        ----------   -------
# \t                 %*           current time, HH:MM:SS
# \u@\h              %n@%m         user@host
# \w                 %~           cwd, with ~ for $HOME
# \[\e[0;32m\]       %F{green}     set foreground color / %f resets it
# \[\e[38;5;240m\]   %F{240}       dim gray (256-color palette)
#-----------------------------------------------------------------------------

# Allow $(...) command substitution to run every time the prompt is drawn, so
# __git_ps1 re-evaluates in the current directory on each command.
setopt PROMPT_SUBST

# Configure the git-prompt script (git-prompt.sh is already dual bash/zsh).
GIT_PROMPT_PATH="${HOME}/bin/git-prompt.sh"
if [ -f "${GIT_PROMPT_PATH}" ]; then
    source "${GIT_PROMPT_PATH}"
    export GIT_PS1_SHOWDIRTYSTATE=1
    export GIT_PS1_SHOWSTASHSTATE=1
    export GIT_PS1_SHOWUNTRACKEDFILES=1
    export GIT_PS1_SHOWUPSTREAM="auto verbose"
fi
unset GIT_PROMPT_PATH

# Build the prompt piece by piece so it stays readable:
#   %f              reset any inherited color
#   [%*]            time in brackets
#   %F{green}%n@%m  user@host in green
#   %f:             reset, then a literal colon
#   %F{cyan}%~      cwd in cyan
#   git segment     yellow " (branch state)" via __git_ps1, only in a repo
#   exit-code       %(?..X) prints X only when $? is non-zero: a dim-gray
#                   "(code)".  The closing paren of the (code) literal must be
#                   written %) so it is not read as the end of the %(...)
#                   conditional.
#   %f >            reset color, then the " > " command separator
PROMPT='%f[%*] %F{green}%n@%m%f:%F{cyan}%~'
if [ -f "${HOME}/bin/git-prompt.sh" ]; then
    PROMPT+='%F{yellow}$(__git_ps1 " (%s)")'
fi
PROMPT+='%(?.. %F{240}(%?%)%f)'
PROMPT+='%f > '
