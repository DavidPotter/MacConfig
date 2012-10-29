#!/bin/bash -e
#pwd

# Find the directory containing git.
if [ -f /usr/bin/git ]
then
	GITDIR=/usr/bin
elif [ -f /usr/local/bin/git ]
then
	GITDIR=/usr/local/bin
else
	echo '** Git not installed yet. Aborting.'
	return
fi
echo "[Git is in $GITDIR]"

#
# install-git-tools.sh
#   Installs the git helpers by performing following steps:
#   - Clones repositories:
#     - Git source to ~/src/external/git.
#     - Git-Flow to ~/src/external/gitflow.
#     - Git-Flow Completion to ~/src/external/git-flow-completion.
#     - git-wtf to ~/src/external/willgit.
#   - Installs Git-Flow.
#   - Creates symbolic links:
#     - git-completion
#     - git-flow-completion
#     - git-wtf
#

###############################################################################
# Git
###############################################################################

# Clone the git source if not already present.
REPOLOC="$HOME/src/external/git"
if [ ! -d $REPLOC ]
then
	echo "--> Cloning git to $REPOLOC..."
	git clone https://github.com/git/git.git $REPOLOC
fi
if [ ! -d $REPLOC ]
then
	echo '** Failed to clone git. Aborting.'
	return
fi

# Update the git repository.
echo '--> Pulling git repository from origin...'
pushd $REPOLOC
git pull origin
popd

# Don't continue if required files aren't present.
if [ ! -f $REPOLOC/contrib/completion/git-completion.bash ]
then
	echo '** Git completion script not found. Aborting.'
	return
fi

###############################################################################
# Git-flow
###############################################################################

# Clone the git-flow source if not already present.
REPOLOC="$HOME/src/external/gitflow"
if [ ! -d $REPOLOC ]
then
	echo '--> Cloning gitflow...'
	git clone https://github.com/nvie/gitflow.git $REPOLOC
fi
if [ ! -d $REPOLOC ]
then
	echo '** Failed to clone git-flow. Aborting.'
	return
fi

# Update the git-flow repository.
echo '--> Pulling gitflow repository from origin...'
pushd $REPOLOC
git pull origin
popd

# Don't continue if required files aren't present.
if [ ! -f $REPOLOC/contrib/gitflow-installer.sh ]
then
	echo '** Git-flow install script not found. Aborting.'
	return
fi

# Install Git-Flow if not already installed.
echo "--> Installing git-flow into $GITDIR..."
echo "If prompted, enter admin password for updating system directory $GITDIR"
sudo bash <<EOF
	cd $REPOLOC/..
	export INSTALL_PREFIX="$GITDIR"
	bash $REPOLOC/contrib/gitflow-installer.sh
	unset INSTALL_PREFIX
EOF

###############################################################################
# Git-flow-completion
###############################################################################

# Clone the git-flow-completion source if not already present.
REPOLOC="$HOME/src/external/git-flow-completion"
if [ ! -d $REPOLOC ]
then
	echo '--> Cloning git-flow-completion...'
	git clone https://github.com/bobthecow/git-flow-completion.git $REPOLOC
fi
if [ ! -d $REPOLOC ]
then
	echo '** Failed to clone git-flow-completion. Aborting.'
	return
fi

# Update the git-flow-completion repository.
echo '--> Pulling git-flow-completion repository from origin...'
pushd $REPOLOC
git pull origin
popd

# Don't continue if required files aren't present.
if [ ! -f $REPOLOC/git-flow-completion.bash ]
then
	echo '** Git-flow completion script not found. Aborting.'
	return
fi

###############################################################################
# Git-wtf
###############################################################################

# Clone the git-wtf source if not already present.
REPOLOC="$HOME/src/external/willgit"
if [ ! -d $REPOLOC ]
then
	echo '--> Cloning git-wtf...'
	git clone git://gitorious.org/willgit/mainline.git/ $REPOLOC
fi
if [ ! -d $REPOLOC ]
then
	echo '** Failed to clone git-wtf. Aborting.'
	return
fi

# Update the git-wtf (willgit) repository.
echo '--> Pulling git-wtf (willgit) repository from origin...'
pushd $REPOLOC
git pull origin
popd

# Don't continue if required files aren't present.
if [ ! -f $REPOLOC/bin/git-wtf ]
then
	echo '** Git-wtf script not found. Aborting.'
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

	if [ ! -e "$DST" ]
	then
		echo -n "--> Creating symbolic link: "
		ln -sv "$SRC" "$DST"
	else
		if [ ! -L "$DST" ] || [ "`readlink "$DST"`" != "$SRC" ]
		then
			echo -n "--> $REPONAME: $DST already exists" >&2
			if [ -L "$DST" ]
			then
				echo " (pointing to `readlink "$DST"`)"
			else
				echo " (not a symlink)"
			fi
		fi
	fi
}

# Create symbolic links to completion and command.

create_link $HOME/src/external/git/contrib/completion/git-completion.bash $HOME/bin/git-completion.sh
create_link $HOME/src/external/git-flow-completion/git-flow-completion.bash $HOME/bin/git-flow-completion.sh
create_link $HOME/src/external/willgit/bin/git-wtf $HOME/bin/git-wtf
