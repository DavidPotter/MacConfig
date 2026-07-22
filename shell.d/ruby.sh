#!/bin/bash -e

# Enable rvm if available.
if [[ -s "${HOME}/.rvm/scripts/rvm" ]]; then
    source "${HOME}/.rvm/scripts/rvm"
fi

# TODO: Should this move to completion.sh or should that file be broken up?
[[ -n "${rvm_path}" ]] && [[ -r "${rvm_path}/scripts/completion" ]] && source "${rvm_path}/scripts/completion"

export rvm_pretty_print_flag=1

# # mategem makes it easy to open a gem in TextMate
# # original src: <http://effectif.com/articles/opening-ruby-gems-in-textmate>
# function mategem()
# {
# 	local GEM="$1"
# 	if [ -z "${GEM}" ]; then
# 		echo "Usage: mategem <gem>" 1>&2
# 		false
# 	else
# 		gem_bin_path > /dev/null # init path
# 		mate "$(gem_bin_path)/gems/${GEM}"
# 	fi
# }
# _mategem()
# {
# 	local curw
# 	COMPREPLY=()
# 	curw=${COMP_WORDS[COMP_CWORD]}
# 	gem_bin_path > /dev/null # init path
# 	local gems="$(gem_bin_path)/gems"
# 	COMPREPLY=($(compgen -W '$(ls $gems)' -- ${curw}));
# 	return 0
# }
# complete -F _mategem -o dirnames mategem
