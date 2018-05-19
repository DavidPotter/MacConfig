#!/bin/bash -e

function __configure_command_line_completion() {
    # Git
    local GIT_COMPLETION_PATH="${HOME}/bin/git-completion.bash"
    if [ -f "${GIT_COMPLETION_PATH}" ]; then
        source "${GIT_COMPLETION_PATH}"
    fi

    # Git-flow
    local GIT_FLOW_COMPLETION_PATH="${HOME}/bin/git-flow-completion.bash"
    if [ -f "${GIT_FLOW_COMPLETION_PATH}" ]; then
        source ${GIT_FLOW_COMPLETION_PATH}
    else
        echo "${GIT_FLOW_COMPLETION_PATH} not found."
    fi

    # npm
    if [ ! -z `which npm` ]; then
        source <(npm completion)
    fi

    # yarn
    local YARN_COMPLETION_PATH="${HOME}/src/external/yarn-completion/yarn-completion.bash"
    if [ -f "${YARN_COMPLETION_PATH}" ]; then
        source ${YARN_COMPLETION_PATH}
    #else
    #	echo "${YARN_COMPLETION_PATH} not found."
    fi

    # Install bash-completion to support other types of shell completion.
    local BASH_COMPLETION_PATH="$(brew --prefix)/etc/bash_completion"
    if [ -f "${BASH_COMPLETION_PATH}" ]; then
        source ${BASH_COMPLETION_PATH}
    fi

    # Only complete with directories when executing a directory-related command.
    complete -d cd mkdir rmdir
}

__configure_command_line_completion
unset __configure_command_line_completion
