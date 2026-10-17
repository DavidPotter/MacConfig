#!/bin/sh

# NOTE: no `set -e` here.  This script is SOURCED (it uses a top-level `return`,
# and the install.sh final instructions run `source install-tools.sh`), so any
# `set -e` would turn on errexit in the caller's interactive shell and leave it
# on afterward.  The old `#!/bin/bash -e` shebang was silently ignored when
# sourced, so errexit was never actually in effect -- preserve that.

#
# install-tools.sh
#   Installs the minimum set of tools wanted on any machine by performing
#   the following steps:
#   - Installs Homebrew (if not already installed).
#   - Installs Python by running install-python.sh (uv-managed).
#   Installs the Git helpers by performing following steps:
#   - Clones repositories:
#     - Git source to ~/src/external/git.
#   - Creates symbolic links:
#     - git-completion
#   Installs git-up.
#   Installs RVM and Ruby.
#

###############################################################################
# Homebrew
###############################################################################

# Locate Homebrew.  It may be installed without being on PATH yet (fresh
# machine, or a shell that has not loaded the profile), so check the standard
# locations too: /opt/homebrew (Apple silicon) and /usr/local (Intel).
find_brew()
{
	BREW_BIN=
	for BREW_CANDIDATE in "$(command -v brew)" /opt/homebrew/bin/brew /usr/local/bin/brew; do
		if [ -n "$BREW_CANDIDATE" ] && [ -x "$BREW_CANDIDATE" ]; then
			BREW_BIN="$BREW_CANDIDATE"
			break
		fi
	done
	unset BREW_CANDIDATE
}

find_brew
if [ -z "$BREW_BIN" ]; then
	echo '--'
	echo '--> Installing Homebrew...'
	echo 'You may be prompted for your admin password to allow Homebrew to be installed.'
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	find_brew
fi
unset -f find_brew

if [ -z "$BREW_BIN" ]; then
	echo '** Failed to install Homebrew. Aborting.'
	unset BREW_BIN
	return
fi
echo "[Homebrew is $BREW_BIN]"

# Put Homebrew on PATH for the rest of this session.  Same guard as
# dotfiles/zshrc: if the profile already ran `brew shellenv`, don't run it again
# (it would re-prepend Homebrew's directories and reorder PATH).
if [ -z "${HOMEBREW_PREFIX}" ]; then
	eval "$("$BREW_BIN" shellenv)"
fi
unset BREW_BIN

###############################################################################
# Python
###############################################################################

# install-python.sh installs uv with Homebrew and uses it to install Python.  It
# is run as a child process (not sourced) so its working variables don't leak
# into this interactive shell and so it can also be run on its own later to move
# to a newer Python.  It needs no PATH changes of its own: ~/.local/bin (where
# uv puts `python`/`python3`) is put at the front of PATH by shell.d/3-path.sh.
MACCONFIG_DIR="$HOME/bin/MacConfig"
if [ -f "$MACCONFIG_DIR/install-python.sh" ]; then
	echo '--'
	echo '--> Installing Python (via uv)...'
	sh "$MACCONFIG_DIR/install-python.sh"
	# ~/.local/bin may not have existed when this shell started, so put it at
	# the front of PATH now (ahead of /usr/bin's python3 stub), the same way
	# shell.d/3-path.sh does for every new shell.
	if command -v prependToPathIfExists > /dev/null 2>&1; then
		prependToPathIfExists "$HOME/.local/bin"
	elif [ -d "$HOME/.local/bin" ]; then
		PATH="$HOME/.local/bin:$PATH"
		export PATH
	fi
else
	echo "** $MACCONFIG_DIR/install-python.sh not found. Skipping Python."
fi
unset MACCONFIG_DIR

# Find the directory containing Git.
if [ -f /usr/bin/git ]; then
	GIT_DIR=/usr/bin
elif [ -f /usr/local/bin/git ]; then
	GIT_DIR=/usr/local/bin
else
	echo '** Git not installed yet. Aborting.'
	return
fi
echo "[Git is in $GIT_DIR]"

###############################################################################
# Git
###############################################################################

# Clone the Git source if not already present.
LOCAL_REPO_DIR="$HOME/src/external/git"
REMOTE_REPO='https://github.com/git/git.git'
if [ ! -d $LOCAL_REPO_DIR ]; then
	echo '--'
	echo "--> Cloning git to $LOCAL_REPO_DIR..."
	git clone $REMOTE_REPO $LOCAL_REPO_DIR
fi
if [ ! -d $LOCAL_REPO_DIR ]; then
	echo '** Failed to clone git. Aborting.'
	return
fi

# Update the git repository.
echo '--'
echo '--> Pulling git repository from origin...'
( cd $LOCAL_REPO_DIR && git pull origin )

# Don't continue if required files aren't present.
if [ ! -f $LOCAL_REPO_DIR/contrib/completion/git-completion.bash ]; then
	echo '** Git completion script not found. Aborting.'
	return
fi

###############################################################################
# Create symbolic links
###############################################################################

# Helper function to create a link if the destination doesn't exist
# or display an error message detailing why it failed.
create_link()
{
	local SRC="$1"
	local DST="$2"

	if [ ! -e "$DST" ]; then
		echo '--'
		printf '%s' '--> Creating symbolic link: '
		ln -sv "$SRC" "$DST"
	else
		if [ ! -L "$DST" ] || [ "`readlink "$DST"`" != "$SRC" ]; then
			printf '%s' "--> $DST already exists" >&2
			if [ -L "$DST" ]; then
				echo " (pointing to `readlink "$DST"`)"
			else
				echo ' (not a symlink)'
			fi
		fi
	fi
}

# Create symbolic links to completion and command.

echo '--'
echo '--> Create symbolic links for Git helpers.'
create_link $HOME/src/external/git/contrib/completion/git-completion.bash   $HOME/bin/git-completion.bash
create_link $HOME/src/external/git/contrib/completion/git-prompt.sh         $HOME/bin/git-prompt.sh

###############################################################################
# Install RVM
###############################################################################

# Install the stable release version of RVM.
if [ ! -s "$HOME/.rvm/scripts/rvm" ]; then
	echo '--'
	echo '--> Installing RVM...'
	curl -L https://get.rvm.io | bash -s stable
fi

# Enable rvm if available.
if [ -s "$HOME/.rvm/scripts/rvm" ]; then
	echo '--'
	echo '--> Enable RVM...'
	source "$HOME/.rvm/scripts/rvm"
fi

###############################################################################
# Install git-up
###############################################################################

echo '--'
echo '--> Installing git-up...'
echo 'You may be prompted for your admin password to allow git-up to be installed.'
sudo gem install git-up

###############################################################################
# Instructions for installing Ruby
###############################################################################

# Tell user what to do next.
echo ' '
echo 'To install Ruby, type:'
echo ' '
echo '   rvm install _version_'
echo ' '
echo 'where _version_ is the version to install.'
echo 'The latest version of Ruby as of 10/28/2012 is 1.9.3.'
echo 'To get a list of available versions type:'
echo ' '
echo '   rvm list known'
echo ' '
