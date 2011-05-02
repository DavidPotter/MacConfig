#!/bin/bash -e
cd

# Location of repository.
REPONAME='MacConfig'
REPOLOC="$HOME/bin/$REPONAME"

# Clone the dotfiles repository and execute the profile script.
[ -d $REPOLOC ] || git clone git://github.com/DavidPotter/$REPONAME.git $REPOLOC
(
	set -e
	cd $REPOLOC

	TEMPFILE="`mktemp -t install.XXXXXX`"
	trap '{ rm -f "$TEMPFILE"; }' EXIT

	set +e
	git fetch origin
	git show origin/master:dotfiles/profile > "$TEMPFILE"
	echo "Executing $TEMPFILE"
	source "$TEMPFILE"
	set -e

	gup
)

# Helper function to create a link if the destination doesn't exist
# or display an error message detailing why it failed.
function create_link()
{
	local SRC="$1"
	local DST="$2"

	if [ ! -e "$DST" ]
	then
		ln -sv "$SRC" "$DST"
	else
		if [ ! -L "$DST" ] || [ "`readlink "$DST"`" != "$SRC" ]
		then
			echo -n "$REPONAME: $DST already exists" >&2
			if [ -L "$DST" ]
			then
				echo " (pointing to `readlink "$DST"`)"
			else
				echo " (not a symlink)"
			fi
		fi
	fi

}

# Loop throgh the files in the dotfiles directory and create a symlink to each one
# from a file with the same name but with a dot prefix (a dotfile) in the home directory.
# Special-case the profile script.
find $REPOLOC/dotfiles -maxdepth 1 -type f -not -name 'install.sh' -not -name 'README*' | while read SRC
do
	DST="`echo "$SRC" | sed -e 's#.*/#.#'`"
	if echo "$SRC" | grep -q /profile$
	then
		create_link "$SRC" .bash_profile
		create_link "$SRC" .bashrc
	else
		create_link "$SRC" "$DST"
	fi
done

# Install the CreateHosts script to detect changes in the network configuration
# and set up the correct hosts file.
source $REPOLOC/installChangeHosts.sh

echo '#'
echo '# Invoke the following command to complete the installation:'
echo '#   source ~/.bash_profile'
echo '#'
