#!/bin/bash -e

#
# install-tools.sh
#   Installs the Git helpers by performing following steps:
#   - Clones repositories:
#     - Git source to ~/src/external/git.
#   - Creates symbolic links:
#     - git-completion
#   Installs git-up.
#   Installs RVM and Ruby.
#

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
pushd $LOCAL_REPO_DIR
git pull origin
popd

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
function create_link()
{
	local SRC="$1"
	local DST="$2"

	if [ ! -e "$DST" ]; then
		echo '--'
		echo -n '--> Creating symbolic link: '
		ln -sv "$SRC" "$DST"
	else
		if [ ! -L "$DST" ] || [ "`readlink "$DST"`" != "$SRC" ]; then
			echo -n "--> $DST already exists" >&2
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
if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
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
