#!/bin/zsh

#-----------------------------------------------------------------------------
# Line-editor keybindings (the zsh analog of dotfiles/inputrc).
#
# inputrc configures GNU readline, which bash uses.  zsh has its own line
# editor (zle) and completely ignores inputrc, so every keybinding must be
# reconstructed here with `bindkey`.  The escape sequences below mirror the
# ones in dotfiles/inputrc so the keys behave identically in both shells.
#
# Note on WORDCHARS: this file deliberately does NOT change WORDCHARS, so word
# motion (Ctrl/Alt-arrow, ^W) uses zsh's default word definition.  zsh treats
# more punctuation as part of a word than readline does, so word jumps are
# coarser than in bash -- this is intentional, to learn the zsh defaults.
#-----------------------------------------------------------------------------

# Use Emacs-style keybindings (readline's default), so the familiar Ctrl-A /
# Ctrl-E / Ctrl-W chords work regardless of $EDITOR.
bindkey -e

#-----------------------------------------------------------------------------
# History search on the up/down arrows.
#
# Mirrors the inputrc history-search-backward / -forward bindings: with text
# already typed, the arrows walk only through history entries that begin with
# that text; with an empty line they behave like an ordinary history walk.
# (zsh's *-beginning-search-* widgets are the equivalent of readline's
# history-search-* -- they anchor the match to the start of the line.)
#-----------------------------------------------------------------------------

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey '\e[A' up-line-or-beginning-search       # Up
bindkey '\e[B' down-line-or-beginning-search      # Down
bindkey '\eOA' up-line-or-beginning-search        # Up   (application cursor keys)
bindkey '\eOB' down-line-or-beginning-search      # Down (application cursor keys)

#-----------------------------------------------------------------------------
# Word motion on Ctrl-arrow and Alt-arrow (mirrors inputrc forward-word /
# backward-word).  Which key triggers a word jump is set here; how much it
# jumps is governed by WORDCHARS, left at the zsh default (see note above).
#-----------------------------------------------------------------------------

bindkey '\e[1;5C' forward-word                    # Ctrl-Right
bindkey '\e[1;5D' backward-word                   # Ctrl-Left
bindkey '\e[5C' forward-word                      # Ctrl-Right (alt encoding)
bindkey '\e[5D' backward-word                     # Ctrl-Left  (alt encoding)
bindkey '\e\e[C' forward-word                     # Alt-Right
bindkey '\e\e[D' backward-word                    # Alt-Left

#-----------------------------------------------------------------------------
# Delete and Insert keys (mirrors inputrc delete-char / quoted-insert).
#-----------------------------------------------------------------------------

bindkey '\e[3~' delete-char                       # Delete
bindkey '\e[2~' quoted-insert                     # Insert

#-----------------------------------------------------------------------------
# Home and End jump to the start/end of the line.
# Terminals disagree on what these keys send, so bind every common variant:
#   \eOH  / \eOF   application cursor-key mode (SS3) -- what xterm-256color's
#                  terminfo reports for khome/kend
#   \e[H  / \e[F   normal cursor-key mode (CSI) -- what this repo's installer
#                  configures macOS Terminal.app to Send Text (see README)
#   \e[1~ / \e[4~  vt220-style terminals
#   \e[7~ / \e[8~  rxvt
#-----------------------------------------------------------------------------

bindkey '\e[1~' beginning-of-line
bindkey '\e[4~' end-of-line
bindkey '\e[7~' beginning-of-line
bindkey '\e[8~' end-of-line
bindkey '\e[H' beginning-of-line
bindkey '\e[F' end-of-line
bindkey '\eOH' beginning-of-line
bindkey '\eOF' end-of-line

#-----------------------------------------------------------------------------
# Space performs history expansion (mirrors inputrc's magic-space, which was
# inside the $if Bash block; zsh has the same widget).
#-----------------------------------------------------------------------------

bindkey ' ' magic-space
