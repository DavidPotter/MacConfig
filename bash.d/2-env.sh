#!/bin/bash -e

# Set the colors of a directory listing.
# These colors look good on the Grass terminal theme.
#   Directory            = g:cyan
#   Symbolic link        = C:bold green
#   Socket               = F:bold magenta
#   Pipe                 = f:magenta
#   Executable           = h:light grey
#   Block special        = e:blue g:cyan background
#   Character special    = e:blue d:brown background
#   Executable/setuid    = H:bold light grey
#   Executable/setgid    = H:bold light grey
#   directory w/sticky   = G:bold cyan
#   directory w/o sticky = G:bold cyan
export LSCOLORS=gxCxFxfxhxegedHxHxGxGx

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
