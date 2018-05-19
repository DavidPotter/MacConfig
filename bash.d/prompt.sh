#!/bin/bash -e

# Define colors to use in prompt.
# See https://misc.flogisoft.com/bash/tip_colors_and_formatting for details on colors in Bash.
txtred='\e[0;31m' # Red
txtgrn='\e[0;32m' # Green
txtylw='\e[0;33m' # Yellow
txtblu='\e[0;34m' # Blue
txtpur='\e[0;35m' # Purple
txtcyn='\e[0;36m' # Cyan
txtwht='\e[0;37m' # White
bldblk='\e[1;30m' # Black - Bold
bldred='\e[1;31m' # Red
bldgrn='\e[1;32m' # Green
bldylw='\e[1;33m' # Yellow
bldblu='\e[1;34m' # Blue
bldpur='\e[1;35m' # Purple
bldcyn='\e[1;36m' # Cyan
bldwht='\e[1;37m' # White
unkblk='\e[4;30m' # Black - Underline
undred='\e[4;31m' # Red
undgrn='\e[4;32m' # Green
undylw='\e[4;33m' # Yellow
undblu='\e[4;34m' # Blue
undpur='\e[4;35m' # Purple
undcyn='\e[4;36m' # Cyan
undwht='\e[4;37m' # White
bakblk='\e[40m'   # Black - Background
bakred='\e[41m'   # Red
badgrn='\e[42m'   # Green
bakylw='\e[43m'   # Yellow
bakblu='\e[44m'   # Blue
bakpur='\e[45m'   # Purple
bakcyn='\e[46m'   # Cyan
bakwht='\e[47m'   # White
txtrst='\e[0m'    # Text Reset

function __prepare_for_prompt() {
    # Configure the git-prompt script.
    local GIT_PROMPT_PATH="${HOME}/bin/git-prompt.sh"
    if [ -f "${GIT_PROMPT_PATH}" ]; then
        source "${GIT_PROMPT_PATH}"
        export GIT_PS1_SHOWDIRTYSTATE=1
        export GIT_PS1_SHOWSTASHSTATE=1
        export GIT_PS1_SHOWUNTRACKEDFILES=1
        export GIT_PS1_SHOWUPSTREAM="auto verbose"
    fi

    # Start the prompt by resetting colors and adding the current time.
    export __BASE_PS1="\[${txtrst}\][\t] "

    # # Add rvm version@gemset
    # if [[ -n "${rvm_path}" ]]; then
    #     function __my_rvm_ps1()
    #     {
    #         #[[ -z "$rvm_ruby_string" ]] && return
    #         if [[ -z "${rvm_gemset_name}" && "${rvm_sticky_flag}" -ne 1 ]]; then
    #             [[ "${rvm_ruby_string}" = "system" && ! -s "${rvm_path}/config/alias" ]] && return
    #             grep -q -F "default=${rvm_ruby_string}" "${rvm_path}/config/alias" && return
    #         fi
    #         local full=$(
    #             "${rvm_path}/bin/rvm-prompt" i v p g s |
    #             sed \
    #                 -e 's/jruby-jruby-/jruby-/' -e 's/ruby-//' \
    #                 -e 's/-head/H/' \
    #                 -e 's/-2[0-9][0-9][0-9]\.[0-9][0-9]//' \
    #                 -e 's/-@/@/' -e 's/-$//')
    #         [ -n "${full}" ] && echo "${full} "
    #     }
    # #	export PS1+="\[${txtred}\]"'$(__my_rvm_ps1)'
    # fi

    # Add user@host:path and current directory.
    export __BASE_PS1+="\[${txtgrn}\]\u@\h\[${txtrst}\]:\[${txtcyn}\]\w"

    # Add Git repo status info.
    if [ -f "${HOME}/bin/git-prompt.sh" ]; then
        export __BASE_PS1+="\[${txtylw}\]"'$(__git_ps1 " (%s)")'
    fi
}

function __prompt_command() {
    # Grab the exit code first before any commands are run.
    local EXIT_CODE="$?"

    # Append every line to history.
    # TODO: Is this necessary?
    history -a

    # Start with the base prompt.
    export PS1=${__BASE_PS1}

    # Add the exit code.
    if [ ${EXIT_CODE} -ne 0 ]; then
        # 38;5;240 is a somewhat dim gray color.
        export PS1+=" \[\e[38;5;240m\](${EXIT_CODE})\[${txtrst}\]"
    fi

    # Finish off the prompt.
    export PS1+="\[${txtrst}\]"' > '
}

__prepare_for_prompt
unset __prepare_for_prompt

PROMPT_COMMAND=__prompt_command
