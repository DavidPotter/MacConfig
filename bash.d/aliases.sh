#!/bin/bash -e

# Change directory aliases.
alias ~='cd ~'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias home='cd ~'

# Directory listing aliases.
# -F = Display:
#      / after directory
#      * after executable
#      @ after symbolic link
#      = after socket
#      % after whiteout
#      | after FIFO
# -G = Colorized output.
# -h = Use unit suffixes to reduce the # of digits to 3 or less.
# -l = List in long format.
# -a = Include directory entries whose names begin with a dot.
alias d='ls -FGhl'
alias dir='ls -FGhl'
alias da='ls -aFGhl'
alias la='ls -aGhl'

# Display disk usage in a human-readable format.
alias du='du -h'

# Show files being deleted.
alias del='rm -v'
alias rm='rm -v'

# Rename like in Windows.
alias ren=mv

# Eject optical disk from the command line.
alias eject='drutil tray open'

# Ping only 4 times like in Windows.
alias ping4='ping -c4'

# Reveal files in finder instead of opening them.
alias reveal='open -R --'

# Show and hide hidden files in Finder.
alias showFiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder /System/Library/CoreServices/Finder.app'
alias hideFiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder /System/Library/CoreServices/Finder.app'

# Launch applications.
alias textedit='open -e'
alias filemerge='open /Applications/Xcode.app/Contents/Applications/FileMerge.app'

# Default editor.
# if [ -d /Applications/TextMate.app ]; then
# 	alias edit='open -a /Applications/TextMate.app'
# else
# 	echo 'TextMate is not installed.'
# fi
