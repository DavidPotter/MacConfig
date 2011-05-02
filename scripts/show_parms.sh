#!/bin/bash

function realpath()
{
	python -c 'import os,sys;print os.path.realpath(sys.argv[1])' "$@"
}

# Show parameters passed to a script.

echo
echo '# arguments called with ($@) -->  '"$@"
echo '# $1 -------------------------->  '"$1"
echo '# $2 -------------------------->  '"$2"
echo '# path to me ($0) ------------->  '"$0"
echo '# parent path (${0%/*}) ------->  '"${0%/*}"
echo '# my name (${0##*/}) ---------->  '"${0##*/}"
echo '# $BASH_SOURCE ---------------->  '"$BASH_SOURCE"
echo '# Full script path ------------>  '"$(realpath $BASH_SOURCE)"
echo
