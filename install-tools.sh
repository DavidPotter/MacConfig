#!/bin/bash -e

#
# install-tools.sh
#   Installs the Git helpers by performing following steps:
#   - Clones repositories:
#     - Git source to ~/src/external/git.
#     - Git-Flow to ~/src/external/gitflow.
#     - Git-Flow Completion to ~/src/external/git-flow-completion.
#   - Installs Git-Flow.
#   - Creates symbolic links:
#     - git-completion
#     - git-flow-completion
#   Installs RVM and Ruby
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
REMOTE_REPO="https://github.com/git/git.git"
if [ ! -d $LOCAL_REPO_DIR ]; then
	echo "--> Cloning git to $LOCAL_REPO_DIR..."
	git clone $REMOTE_REPO $LOCAL_REPO_DIR
fi
if [ ! -d $LOCAL_REPO_DIR ]; then
	echo '** Failed to clone git. Aborting.'
	return
fi

# Update the git repository.
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
# Git-flow
###############################################################################

# Clone the git-flow source if not already present.
LOCAL_REPO_DIR="$HOME/src/external/gitflow"
REMOTE_REPO="https://github.com/nvie/gitflow.git"
if [ ! -d $LOCAL_REPO_DIR ]; then
	echo '--> Cloning gitflow...'
	git clone $REMOTE_REPO $LOCAL_REPO_DIR
fi
if [ ! -d $LOCAL_REPO_DIR ]; then
	echo '** Failed to clone git-flow. Aborting.'
	return
fi

# Update the git-flow repository.
echo '--> Pulling gitflow repository from origin...'
pushd $LOCAL_REPO_DIR
git pull origin
popd

# Don't continue if required files aren't present.
if [ ! -f $LOCAL_REPO_DIR/contrib/gitflow-installer.sh ]; then
	echo '** Git-flow install script not found. Aborting.'
	return
fi

# Install Git-Flow if not already installed.
echo "--> Installing git-flow into $GIT_DIR..."
echo "If prompted, enter admin password for updating system directory $GIT_DIR"
sudo bash <<EOF
	cd $LOCAL_REPO_DIR/..
	export INSTALL_PREFIX="$GIT_DIR"
	bash $LOCAL_REPO_DIR/contrib/gitflow-installer.sh
	unset INSTALL_PREFIX
EOF

###############################################################################
# Git-flow-completion
###############################################################################

# Clone the git-flow-completion source if not already present.
LOCAL_REPO_DIR="$HOME/src/external/git-flow-completion"
REMOTE_REPO="https://github.com/bobthecow/git-flow-completion.git"
if [ ! -d $LOCAL_REPO_DIR ]; then
	echo '--> Cloning git-flow-completion...'
	git clone $REMOTE_REPO $LOCAL_REPO_DIR
fi
if [ ! -d $LOCAL_REPO_DIR ]; then
	echo '** Failed to clone git-flow-completion. Aborting.'
	return
fi

# Update the git-flow-completion repository.
echo '--> Pulling git-flow-completion repository from origin...'
pushd $LOCAL_REPO_DIR
git pull origin
popd

# Don't continue if required files aren't present.
if [ ! -f $LOCAL_REPO_DIR/git-flow-completion.bash ]; then
	echo '** Git-flow completion script not found. Aborting.'
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
		echo -n "--> Creating symbolic link: "
		ln -sv "$SRC" "$DST"
	else
		if [ ! -L "$DST" ] || [ "`readlink "$DST"`" != "$SRC" ]; then
			echo -n "--> $DST already exists" >&2
			if [ -L "$DST" ]; then
				echo " (pointing to `readlink "$DST"`)"
			else
				echo " (not a symlink)"
			fi
		fi
	fi
}

# Create symbolic links to completion and command.

create_link $HOME/src/external/git/contrib/completion/git-completion.bash   $HOME/bin/git-completion.bash
create_link $HOME/src/external/git/contrib/completion/git-prompt.sh         $HOME/bin/git-prompt.sh
create_link $HOME/src/external/git-flow-completion/git-flow-completion.bash $HOME/bin/git-flow-completion.bash

###############################################################################
# Install RVM
###############################################################################

# Install the stable release version of RVM.
if [ ! -s "$HOME/.rvm/scripts/rvm" ]; then
	echo '--> Installing RVM...'
	curl -L https://get.rvm.io | bash -s stable
fi

# Enable rvm if available.
if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
	source "$HOME/.rvm/scripts/rvm"
fi

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
