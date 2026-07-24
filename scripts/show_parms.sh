#!/bin/sh

# Show parameters passed to a script.
#
# Uses printf, not echo, for the value lines: /bin/sh's echo interprets
# backslash escapes, so an argument like 'a\tb' would come out mangled;
# bash's echo (the original shebang) left it literal.  printf '%s' keeps
# the bytes exactly as passed.

echo
printf '%s%s\n' '# arguments called with ($@) -->  ' "$*"
printf '%s%s\n' '# $1 -------------------------->  ' "$1"
printf '%s%s\n' '# $2 -------------------------->  ' "$2"
printf '%s%s\n' '# path to me ($0) ------------->  ' "$0"
printf '%s%s\n' '# parent path (${0%/*}) ------->  ' "${0%/*}"
printf '%s%s\n' '# my name (${0##*/}) ---------->  ' "${0##*/}"
printf '%s%s\n' '# Full script path ------------>  ' "$(realpath "$0")"
echo
