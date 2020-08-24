#!/bin/bash -e

# lpass-add-sshkey.sh
#   Adds an SSH key passphrase to LastPass.  Prompts silently for the passphrase, which can be empty.
#
# Parameters:
#   $1 - Name to give the key in LastPass.
#   $2 - Hostname for use with key.
#   $3 - Name of the file in the ~/.ssh directory.  Prompts if not specified.

function __add_passphrase_to_lastpass() {
    local NAME_PARAM="$1"
    local HOSTNAME_PARAM="$2"
    local FILE_PARAM="$3"

    # Prompt for a name.
    local NAME
    read -p "Name of the key in LastPass [${NAME_PARAM}]: " NAME
    if [ -z "${NAME}" ]; then
        NAME="${NAME_PARAM}"
    fi
    if [ -z "${NAME}" ]; then
        echo "No name specified, key not added to LastPass."
        return 1
    fi

    # Prompt for a hostname.
    local HOSTNAME
    read -p "Hostname for the key [${HOSTNAME_PARAM}]: " HOSTNAME
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
    read -p "File name [${FILE_PARAM}]: " FILE
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

    # Prompt for the passphrase.
    local PASSPHRASE
    read -s -p "SSH passphrase: " PASSPHRASE
    echo ""
    if [ -z "${PASSPHRASE}" ]; then
        local USE_NO_PASSPHRASE
        read -p "Use no passphrase? [Y/n]" USE_NO_PASSPHRASE
        if [ "${USE_NO_PASSPHRASE}" = "n" ]; then
            echo "No passphrase specified, key not added to LastPass."
            return 1
        fi
    fi

    # Add the key to LastPass.
    echo "Adding ${NAME} to LastPass..."
    printf \
        "Private Key: %s\nPublic Key: %s\nPassphrase: %s\nHostname: %s" \
        "$(cat ${FILE})" "$(cat ${FILE}.pub)" "${PASSPHRASE}" "${HOSTNAME}" | \
        lpass add --non-interactive --sync=now "${NAME}" --note-type=ssh-key

    # Display the key from LastPass.
    lpass show "${NAME}"
}

__add_passphrase_to_lastpass "$1" "$2" "$3"

# gyDkJ*17MOL8
