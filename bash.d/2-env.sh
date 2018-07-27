#!/bin/bash -e

# Set the colors of a directory listing.
# Colors:
#   a black     d brown     g cyan
#   b red       e blue      h light grey
#   c green     f magenta   x default color
# Positions:
#   Directory
#   Symbolic link - special kind of file that contains reference to another file or directory
#   Socket        - special kind of file used for inter-process communication
#   Pipe          - special file that connects the output of one process to the input of another
#   Executable
#   Block special     - A kind of device file
#   Character special - A kind of device file
#   Executable with setuid bit set
#   Executable with setgid bit set
#   Directory writable to others with sticky bit - only owner can rename or delete files
#   Directory writable to others without sticky bit - any user with write and execution permissions can rename or delete files
function __setLsColors() {
    c01='gx' # directory            - cyan
    c02='Cx' # symbolic link        - bold green
    c03='Fx' # socket               - bold magenta
    c04='fx' # pipe                 - magenta
    c05='hx' # executable           - light grey
    c06='eg' # block special        - blue w/cyan background
    c07='ed' # character special    - blue w/brown background
    c08='Hx' # executable/setuid    - bold light grey
    c09='Hx' # executable/setgid    - bold light grey
    c10='Gx' # directory w/sticky   - bold cyan
    c11='Gx' # directory w/o sticky - bold cyan
    export LSCOLORS="${c01}${c02}${c03}${c04}${c05}${c06}${c07}${c08}${c09}${c10}${c11}"
}
__setLsColors
unset __setLsColors

# Set the default editor to TextMate.
# export EDITOR=/usr/local/bin/mate
# export P4EDITOR="/usr/local/bin/mate -w"

# Set the default man pager to less with the following options:
# -F = Display and then exit if only a single page.
# -i = Ignore case on searches unless an uppercase letter is specified.
# -s = Squeeze multiple blank lines into a single blank line.
export PAGER='less -Fis'

export JAVA_HOME="$(/usr/libexec/java_home -v '1.8*')"

export ANDROID_SDK_ROOT=${HOME}/Library/Android/sdk

# If TextMate is available and we're in Terminal.app...
# TODO: Is this still necessary?
if [ "$TERM_PROGRAM" == "Apple_Terminal" -a -x "`which mate`" ]; then
    export LESSEDIT='mate -l %lm %f' # press V in less to edit the file in TextMate
fi
