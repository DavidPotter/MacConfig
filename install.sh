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

function clone_repo()
{
	echo "--- CLONING REPO $REPO_NAME ---"
	git clone https://github.com/DavidPotter/$REPO_NAME.git $LOCAL_REPO_DIR
}

# If the repository doesn't exist on the local disk, clone it.
[ -d $LOCAL_REPO_DIR ] || clone_repo

# Pull from the remote repository.
(
	set -e
	cd $LOCAL_REPO_DIR

	echo "--- PULL FROM REPO $REPO_NAME ---"

	TEMP_FILE='`mktemp -t install.XXXXXX`'
	trap '{ rm -f "$TEMP_FILE"; }' EXIT

	set +e
	git fetch origin
	git show origin/master:dotfiles/bash_profile > "$TEMP_FILE"
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
		echo -n "$REPO_NAME: $DST already" >&2
		if [ -L "$DST" ]
		then
			if [ "`readlink "$DST"`" = "$SRC" ] >&2
			then
				echo -n ' defined properly' >&2
			fi
			echo " (pointing to `readlink "$DST"`)" >&2
		else
			echo ' exists (not a symlink)' >&2
		fi
	fi

}

# Install ~/.bash_profile as a local stub that sources the shared repo profile,
# instead of symlinking ~/.bash_profile straight into the repo.  Some tool
# installers append "export ..." lines to ~/.bash_profile; when that file is a
# symlink into the repo those edits get written through the link into version
# control and leak onto every other machine.  A stub keeps such machine-local
# edits in the home directory, below the repo source line.
function install_bash_profile_stub()
{
	local DST="$HOME/.bash_profile"
	local LOADER='source "$HOME/bin/MacConfig/dotfiles/bash_profile"'

	# Already a local stub: leave it (and any tool-appended lines) untouched.
	if [ -f "$DST" ] && [ ! -L "$DST" ] && grep -qF "$LOADER" "$DST"
	then
		echo "$REPO_NAME: $DST already a local stub (leaving tool-managed lines intact)"
		return
	fi

	# A regular file we did not create: do not clobber it, just advise.
	if [ -f "$DST" ] && [ ! -L "$DST" ]
	then
		echo "$REPO_NAME: $DST exists and is not a MacConfig stub; add this line manually:" >&2
		echo "    $LOADER" >&2
		return
	fi

	# A symlink (the old install style, possibly pointing into the repo) or a
	# broken link: replace it with the stub.
	if [ -L "$DST" ]
	then
		echo "$REPO_NAME: migrating $DST from symlink to local stub"
		rm -f "$DST"
	fi

	cat > "$DST" <<-EOF
		# ~/.bash_profile -- local loader (NOT tracked in the MacConfig repo).
		#
		# Sources the shared profile from the repo, then lets machine-local tool
		# installers append their own "export" lines below.  Keeping this file in
		# \$HOME -- not a symlink into the repo -- stops those edits from leaking
		# into version control.
		$LOADER
	EOF
	echo "$REPO_NAME: wrote local stub $DST -> $LOCAL_REPO_DIR/dotfiles/bash_profile"
}

# CREATE SYMBOLIC LINKS FOR DOT FILES
# Loop through the files in the dotfiles directory and create a symlink to
# each one from a file with the same name but with a dot prefix (a dotfile) in
# the home directory.  The bash_profile script is special-cased: it is installed
# as a local stub (install_bash_profile_stub, above) so tool installers cannot
# write through it into the repo.
install_bash_profile_stub
echo '--- CREATE SYMBOLIC LINKS FOR DOT FILES ---'
find $LOCAL_REPO_DIR/dotfiles -maxdepth 1 -type f -not -name 'install.sh' -not -name 'README*' -not -name 'bash_profile' | while read SRC
do
	if echo "$SRC" | grep -q /bashrc$
	then
		create_link "$SRC" "$HOME/.bash_profile"
		create_link "$SRC" "$HOME/.bashrc"
	else
		DST="$HOME/`echo "$SRC" | sed -e 's#.*/#.#'`"
		create_link "$SRC" "$DST"
	fi
done

# CREATE SYMBOLIC LINKS FOR WORKFLOW FILES TO ADD SERVICES
# Loop through the *.workflow files in the Library/Services directory of the
# repository and create a symlink to each one from a file in the
# ~/Library/Services directory.
# http://macs.about.com/od/diyguidesprojects/qt/Create-A-Menu-Item-To-Hide-And-Show-Hidden-Files-In-Os-X.htm
echo '--- CREATE SYMBOLIC LINKS FOR WORKFLOW FILES TO ADD SERVICES ---'
find $LOCAL_REPO_DIR/Library/Services/*.workflow -maxdepth 0 -type d -not -name 'README*' | while read SRC
do
	DST="$HOME/`echo "$SRC" | sed -e 's#.*/##'`"
	create_link "$SRC" "$DST"
done

# CREATE POWERSHELL PROFILES
# Create the PowerShell config directory first if it doesn't exist.
echo '-- CREATE POWERSHELL PROFILES ---'
if [ ! -d "$HOME/.config/powershell" ]; then
    mkdir "$HOME/.config/powershell"
fi
# Create symlink for profile stored in repo.
echo ". '$LOCAL_REPO_DIR/PowerShell/profile/profile.ps1'" | tee "$HOME/.config/powershell/Microsoft.PowerShell_profile.ps1"
create_link "$HOME/.config/powershell/Microsoft.PowerShell_profile.ps1" "$HOME/.config/powershell/Microsoft.VSCode_profile.ps1"

# INSTALL APPLICATION CONFIGURATIONS
echo '--- INSTALL APPLICATION CONFIGURATIONS ---'
source $LOCAL_REPO_DIR/Application-Config/install-application-configs.sh

# FINAL INSTRUCTIONS
echo ' '
echo '#'
echo '# Invoke the following commands to complete the installation:'
echo '#   source ~/.bash_profile'
echo "#   source ${LOCAL_REPO_DIR}/install-tools.sh"
echo '#'
echo ' '
