#!/bin/bash -e

#
# install.sh
#   Installs files and creates symbolic links to use the tools in the
#   MacConfig repository.
#
#   The follow steps are performed:
#   - Clone the MacConfig repository to ~/bin/MacConfig.
#   - Create symbolic links for dot files in the home directory.
#   - Create symbolic links for workflow files to add services.
#

# Location of repository.
REPO_NAME='MacConfig'
LOCAL_REPO_DIR="$HOME/bin/$REPO_NAME"

# Clone the dotfiles repository and execute the profile script.
[ -d $LOCAL_REPO_DIR ] || git clone https://github.com/DavidPotter/$REPO_NAME.git $LOCAL_REPO_DIR
(
	set -e
	cd $LOCAL_REPO_DIR

	TEMP_FILE='`mktemp -t install.XXXXXX`'
	trap '{ rm -f "$TEMP_FILE"; }' EXIT

	set +e
	git fetch origin
	git show origin/master:dotfiles/profile > "$TEMP_FILE"
	echo "Executing $TEMP_FILE"
	source "$TEMP_FILE"
	set -e

	git pull
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
			echo -n "$REPO_NAME: $DST already exists" >&2
			if [ -L "$DST" ]
			then
				echo " (pointing to `readlink "$DST"`)"
			else
				echo ' (not a symlink)'
			fi
		fi
	fi

}

# CREATE SYMBOLIC LINKS FOR DOT FILES
# Loop through the files in the dotfiles directory and create a symlink to
# each one from a file with the same name but with a dot prefix (a dotfile) in
# the home directory.  Special-case the profile script.
find $LOCAL_REPO_DIR/dotfiles -maxdepth 1 -type f -not -name 'install.sh' -not -name 'README*' | while read SRC
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

# CREATE SYMBOLIC LINKS FOR WORKFLOW FILES TO ADD SERVICES
# Loop through the *.workflow files in the Library/Services directory of the
# repository and create a symlink to each one from a file in the
# ~/Library/Services directory.
# http://macs.about.com/od/diyguidesprojects/qt/Create-A-Menu-Item-To-Hide-And-Show-Hidden-Files-In-Os-X.htm
find $LOCAL_REPO_DIR/Library/Services/*.workflow -maxdepth 0 -type d -not -name 'README*' | while read SRC
do
	DST="`echo "$SRC" | sed -e 's#.*/##'`"
	create_link "$SRC" "$DST"
done

echo ' '
echo '#'
echo '# Invoke the following commands to complete the installation:'
echo '#   source ~/.bashrc'
echo "#   source ${LOCAL_REPO_DIR}/install-tools.sh"
echo '#'
echo ' '
