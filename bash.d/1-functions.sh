#!/bin/bash -e

#-----------------------------------------------------------------------------
# Returns whether an array contains a specified element.
#  $1 - Element to search for
#  $2 - Array (e.g. "${array[@]}")
#-----------------------------------------------------------------------------

function elementIn() {
    local element match="$1"
    shift
    for element; do [[ "${element}" == "${match}" ]] && return 0; done
    return 1
}

#-----------------------------------------------------------------------------
# Returns whether a specified entry is present in the PATH variable.
#  $1 - Path entry to search the PATH variable for.
#-----------------------------------------------------------------------------

function pathContainsEntry() {
    # Split path entries into array.
    local array
    local IFS=:
    set -f # Disable glob expansion
    array=( $PATH )
    set +f

    # Find new entry in array.
    if elementIn "$1" "${array[@]}"; then
        return 0
    fi
    return 1
}

#-----------------------------------------------------------------------------
# Adds a string to PATH if the directory entry exists.
#  $1 - Name of directory entry to add to the path.
#-----------------------------------------------------------------------------

function addToPathIfExists() {
    if [ -d "$1" ]; then
        if ! pathContainsEntry "$1"; then
            export PATH="${PATH}:$1"
        fi
    fi
}

#-----------------------------------------------------------------------------
# Changes the current directory to an ancestor directory n levels up.
#  $1 - Number of ancestor directors to traverse.  Defaults to 1.
#-----------------------------------------------------------------------------

function up() {
    local index=${1:-1} dot
    for ((;index;index--)); do
        dot=${dot}../
    done
    cd ${dot}
}

#-----------------------------------------------------------------------------
# Opens man pages in Preview.app.
#-----------------------------------------------------------------------------

function pman() {
    man -t "$@" | open -f -a /Applications/Preview.app;
}

#-----------------------------------------------------------------------------
# Creates a symbolic link if the destination doesn't exist or displays an
# error message detailing why it failed.
#
#  $1 - Source (file/directory to link to)
#  $2 - Destination (name of directory to link from)
#  $3 - Error message detail info (e.g. name of the root directory)
#-----------------------------------------------------------------------------

function create_link() {
    local SRC="$1"
    local DST="$2"

    if [ ! -e "${DST}" ]; then
        ln -sv "${SRC}" "${DST}"
    elif [ ! -L "${DST}" ] || [ "`readlink "${DST}"`" != "${SRC}" ]; then
        local PREFIX
        if [ -e "$3" ]; then
            PREFIX='ERROR:'
        else
            PREFIX="ERROR ($3):"
        fi
        echo -n "${PREFIX} ${DST} already exists" >&2
        if [ -L "${DST}" ]; then
            echo " (pointing to `readlink "${DST}"`)"
        else
            echo " (not a symlink)"
        fi
    fi
}

#-----------------------------------------------------------------------------
# Starts an Android emulator.
# Requires ANDROID_DEVICE and ANDROID_SDK_ROOT to be defined.
#-----------------------------------------------------------------------------

function startAndroid() {
    if [ -z "${ANDROID_DEVICE}" ]; then
        echo 'ANDROID_DEVICE not defined.'
        return
    fi
    if [ -z "${ANDROID_SDK_ROOT}" ]; then
        echo 'ANDROID_SDK_ROOT not defined.'
        return
    fi
    pushd "${ANDROID_SDK_ROOT}/emulator" > /dev/null 2>&1
    emulator -avd "${ANDROID_DEVICE}" > /dev/null 2>&1 &
    popd > /dev/null 2>&1
}

# # Compare two files using the selected diff application.
# dif()
# {
#   local DIFFPATH1
#   local DIFFPATH2
#   local DIFFPATH3

#   if [ ${1:0:1} == "/" ]; then
#       DIFFPATH1=$1
#   else
#       DIFFPATH1=$(pwd)/$1
#   fi

#   if [ ${2:0:1} == "/" ]; then
#       DIFFPATH2=$2
#   else
#       DIFFPATH2=$(pwd)/$2
#   fi

#   if [ -z ${3} ]; then
#       DIFFPATH3=
#   elif [ ${3:0:1} == "/" ]; then
#       DIFFPATH3=$3
#   else
#       DIFFPATH3=$(pwd)/$3
#   fi

#   /Applications/p4merge.app/Contents/Resources/launchp4merge ${DIFFPATH1} ${DIFFPATH2} ${DIFFPATH3}
# }

# function realpath()
# {
#   python -c 'import os,sys;print os.path.realpath(sys.argv[1])' "$@"
# }

# function first_file_match()
# {
#   local OP="$1"
#   shift
#   while [ $# -gt 0 ]
#   do
#       if [ $OP "$1" ]; then
#           echo "$1"
#           return 0
#       fi
#       shift
#   done
#   return 1
# }
