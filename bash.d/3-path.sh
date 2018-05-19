#!/bin/bash -e

function __add_to_path() {
    # Add Xcode tools to the path.
    local local_XCRUN=$(which xcrun)
    if [ -f "${local_XCRUN}" ]; then
        addToPathIfExists "$(xcode-select --print-path)/usr/bin"
    fi

    # Add Visual Studio Code tools to the path.
    addToPathIfExists '/Applications/Visual Studio Code.app/Contents/Resources/app/bin'

    # Add Yarn to the path.
    if which yarn > /dev/null; then
        local local_YARN_DIR="$(yarn global bin)"
        addToPathIfExists "${local_YARN_DIR}"
    fi

    # Add Android directories to the path.
    addToPathIfExists "${ANDROID_SDK_ROOT}/emulator"
    addToPathIfExists "${ANDROID_SDK_ROOT}/tools"
    addToPathIfExists "${ANDROID_SDK_ROOT}/platform-tools"

    # Add the profile bin directory to the path.
    addToPathIfExists "${HOME}/bin"
}

__add_to_path
unset __add_to_path
