#!/bin/sh -e

# lpass-add-sshkey.sh
#   Adds an SSH key passphrase to LastPass.  Prompts silently for the passphrase, which can be empty.
#
# Parameters:
#   $1 - Name to give the key in LastPass.
#   $2 - Hostname for use with key.
#   $3 - Name of the file in the ~/.ssh directory.  Prompts if not specified.

__add_passphrase_to_lastpass() {
    local NAME_PARAM="$1"
    local HOSTNAME_PARAM="$2"
    local FILE_PARAM="$3"

    # Prompt for a name.  (POSIX `read` has no `-p`; print the prompt first.)
    local NAME
    printf '%s' "Name of the key in LastPass [${NAME_PARAM}]: "
    read NAME
    if [ -z "${NAME}" ]; then
        NAME="${NAME_PARAM}"
    fi
    if [ -z "${NAME}" ]; then
        echo "No name specified, key not added to LastPass."
        return 1
    fi

    # Prompt for a hostname.
    local HOSTNAME
    printf '%s' "Hostname for the key [${HOSTNAME_PARAM}]: "
    read HOSTNAME
    if [ -z "${HOSTNAME}" ]; then
        HOSTNAME="${HOSTNAME_PARAM}"
    fi
    if [ -z "${HOSTNAME}" ]; then
        echo "No hostname specified, key not added to LastPass."
        return 1
    fi

    # Prompt for a file.
    local FILE
    if [ -z "${FILE_PARAM}" ]; then
        FILE_PARAM="id_rsa"
    fi
    printf '%s' "File name [${FILE_PARAM}]: "
    read FILE
    if [ -z "${FILE}" ]; then
        FILE="${FILE_PARAM}"
    fi
    FILE="$HOME/.ssh/${FILE}"

    # Verify the private key file exists.
    if [ ! -f ${FILE} ]; then
        echo "Private key file ${FILE} not found"
        return 1
    fi

    # Verify the public key file exists.
    if [ ! -f ${FILE}.pub ]; then
        echo "Public key file ${FILE}.pub not found"
        return 1
    fi

    # Prompt for the passphrase.  POSIX `read` has no silent (`-s`) mode, so
    # disable terminal echo with `stty` around the read and restore it after
    # (also on interrupt, via the trap) so a Ctrl-C can't leave echo off.
    # The `|| :` on each `stty` keeps a non-terminal stdin (where `stty` exits
    # non-zero) from tripping `set -e` -- bash's `read -s` never aborted on a
    # pipe, and this preserves that.
    local PASSPHRASE
    printf '%s' "SSH passphrase: "
    trap 'stty echo 2>/dev/null; trap - INT; return 1' INT
    stty -echo 2>/dev/null || :
    read PASSPHRASE
    stty echo 2>/dev/null || :
    trap - INT
    echo ""
    if [ -z "${PASSPHRASE}" ]; then
        local USE_NO_PASSPHRASE
        printf '%s' "Use no passphrase? [Y/n]"
        read USE_NO_PASSPHRASE
        if [ "${USE_NO_PASSPHRASE}" = "n" ]; then
            echo "No passphrase specified, key not added to LastPass."
            return 1
        fi
    fi

    # Add the key to LastPass.  Use printf (not echo) for the name: /bin/sh's
    # echo interprets backslash escapes, which would mangle a name containing
    # one; bash's echo (the original shebang) did not.
    printf 'Adding %s to LastPass...\n' "${NAME}"
    printf \
        "Private Key: %s\nPublic Key: %s\nPassphrase: %s\nHostname: %s" \
        "$(cat ${FILE})" "$(cat ${FILE}.pub)" "${PASSPHRASE}" "${HOSTNAME}" | \
        lpass add --non-interactive --sync=now "${NAME}" --note-type=ssh-key

    # Display the key from LastPass.
    lpass show "${NAME}"
}

__add_passphrase_to_lastpass "$1" "$2" "$3"

# gyDkJ*17MOL8
